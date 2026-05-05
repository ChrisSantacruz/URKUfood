import {
    Injectable,
    Logger,
    OnModuleDestroy,
    OnModuleInit,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  accessSync,
  constants,
  existsSync,
  mkdirSync,
  rmSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { isAbsolute, join } from 'node:path';
import { Client, LocalAuth, Poll, type Message } from 'whatsapp-web.js';
import { Order, OrderDocument } from '../orders/schemas/order.schema';
import {
    AvailabilitySession,
    AvailabilitySessionDocument,
    AvailabilitySessionRestaurant,
} from './schemas/availability-session.schema';

const QRCode = require('qrcode') as {
  toDataURL(value: string): Promise<string>;
  toString(
    value: string,
    options: { type: string; small: boolean },
  ): Promise<string>;
};

@Injectable()
export class WhatsappService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(WhatsappService.name);
  private client: Client | null = null;
  private qrCodeDataUrl: string | null = null;
  private rawQr: string | null = null;
  private connectionState:
    | 'disabled'
    | 'idle'
    | 'connecting'
    | 'qr'
    | 'connected'
    | 'error' = 'idle';
  private lastError: string | null = null;
  private isStarting = false;
  private resolvedWhatsappSessionDir: string | null = null;
  private reconnectTimer: ReturnType<typeof setTimeout> | null = null;
  private reconnectAttempts = 0;

  constructor(
    private readonly configService: ConfigService,
    @InjectModel(Order.name) private readonly orderModel: Model<OrderDocument>,
    @InjectModel(AvailabilitySession.name)
    private readonly availabilitySessionModel: Model<AvailabilitySessionDocument>,
  ) {}

  async onModuleInit() {
    if (!this.isEnabled()) {
      this.connectionState = 'disabled';
      return;
    }

    const delayMs = this.deployWhatsAppConnectDelayMs();
    if (delayMs > 0) {
      this.logger.log(
        `WhatsApp: esperando ${delayMs} ms antes de lanzar Chromium (menos choque con el arranque del API).`,
      );
      await new Promise<void>((resolve) => setTimeout(resolve, delayMs));
    }

    await this.connect();
  }

  async onModuleDestroy() {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    await this.client?.destroy();
    this.client = null;
  }

  async connect() {
    if (!this.isEnabled()) {
      this.connectionState = 'disabled';
      return this.getStatus();
    }

    if (this.isStarting) {
      return this.getStatus();
    }

    this.isStarting = true;
    this.connectionState = 'connecting';
    this.lastError = null;

    let waClient: Client | null = null;
    try {
      if (this.client) {
        await this.client.destroy();
        this.client = null;
      }

      waClient = new Client({
        authStrategy: new LocalAuth({
          dataPath: this.sessionDirectory,
          clientId: 'urkufood',
        }),
        puppeteer: {
          headless: true,
          executablePath:
            this.configService.get<string>('WHATSAPP_CHROME_PATH') || undefined,
          // Chrome + Nest en Render free (~512MB): flags para bajar RAM (no garantiza el límite).
          args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu',
            '--disable-software-rasterizer',
            '--disable-extensions',
            '--disable-background-networking',
            '--disable-default-apps',
            '--disable-sync',
            '--disable-translate',
            '--mute-audio',
            '--no-first-run',
            '--font-render-hinting=none',
            '--disable-features=IsolateOrigins,site-per-process',
            '--disable-site-isolation-trials',
          ],
        },
      });

      waClient.on('qr', (qr) => {
        void this.handleQr(qr);
      });
      waClient.on('ready', () => {
        this.reconnectAttempts = 0;
        this.connectionState = 'connected';
        this.qrCodeDataUrl = null;
        this.rawQr = null;
        this.lastError = null;
        this.logger.log('WhatsApp conectado con whatsapp-web.js');
      });
      waClient.on('authenticated', () => {
        this.connectionState = 'connecting';
        this.lastError = null;
      });
      waClient.on('auth_failure', (message) => {
        this.connectionState = 'error';
        this.lastError = message;
      });
      waClient.on('disconnected', (reason) => {
        const r = String(reason);
        this.connectionState = 'idle';
        this.lastError = r;
        this.client = null;
        if (!this.isEnabled()) {
          return;
        }
        if (/LOGOUT/i.test(r)) {
          return;
        }
        this.scheduleReconnect(`disconnected: ${r}`, 15_000);
      });
      waClient.on('message', (message) => {
        void this.handleIncomingMessage(message);
      });
      waClient.on('vote_update', (vote) => {
        void this.handlePollVote(vote);
      });

      await waClient.initialize();

      this.client = waClient;
      waClient = null;
      return this.getStatus();
    } catch (error) {
      if (waClient) {
        await waClient.destroy().catch(() => {});
        waClient = null;
      }
      const msg =
        error instanceof Error
          ? error.message
          : 'Unknown WhatsApp startup error';
      this.connectionState = 'error';
      this.lastError = msg;
      this.logger.error(msg);
      if (
        this.isEnabled() &&
        (msg.includes('detached') ||
          msg.includes('Target closed') ||
          msg.includes('Session closed'))
      ) {
        this.scheduleReconnect(msg, 18_000);
      }
      return this.getStatus();
    } finally {
      this.isStarting = false;
    }
  }

  async sendTestMessage(to?: string) {
    const recipient = this.normalizePhone(
      to || this.configService.get<string>('WHATSAPP_TEST_RECIPIENT') || '',
    );

    if (!recipient) {
      return {
        delivered: false,
        provider: 'disabled',
        error: 'Missing test recipient',
      };
    }

    return this.sendTextMessage(
      recipient,
      'Hola. Este es un mensaje de prueba de URKUfood enviado con whatsapp-web.js.',
    );
  }

  async sendTextMessage(to: string, body: string) {
    const normalizedTo = this.normalizePhone(to);

    if (!this.isEnabled()) {
      this.logger.log(`WhatsApp disabled. Message for ${to}: ${body}`);
      return { delivered: false, provider: 'disabled' };
    }

    if (!normalizedTo) {
      return {
        delivered: false,
        provider: 'disabled',
        error: 'Invalid recipient phone',
      };
    }

    await this.waitForWhatsAppReady(this.getReadyWaitMs());

    if (!this.client || this.connectionState !== 'connected') {
      return {
        delivered: false,
        provider: 'whatsapp-web.js',
        error:
          'WhatsApp del servidor no listo: espera ~1 min tras iniciar Render o escanea el QR del panel. Reintenta el pedido.',
      };
    }

    try {
      const recipientId = await this.resolveRecipientId(normalizedTo);
      if (!recipientId) {
        return {
          delivered: false,
          provider: 'whatsapp-web.js',
          error: `No WhatsApp account found for ${normalizedTo}`,
        };
      }

      await this.client.sendMessage(recipientId, body);
      return { delivered: true, provider: 'whatsapp-web.js' };
    } catch (error) {
      const message =
        error instanceof Error ? error.message : 'Unknown WhatsApp send error';
      this.logger.error(`WhatsApp send failed: ${message}`);
      return { delivered: false, provider: 'whatsapp-web.js', error: message };
    }
  }

  async sendOrderActionsToAdmin(to: string, body: string, orderCode: string) {
    const normalizedTo = this.normalizePhone(to);

    if (!this.client || this.connectionState !== 'connected' || !normalizedTo) {
      return this.sendTextMessage(to, body);
    }

    try {
      const recipientId = await this.resolveRecipientId(normalizedTo);
      if (!recipientId) {
        return {
          delivered: false,
          provider: 'whatsapp-web.js',
          error: `No WhatsApp account found for ${normalizedTo}`,
        };
      }

      await this.client.sendMessage(recipientId, body);

      const poll = new Poll(
        `Estado de ${orderCode}`,
        ['Preparando', 'Enviado', 'Entregado'],
        { allowMultipleAnswers: false, messageSecret: undefined },
      );

      await this.client.sendMessage(recipientId, poll);
      return { delivered: true, provider: 'whatsapp-web.js', type: 'poll' };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`Poll send failed, falling back to text: ${message}`);
      return this.sendTextMessage(
        to,
        [
          body,
          '',
          'Estados manuales disponibles:',
          `PREPARANDO ${orderCode}`,
          `ENVIADO ${orderCode}`,
          `ENTREGADO ${orderCode}`,
        ].join('\n'),
      );
    }
  }

  async sendAvailabilityRequest({
    to,
    body,
    pollName,
  }: {
    to: string;
    body: string;
    pollName: string;
  }) {
    const normalizedTo = this.normalizePhone(to);

    if (!this.client || this.connectionState !== 'connected' || !normalizedTo) {
      return this.sendTextMessage(
        to,
        [
          body,
          '',
          'Si no puedes responder la encuesta, contesta con uno de estos textos:',
          'CONFIRMADO',
          'PLATO NO DISPONIBLE',
          'INGREDIENTE NO DISPONIBLE',
        ].join('\n'),
      );
    }

    try {
      const recipientId = await this.resolveRecipientId(normalizedTo);
      if (!recipientId) {
        return {
          delivered: false,
          provider: 'whatsapp-web.js',
          error: `No WhatsApp account found for ${normalizedTo}`,
        };
      }

      await this.client.sendMessage(recipientId, body);
      const poll = new Poll(
        pollName,
        ['Confirmado', 'Plato no disponible', 'Ingrediente no disponible'],
        { allowMultipleAnswers: false, messageSecret: undefined },
      );
      await this.client.sendMessage(recipientId, poll);
      return { delivered: true, provider: 'whatsapp-web.js', type: 'poll' };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(
        `Availability poll send failed, falling back to text: ${message}`,
      );
      return this.sendTextMessage(
        to,
        [
          body,
          '',
          'Responde con uno de estos textos:',
          'CONFIRMADO',
          'PLATO NO DISPONIBLE',
          'INGREDIENTE NO DISPONIBLE',
        ].join('\n'),
      );
    }
  }

  async sendAvailabilitySelectionPoll({
    to,
    body,
    pollName,
    options,
  }: {
    to: string;
    body: string;
    pollName: string;
    options: string[];
  }) {
    const normalizedTo = this.normalizePhone(to);

    if (
      !this.client ||
      this.connectionState !== 'connected' ||
      !normalizedTo ||
      options.length === 0
    ) {
      return this.sendTextMessage(to, body);
    }

    try {
      const recipientId = await this.resolveRecipientId(normalizedTo);
      if (!recipientId) {
        return {
          delivered: false,
          provider: 'whatsapp-web.js',
          error: `No WhatsApp account found for ${normalizedTo}`,
        };
      }

      await this.client.sendMessage(recipientId, body);
      const poll = new Poll(pollName, options, {
        allowMultipleAnswers: false,
        messageSecret: undefined,
      });
      await this.client.sendMessage(recipientId, poll);
      return { delivered: true, provider: 'whatsapp-web.js', type: 'poll' };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(
        `Availability selection poll send failed, falling back to text: ${message}`,
      );
      return this.sendTextMessage(to, body);
    }
  }

  getStatus() {
    return {
      provider: 'whatsapp-web.js',
      enabled: this.isEnabled(),
      state: this.connectionState,
      qrCodeDataUrl: this.qrCodeDataUrl,
      rawQr: this.rawQr,
      lastError: this.lastError,
      sessionDirectory: this.sessionDirectory,
      qrPageUrl: this.getPublicQrPageUrl(),
      keepaliveUrl: this.getPublicKeepaliveUrl(),
    };
  }

  /**
   * URL pública para enlaces y logs. En Render usa `RENDER_EXTERNAL_URL` si `PUBLIC_BASE_URL` sigue en localhost.
   * También la usa la página HTML del QR.
   */
  resolvePublicBaseUrl(): string | null {
    const configured = this.configService
      .get<string>('PUBLIC_BASE_URL')
      ?.trim()
      .replace(/\/$/, '');
    const renderUrl = process.env.RENDER_EXTERNAL_URL?.trim().replace(/\/$/, '');

    const looksLocal =
      configured &&
      (configured.includes('localhost') ||
        configured.includes('127.0.0.1'));

    if (configured && !looksLocal) {
      return configured;
    }
    if (renderUrl) {
      return renderUrl;
    }
    return configured || null;
  }

  private getPublicQrPageUrl(): string | null {
    const base = this.resolvePublicBaseUrl();
    if (!base) {
      return null;
    }
    return `${base}/automation/whatsapp/qr-page`;
  }

  private getPublicKeepaliveUrl(): string | null {
    const base = this.resolvePublicBaseUrl();
    if (!base) {
      return null;
    }
    return `${base}/keepalive`;
  }

  private normalizePhone(value: string) {
    return value.replace(/[^0-9]/g, '');
  }

  private get isRenderEnvironment() {
    return (
      process.env.RENDER === 'true' ||
      Boolean(process.env.RENDER_SERVICE_ID) ||
      Boolean(process.env.RENDER_EXTERNAL_URL)
    );
  }

  /** Acepta true / True / 1 / yes (Render y .env suelen variar mayúsculas). */
  private envTruthy(value: string | undefined): boolean {
    if (value == null || value === '') {
      return false;
    }
    const normalized = String(value).trim().toLowerCase();
    return (
      normalized === 'true' || normalized === '1' || normalized === 'yes'
    );
  }

  private get allowRenderWhatsapp() {
    return this.envTruthy(
      this.configService.get<string>('WHATSAPP_ALLOW_RENDER'),
    );
  }

  private async resolveRecipientId(phone: string) {
    if (!this.client) {
      return null;
    }

    const result = await this.client.getNumberId(phone);
    if (!result) {
      return null;
    }

    if (typeof result === 'string') {
      return result;
    }

    return result._serialized ?? null;
  }

  private isEnabled() {
    if (this.isRenderEnvironment && !this.allowRenderWhatsapp) {
      return false;
    }

    return this.envTruthy(this.configService.get<string>('WHATSAPP_ENABLED'));
  }

  /** Retraso antes del primer Chromium (Docker/Render): menos RAM concurrente con Mongo/seed. */
  private deployWhatsAppConnectDelayMs(): number {
    const raw =
      this.configService.get<string>('WHATSAPP_CONNECT_DELAY_MS')?.trim();
    const parsed = raw ? Number.parseInt(raw, 10) : NaN;
    if (Number.isFinite(parsed) && parsed >= 0) {
      return parsed;
    }
    return this.isRenderEnvironment || process.cwd() === '/usr/src/app'
      ? 8000
      : 0;
  }

  private getReadyWaitMs(): number {
    const raw =
      this.configService.get<string>('WHATSAPP_READY_WAIT_MS')?.trim();
    const parsed = raw ? Number.parseInt(raw, 10) : NaN;
    if (Number.isFinite(parsed) && parsed >= 5000) {
      return parsed;
    }
    return 90_000;
  }

  /** Render cold start: Puppeteer puede tardar; esperamos antes de rechazar el envío. */
  private async waitForWhatsAppReady(maxMs: number): Promise<void> {
    if (!this.isEnabled()) {
      return;
    }
    const deadline = Date.now() + maxMs;
    while (Date.now() < deadline) {
      if (this.client && this.connectionState === 'connected') {
        return;
      }
      if (this.connectionState === 'qr' || this.connectionState === 'disabled') {
        return;
      }
      await new Promise<void>((resolve) => setTimeout(resolve, 500));
    }
  }

  private scheduleReconnect(reason: string, delayMs: number): void {
    if (!this.isEnabled()) {
      return;
    }
    const max = 10;
    if (this.reconnectAttempts >= max) {
      this.logger.warn(
        `WhatsApp: máximo de reconexiones automáticas (${max}). Revisa QR, RAM o sesión.`,
      );
      return;
    }
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
    }
    this.reconnectAttempts += 1;
    this.logger.warn(
      `WhatsApp reconexión #${this.reconnectAttempts} en ${delayMs} ms — ${reason}`,
    );
    this.reconnectTimer = setTimeout(() => {
      this.reconnectTimer = null;
      void this.connect();
    }, delayMs);
  }

  /**
   * LocalAuth crea subcarpetas (p. ej. session-urkufood). Comprobar W_OK en el padre
   * no basta: en Docker a veces el padre parece ok y falla mkdir hija → probamos una subcarpeta.
   */
  private trySessionDataPath(dir: string): string | null {
    try {
      if (!existsSync(dir)) {
        mkdirSync(dir, { recursive: true });
      }
      accessSync(dir, constants.W_OK);
      const probe = join(dir, `.urku-wprobe-${Date.now()}`);
      mkdirSync(probe, { recursive: true });
      rmSync(probe, { recursive: true, force: true });
      return dir;
    } catch {
      return null;
    }
  }

  private get sessionDirectory(): string {
    if (this.resolvedWhatsappSessionDir) {
      return this.resolvedWhatsappSessionDir;
    }

    const raw =
      this.configService.get<string>('WHATSAPP_SESSION_DIR')?.trim() ||
      './session';
    const fromConfig = isAbsolute(raw)
      ? raw
      : join(process.cwd(), raw);

    const tmpSession = join(tmpdir(), 'urkufood-wwebjs-session');
    const deployLike =
      this.isRenderEnvironment || process.cwd() === '/usr/src/app';

    // En Render/Docker: no priorizar .wwebjs_auth bajo /usr/src/app (EACCES al crear session-*).
    const ordered = deployLike
      ? ['/data/session', tmpSession, fromConfig]
      : [fromConfig, '/data/session', tmpSession];

    for (const dir of ordered) {
      const ok = this.trySessionDataPath(dir);
      if (ok) {
        this.resolvedWhatsappSessionDir = ok;
        if (ok !== fromConfig) {
          this.logger.log(
            `Sesión WA en ${ok} (WHATSAPP_SESSION_DIR en env era "${raw}"; se usa la primera ruta escribible en Docker/Render).`,
          );
        }
        return ok;
      }
    }

    mkdirSync(tmpSession, { recursive: true });
    this.resolvedWhatsappSessionDir = tmpSession;
    this.logger.error(
      `No se pudo preparar ruta de sesión WA; usando ${tmpSession}`,
    );
    return tmpSession;
  }

  private async handleQr(qr: string) {
    this.rawQr = qr;
    this.qrCodeDataUrl = await QRCode.toDataURL(qr);
    this.connectionState = 'qr';
    this.lastError = null;
    const page = this.getPublicQrPageUrl();
    if (page) {
      this.logger.log(
        `QR WhatsApp listo. Abre en el navegador (no uses la consola): ${page}`,
      );
    } else {
      this.logger.log(
        'QR WhatsApp listo. Configura PUBLIC_BASE_URL para ver el enlace en logs.',
      );
    }
  }

  private async handleIncomingMessage(message: Message) {
    if (message.fromMe || !message.from || message.from.endsWith('@g.us')) {
      return;
    }

    const normalizedFrom = this.normalizePhone(message.from);
    const adminPhone = this.normalizePhone(
      this.configService.get<string>('WHATSAPP_NOTIFY_TO') || '',
    );

    if (normalizedFrom && adminPhone && normalizedFrom === adminPhone) {
      const text = this.extractMessageText(message);
      const handled = await this.handleAdminCommand(text, message.from);
      if (handled) {
        return;
      }
    }

    const restaurantHandled = await this.handleRestaurantMessage(
      message,
      normalizedFrom,
    );
    if (restaurantHandled) {
      return;
    }

    if (!this.envTruthy(this.configService.get('WHATSAPP_AUTO_REPLY_ENABLED'))) {
      return;
    }

    if (!this.client || this.connectionState !== 'connected') {
      return;
    }

    const autoReply =
      this.configService.get<string>('WHATSAPP_AUTO_REPLY_TEXT') ||
      'Hola, recibimos tu mensaje en URKUfood. En breve validamos tu pedido o consulta.';

    await this.client.sendMessage(message.from, autoReply);
  }

  private async handlePollVote(vote: any) {
    const adminPhone = this.normalizePhone(
      this.configService.get<string>('WHATSAPP_NOTIFY_TO') || '',
    );
    const voter = this.normalizePhone(vote?.voter || '');

    const selectedOption = this.extractVoteOptionLabel(vote);
    const pollName = this.extractAvailabilityPollName(vote);

    this.logger.log(
      `Availability vote_update <- voter=${voter || 'unknown'} option=${selectedOption || 'unknown'} poll=${pollName || 'missing'} keys=${Object.keys(vote || {}).join(',')}`,
    );

    if (!selectedOption) {
      this.logger.warn(
        'Availability vote_update ignored because no option label was extracted.',
      );
      return;
    }

    if (adminPhone && voter && adminPhone === voter) {
      if (!pollName) {
        this.logger.warn(
          'Admin vote_update ignored because poll name was missing.',
        );
        return;
      }

      const orderCode = this.extractOrderCode(pollName);
      if (!orderCode) {
        return;
      }

      await this.handleAdminCommand(
        `${selectedOption} ${orderCode}`,
        vote.parentMessage.from,
      );
      return;
    }

    if (!voter) {
      this.logger.warn(
        'Availability vote_update ignored because voter phone was missing.',
      );
      return;
    }

    await this.handleAvailabilityVote(voter, selectedOption, pollName);
  }

  private async handleAdminCommand(body: string, chatId: string) {
    const command = body.trim().toUpperCase();
    const status = this.resolveStatusFromCommand(command);
    const orderCode = this.extractOrderCode(command);

    if (!status || !orderCode) {
      return false;
    }

    const order = await this.orderModel.findOne({ orderCode });
    if (!order) {
      if (this.client && this.connectionState === 'connected') {
        await this.client.sendMessage(
          chatId,
          `No encontré el pedido ${orderCode}.`,
        );
      }
      return true;
    }

    order.status = status;
    order.automationLogs.push({
      type: 'order_status_admin_whatsapp',
      target: chatId,
      delivered: true,
      note: `Cambio por comando admin: ${status}`,
    } as never);
    await order.save();

    await this.sendTextMessage(
      order.customerPhone,
      `Actualización de tu pedido ${order.orderCode}: ahora está ${this.statusLabel(status)}.`,
    );

    if (this.client && this.connectionState === 'connected') {
      await this.client.sendMessage(
        chatId,
        `Pedido ${order.orderCode} actualizado a ${this.statusLabel(status)}.`,
      );
    }

    return true;
  }

  private resolveStatusFromCommand(command: string) {
    const upper = command.toUpperCase();

    if (
      upper.startsWith('STATUS_PREPARING_') ||
      upper.startsWith('PREPARANDO_') ||
      upper.includes('PREPARANDO') ||
      upper.includes('PREPARACION')
    ) {
      return 'preparing';
    }

    if (
      upper.startsWith('STATUS_ON_THE_WAY_') ||
      upper.startsWith('ENVIADO_') ||
      upper.includes('ENVIADO') ||
      upper.includes('EN CAMINO') ||
      upper.includes('CAMINO')
    ) {
      return 'on_the_way';
    }

    if (
      upper.startsWith('STATUS_DELIVERED_') ||
      upper.startsWith('ENTREGADO_') ||
      upper.includes('ENTREGADO')
    ) {
      return 'delivered';
    }

    if (upper.includes('CONFIRMAR') || upper.includes('CONFIRMADO')) {
      return 'confirmed';
    }

    return null;
  }

  private extractOrderCode(command: string) {
    const match = command.match(/#?\d{6,}/);
    if (!match) {
      return null;
    }

    return match[0].startsWith('#') ? match[0] : `#${match[0]}`;
  }

  private statusLabel(status: string) {
    switch (status) {
      case 'confirmed':
        return 'confirmado';
      case 'preparing':
        return 'en preparación';
      case 'on_the_way':
        return 'en camino';
      case 'delivered':
        return 'entregado';
      default:
        return status;
    }
  }

  private extractMessageText(message: Message) {
    if (message.type === 'list_response') {
      return ((message as any).selectedRowId || message.body || '') as string;
    }

    if (message.type === 'buttons_response') {
      return ((message as any).selectedButtonId || message.body || '') as string;
    }

    return message.body || '';
  }

  private async handleRestaurantMessage(message: Message, normalizedFrom: string) {
    if (!normalizedFrom) {
      return false;
    }

    const text = this.extractMessageText(message).trim();
    if (!text) {
      return false;
    }

    this.logger.log(
      `Availability inbound message <- from=${normalizedFrom} type=${message.type} text=${text}`,
    );

    const handledSelection = await this.handleAvailabilityTextSelection(
      normalizedFrom,
      text,
    );
    if (handledSelection) {
      return true;
    }

    const session =
      await this.findLatestAvailabilitySessionForPhoneAndFlowSteps(
        normalizedFrom,
        ['dish_number', 'ingredient_dish_number', 'ingredient_name'],
      ) ??
      (await this.findLatestAvailabilitySessionForFlowSteps([
        'dish_number',
        'ingredient_dish_number',
        'ingredient_name',
      ])) ??
      (await this.findAvailabilitySessionByPhone(normalizedFrom));
    if (!session) {
      this.logger.warn(
        `Availability inbound message without matching session for from=${normalizedFrom} text=${text}`,
      );
      return false;
    }

    const restaurant = session.restaurants.find(
      (entry) =>
        this.phonesMatch(entry.restaurantPhone, normalizedFrom) &&
        entry.flowStep !== 'resolved',
    ) ?? session.restaurants.find(
      (entry) =>
        entry.flowStep === 'dish_number' ||
        entry.flowStep === 'ingredient_dish_number' ||
        entry.flowStep === 'ingredient_name',
    );
    if (!restaurant) {
      this.logger.warn(
        `Availability inbound message without matching restaurant for session=${session.id} from=${normalizedFrom} text=${text}`,
      );
      return false;
    }

    if (restaurant.flowStep === 'dish_number') {
      this.logger.log(
        `Availability dish reply matched -> session=${session.id} restaurant=${restaurant.restaurantName} text=${text}`,
      );
      return this.handleDishUnavailableSelection(session, restaurant, text, message.from);
    }

    if (restaurant.flowStep === 'ingredient_dish_number') {
      this.logger.log(
        `Availability ingredient dish reply matched -> session=${session.id} restaurant=${restaurant.restaurantName} text=${text}`,
      );
      return this.handleIngredientDishSelection(session, restaurant, text, message.from);
    }

    if (restaurant.flowStep === 'ingredient_name') {
      this.logger.log(
        `Availability ingredient name reply matched -> session=${session.id} restaurant=${restaurant.restaurantName} text=${text}`,
      );
      return this.handleIngredientNameSelection(session, restaurant, text, message.from);
    }

    return false;
  }

  private async handleAvailabilityTextSelection(
    normalizedFrom: string,
    text: string,
  ) {
    const normalized = text.trim().toUpperCase();
    let selectedOption: string | null = null;

    if (normalized.includes('CONFIRMADO')) {
      selectedOption = 'Confirmado';
    } else if (normalized.includes('PLATO') && normalized.includes('NO DISPONIBLE')) {
      selectedOption = 'Plato no disponible';
    } else if (
      normalized.includes('INGREDIENTE') &&
      normalized.includes('NO DISPONIBLE')
    ) {
      selectedOption = 'Ingrediente no disponible';
    }

    if (selectedOption == null) {
      return false;
    }

    const session =
      await this.findLatestAvailabilitySessionForPhoneAndFlowSteps(
        normalizedFrom,
        ['poll'],
      ) ??
      (await this.findLatestAvailabilitySessionForFlowSteps(['poll'])) ??
      (await this.findAvailabilitySessionByPhone(normalizedFrom));
    if (!session) {
      return false;
    }

    const restaurant = session.restaurants.find(
      (entry) =>
        this.phonesMatch(entry.restaurantPhone, normalizedFrom) &&
        entry.flowStep === 'poll',
    ) ?? session.restaurants.find(
      (entry) => entry.flowStep === 'poll',
    );
    if (!restaurant) {
      return false;
    }

    await this.applyAvailabilitySelection(session, restaurant, selectedOption);
    return true;
  }

  private async handleAvailabilityVote(
    voter: string,
    selectedOption: string,
    pollName?: string,
  ) {
    const trimmedPollName = (pollName || '').trim();
    const session =
      (trimmedPollName.length > 0
        ? await this.findLatestAvailabilitySessionByPollName(trimmedPollName)
        : null) ?? (await this.findAvailabilitySessionByPhone(voter));
    if (!session) {
      this.logger.warn(
        `Availability vote_update without matching session for voter=${voter} poll=${trimmedPollName || 'missing'}`,
      );
      return false;
    }

    const restaurant =
      session.restaurants.find(
        (entry) =>
          trimmedPollName.length > 0 &&
          entry.pollName === trimmedPollName &&
          entry.flowStep === 'poll',
      ) ??
      session.restaurants.find(
        (entry) =>
          trimmedPollName.length > 0 &&
          entry.activePollName === trimmedPollName &&
          (entry.flowStep === 'dish_number' ||
            entry.flowStep === 'ingredient_dish_number'),
      ) ??
      session.restaurants.find(
        (entry) =>
          this.phonesMatch(entry.restaurantPhone, voter) &&
          entry.flowStep === 'poll',
      );
    if (!restaurant) {
      this.logger.warn(
        `Availability vote_update without matching restaurant for session=${session.id} voter=${voter} poll=${trimmedPollName || 'missing'}`,
      );
      return false;
    }

    this.logger.log(
      `Availability vote matched -> session=${session.id} restaurant=${restaurant.restaurantName} option=${selectedOption}`,
    );

    if (restaurant.flowStep === 'dish_number') {
      return this.handleDishUnavailableSelection(
        session,
        restaurant,
        selectedOption,
        restaurant.restaurantPhone,
      );
    }

    if (restaurant.flowStep === 'ingredient_dish_number') {
      return this.handleIngredientDishSelection(
        session,
        restaurant,
        selectedOption,
        restaurant.restaurantPhone,
      );
    }

    await this.applyAvailabilitySelection(session, restaurant, selectedOption);
    return true;
  }

  private async findLatestAvailabilitySessionByPollName(pollName: string) {
    const sessions = await this.availabilitySessionModel
      .find({
        status: { $in: ['pending', 'action_required'] },
        $or: [
          { 'restaurants.pollName': pollName },
          { 'restaurants.activePollName': pollName },
        ],
      })
      .sort({ updatedAt: -1 })
      .limit(10);

    return (
      sessions.find((session) =>
        session.restaurants.some(
          (entry) =>
            (entry.pollName === pollName && entry.flowStep === 'poll') ||
            (entry.activePollName === pollName &&
              (entry.flowStep === 'dish_number' ||
                entry.flowStep === 'ingredient_dish_number')),
        ),
      ) ?? null
    );
  }

  private async findLatestAvailabilitySessionForPhoneAndFlowSteps(
    normalizedPhone: string,
    flowSteps: string[],
  ) {
    const sessions = await this.availabilitySessionModel
      .find({
        status: { $in: ['pending', 'action_required'] },
      })
      .sort({ updatedAt: -1 })
      .limit(20);

    return (
      sessions.find((session) =>
        session.restaurants.some(
          (entry) =>
            this.phonesMatch(entry.restaurantPhone, normalizedPhone) &&
            flowSteps.includes(entry.flowStep),
        ),
      ) ?? null
    );
  }

  private async findLatestAvailabilitySessionForFlowSteps(flowSteps: string[]) {
    const sessions = await this.availabilitySessionModel
      .find({
        status: { $in: ['pending', 'action_required'] },
      })
      .sort({ updatedAt: -1 })
      .limit(20);

    return (
      sessions.find((session) =>
        session.restaurants.some((entry) => flowSteps.includes(entry.flowStep)),
      ) ?? null
    );
  }

  private async applyAvailabilitySelection(
    session: AvailabilitySessionDocument,
    restaurant: AvailabilitySessionRestaurant,
    selectedOption: string,
  ) {
    const normalized = selectedOption.trim().toUpperCase();

    if (normalized.includes('CONFIRMADO')) {
      restaurant.state = 'confirmed';
      restaurant.flowStep = 'resolved';
      restaurant.activePollName = restaurant.pollName;
      restaurant.note = 'El restaurante confirmó todos los platos.';
      await session.save();
      this.recomputeAvailabilityStatus(session);
      await session.save();
      this.logger.log(
        `Availability confirmed -> session=${session.id} restaurant=${restaurant.restaurantName} status=${session.status}`,
      );
      await this.sendTextMessage(
        restaurant.restaurantPhone,
        'Perfecto. Marcamos este pedido como confirmado.',
      );
      return;
    }

    if (normalized.includes('PLATO') && normalized.includes('NO DISPONIBLE')) {
      restaurant.state = 'pending';
      restaurant.flowStep = 'dish_number';
      restaurant.activePollName = `${restaurant.pollName} · PLATO`;
      restaurant.note = 'El restaurante está indicando qué plato no está disponible.';
      this.recomputeAvailabilityStatus(session);
      await session.save();

      if (restaurant.items.length == 1) {
        this.logger.log(
          `Availability auto-select single dish unavailable -> session=${session.id} restaurant=${restaurant.restaurantName}`,
        );
        return this.handleDishUnavailableSelection(
          session,
          restaurant,
          '1',
          restaurant.restaurantPhone,
        );
      }

      this.logger.log(
        `Availability requires dish selection -> session=${session.id} restaurant=${restaurant.restaurantName}`,
      );
      await this.sendAvailabilitySelectionPoll(
        {
          to: restaurant.restaurantPhone,
          body: this.buildNumberedItemsPrompt(
          restaurant,
          '¿Qué plato no está disponible? Selecciónalo en la encuesta o responde sólo con el número.',
        ),
          pollName: restaurant.activePollName,
          options: this.buildItemPollOptions(restaurant),
        },
      );
      return;
    }

    if (
      normalized.includes('INGREDIENTE') &&
      normalized.includes('NO DISPONIBLE')
    ) {
      restaurant.state = 'pending';
      restaurant.flowStep = 'ingredient_dish_number';
      restaurant.activePollName = `${restaurant.pollName} · INGREDIENTE`;
      restaurant.note = 'El restaurante está indicando qué plato tiene un ingrediente faltante.';
      this.recomputeAvailabilityStatus(session);
      await session.save();

      if (restaurant.items.length == 1) {
        restaurant.pendingItemName = restaurant.items[0].name;
        restaurant.flowStep = 'ingredient_name';
        restaurant.activePollName = restaurant.pollName;
        restaurant.note = `Esperando el ingrediente faltante de ${restaurant.pendingItemName}.`;
        await session.save();
        this.logger.log(
          `Availability auto-select single ingredient dish -> session=${session.id} restaurant=${restaurant.restaurantName}`,
        );
        await this.sendTextMessage(
          restaurant.restaurantPhone,
          `¿Qué ingrediente no tienes disponible en ${restaurant.pendingItemName}?`,
        );
        return;
      }

      this.logger.log(
        `Availability requires ingredient selection -> session=${session.id} restaurant=${restaurant.restaurantName}`,
      );
      await this.sendAvailabilitySelectionPoll(
        {
          to: restaurant.restaurantPhone,
          body: this.buildNumberedItemsPrompt(
          restaurant,
          '¿De qué plato falta el ingrediente? Selecciónalo en la encuesta o responde sólo con el número.',
        ),
          pollName: restaurant.activePollName,
          options: this.buildItemPollOptions(restaurant),
        },
      );
    }
  }

  private async handleDishUnavailableSelection(
    session: AvailabilitySessionDocument,
    restaurant: AvailabilitySessionRestaurant,
    text: string,
    chatId: string,
  ) {
    const item = this.resolveSelectedItem(restaurant, text);
    if (!item) {
      await this.sendTextMessage(
        chatId,
        this.buildNumberedItemsPrompt(
          restaurant,
          'No entendí el número. Responde sólo con el plato que no está disponible.',
        ),
      );
      return true;
    }

    restaurant.state = 'dish_unavailable';
    restaurant.flowStep = 'resolved';
    restaurant.activePollName = restaurant.pollName;
    restaurant.unavailableItemName = item.name;
    restaurant.note = `${item.name} no está disponible.`;
    this.recomputeAvailabilityStatus(session);
    await session.save();
    await this.sendTextMessage(
      chatId,
      `Entendido. Notificaremos al cliente que ${item.name} no está disponible.`,
    );
    return true;
  }

  private async handleIngredientDishSelection(
    session: AvailabilitySessionDocument,
    restaurant: AvailabilitySessionRestaurant,
    text: string,
    chatId: string,
  ) {
    const item = this.resolveSelectedItem(restaurant, text);
    if (!item) {
      await this.sendTextMessage(
        chatId,
        this.buildNumberedItemsPrompt(
          restaurant,
          'No entendí el número. Responde sólo con el plato al que le falta el ingrediente.',
        ),
      );
      return true;
    }

    restaurant.pendingItemName = item.name;
    restaurant.flowStep = 'ingredient_name';
    restaurant.activePollName = restaurant.pollName;
    restaurant.note = `Esperando el ingrediente faltante de ${item.name}.`;
    await session.save();
    await this.sendTextMessage(
      chatId,
      `¿Qué ingrediente no tienes disponible en ${item.name}?`,
    );
    return true;
  }

  private async handleIngredientNameSelection(
    session: AvailabilitySessionDocument,
    restaurant: AvailabilitySessionRestaurant,
    text: string,
    chatId: string,
  ) {
    const ingredient = text.trim();
    if (!ingredient) {
      await this.sendTextMessage(
        chatId,
        `Escríbeme el ingrediente que no tienes disponible en ${restaurant.pendingItemName}.`,
      );
      return true;
    }

    restaurant.state = 'ingredient_unavailable';
    restaurant.flowStep = 'resolved';
    restaurant.activePollName = restaurant.pollName;
    restaurant.unavailableItemName = restaurant.pendingItemName;
    restaurant.unavailableIngredient = ingredient;
    restaurant.note = `${restaurant.pendingItemName} no cuenta con ${ingredient}.`;
    restaurant.pendingItemName = '';
    restaurant.continueChosen = false;
    this.recomputeAvailabilityStatus(session);
    await session.save();
    await this.sendTextMessage(
      chatId,
      'Entendido. Le mostraremos al cliente la novedad para que decida si continúa o cancela.',
    );
    return true;
  }

  private buildNumberedItemsPrompt(
    restaurant: AvailabilitySessionRestaurant,
    intro: string,
  ) {
    const items = restaurant.items
      .map((item, index) => `${index + 1}. ${item.quantity}x ${item.name}`)
      .join('\n');
    return [intro, '', items].join('\n');
  }

  private buildItemPollOptions(restaurant: AvailabilitySessionRestaurant) {
    return restaurant.items.map(
      (item, index) => `${index + 1}. ${item.quantity}x ${item.name}`,
    );
  }

  private resolveSelectedItem(
    restaurant: AvailabilitySessionRestaurant,
    text: string,
  ) {
    const match = text.match(/\d+/);
    if (!match) {
      return null;
    }

    const index = Number.parseInt(match[0], 10) - 1;
    if (index < 0 || index >= restaurant.items.length) {
      return null;
    }

    return restaurant.items[index];
  }

  private extractVoteOptionLabel(vote: any) {
    const selected = vote?.selectedOptions?.[0];

    if (
      typeof selected?.name === 'string' &&
      selected.name.trim().length > 0
    ) {
      return selected.name.trim();
    }

    if (
      typeof selected?.localId === 'number' ||
      (typeof selected?.localId === 'string' && selected.localId.trim() !== '')
    ) {
      return this.optionLabelFromVote(vote, Number(selected.localId));
    }

    if (
      typeof selected === 'string' &&
      selected.trim().length > 0 &&
      Number.isNaN(Number(selected))
    ) {
      return selected.trim();
    }

    const localId = vote?.selectedOptionLocalIds?.[0] ?? vote?.selectedOptionIds?.[0];
    if (
      typeof localId === 'number' ||
      (typeof localId === 'string' && localId.trim() !== '')
    ) {
      return this.optionLabelFromVote(vote, Number(localId));
    }

    const fallbackText =
      vote?.selectedOptions?.[0]?.toString?.() || vote?.body?.toString?.() || '';
    return fallbackText.trim();
  }

  private optionLabelFromVote(vote: any, index: number) {
    const candidateCollections = [
      vote?.parentMessage?.options,
      vote?.parentMessage?.pollOptions,
      vote?.parentMessage?.selectableOptions,
      vote?.parentMessage?.pollSelectableOptions,
      vote?.options,
      vote?.pollOptions,
    ];

    for (const collection of candidateCollections) {
      if (!Array.isArray(collection) || collection.length === 0) {
        continue;
      }

      const option = collection[index] ?? collection[index - 1];
      if (typeof option === 'string' && option.trim().length > 0) {
        return option.trim();
      }

      const namedOption =
        option?.name ?? option?.title ?? option?.optionName ?? option?.body;
      if (typeof namedOption === 'string' && namedOption.trim().length > 0) {
        return namedOption.trim();
      }
    }

    return this.voteLabelFromIndex(index);
  }

  private extractAvailabilityPollName(vote: any) {
    const candidates = [
      vote?.parentMessage?.pollName,
      vote?.parentMessage?.body,
      vote?.pollName,
      vote?.pollCreationMessage?.name,
      vote?.pollCreationMessage?.pollName,
      vote?.msg?.pollName,
      vote?.msg?.body,
    ];

    for (const candidate of candidates) {
      if (typeof candidate === 'string' && candidate.trim().length > 0) {
        return candidate.trim();
      }
    }

    return '';
  }

  private voteLabelFromIndex(index: number) {
    switch (index) {
      case 0:
        return 'Confirmado';
      case 1:
        return 'Plato no disponible';
      case 2:
        return 'Ingrediente no disponible';
      default:
        return '';
    }
  }

  private async findAvailabilitySessionByPhone(normalizedPhone: string) {
    const sessions = await this.availabilitySessionModel
      .find({
        status: { $in: ['pending', 'action_required'] },
      })
      .sort({ updatedAt: -1 })
      .limit(12);

    return (
      sessions.find((session) =>
        session.restaurants.some((entry) =>
          this.phonesMatch(entry.restaurantPhone, normalizedPhone),
        ),
      ) ?? null
    );
  }

  private phonesMatch(left: string, right: string) {
    const normalizedLeft = this.normalizePhone(left);
    const normalizedRight = this.normalizePhone(right);
    if (!normalizedLeft || !normalizedRight) {
      return false;
    }

    return (
      normalizedLeft === normalizedRight ||
      normalizedLeft.endsWith(normalizedRight) ||
      normalizedRight.endsWith(normalizedLeft)
    );
  }

  private recomputeAvailabilityStatus(session: AvailabilitySessionDocument) {
    if (session.status === 'cancelled' || session.status === 'completed') {
      return;
    }

    const hasBlockedRestaurant = session.restaurants.some(
      (restaurant) =>
        restaurant.state === 'dish_unavailable' || restaurant.state === 'error',
    );
    if (hasBlockedRestaurant) {
      session.status = 'blocked';
      return;
    }

    const needsDecision = session.restaurants.some(
      (restaurant) =>
        restaurant.state === 'ingredient_unavailable' && !restaurant.continueChosen,
    );
    if (needsDecision) {
      session.status = 'action_required';
      return;
    }

    const hasPendingRestaurant = session.restaurants.some(
      (restaurant) => restaurant.state === 'pending',
    );
    if (hasPendingRestaurant) {
      session.status = 'pending';
      return;
    }

    session.status = 'ready';
  }
}
