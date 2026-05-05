import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  Query,
  Redirect,
  Res,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Response } from 'express';
import { WhatsappService } from './whatsapp.service';

@Controller('automation/whatsapp')
export class AutomationController {
  constructor(
    private readonly whatsappService: WhatsappService,
    private readonly configService: ConfigService,
  ) {}

  /** Atajo: /automation/whatsapp → página del QR. */
  @Get()
  @Redirect('/automation/whatsapp/qr-page', 302)
  qrEntry(): void {
    return;
  }

  @Get('status')
  getStatus() {
    return this.whatsappService.getStatus();
  }

  /**
   * Página HTML para ver el QR en el navegador (en Render no hay consola interactiva).
   * Opcional: WHATSAPP_QR_PAGE_TOKEN en env y ?token=... en la URL para limitar el acceso.
   */
  @Get('qr-page')
  qrPage(@Query('token') token: string | undefined, @Res() res: Response) {
    const expected = this.configService
      .get<string>('WHATSAPP_QR_PAGE_TOKEN')
      ?.trim();
    if (expected && token !== expected) {
      res.status(401).type('text/plain').send('No autorizado');
      return;
    }
    const publicBase =
      this.whatsappService.resolvePublicBaseUrl()?.replace(/\/$/, '') ?? '';
    res
      .type('text/html; charset=utf-8')
      .send(buildWhatsappQrPageHtml(publicBase));
  }

  @Post('connect')
  @HttpCode(200)
  connect() {
    return this.whatsappService.connect();
  }

  @Post('test-message')
  @HttpCode(200)
  sendTestMessage(@Body() body: { to?: string; message?: string }) {
    if (body?.message?.trim()) {
      return this.whatsappService.sendTextMessage(
        body.to || '',
        body.message.trim(),
      );
    }

    return this.whatsappService.sendTestMessage(body?.to);
  }
}

function buildWhatsappQrPageHtml(publicBase: string): string {
  const safeBase = JSON.stringify(publicBase);
  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WhatsApp — URKUfood</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 28rem; margin: 1.25rem auto; padding: 0 1rem; line-height: 1.45; }
    img { width: 100%; height: auto; display: block; background: #fff; border-radius: 8px; border: 1px solid #e8e8e8; }
    .err { color: #b00020; font-size: 0.9rem; }
    .box { background: #f8f8f8; border-radius: 10px; padding: 0.85rem 1rem; margin: 0.75rem 0; font-size: 0.88rem; }
    .box code { word-break: break-all; font-size: 0.8rem; }
    button { margin-top: 0.5rem; margin-right: 0.5rem; padding: 0.5rem 1rem; cursor: pointer; }
    h1 { font-size: 1.35rem; }
  </style>
</head>
<body>
  <h1>Vincular WhatsApp (servidor)</h1>
  <p>Usa <strong>este enlace</strong> para abrir o compartir la pantalla del QR. No hace falta mirar la consola del servidor.</p>
  <div class="box" id="linkbox">
    <div><strong>Enlace a esta página</strong></div>
    <p id="pageUrl" style="margin:0.4rem 0 0 0"><code>…</code></p>
    <button type="button" id="copyUrl">Copiar enlace</button>
  </div>
  <div class="box">
    <strong>Mantener el servicio despierto (Render free)</strong>
    <p style="margin:0.4rem 0 0 0">Configura UptimeRobot, cron-job.org o similar con un GET cada <strong>5 min</strong> a la URL mínima (no gasta casi ancho de banda):</p>
    <p id="keepUrl" style="margin:0.3rem 0 0 0"><code>…</code></p>
    <button type="button" id="copyKeep">Copiar URL keep-alive</button>
  </div>
  <p id="state">Cargando estado…</p>
  <div id="qr"></div>
  <p id="hint" class="err"></p>
  <button type="button" id="connect">Pedir código QR nuevo</button>
  <script>
    (function () {
      var base = ${safeBase};
      var origin = location.origin;
      var pagePath = origin + '/automation/whatsapp/qr-page' + location.search;
      var keepPath = origin + '/keepalive';
      if (base) {
        pagePath = base + '/automation/whatsapp/qr-page' + location.search;
        keepPath = base + '/keepalive';
      }
      document.getElementById('pageUrl').innerHTML = '<code>' + pagePath + '</code>';
      document.getElementById('keepUrl').innerHTML = '<code>' + keepPath + '</code>';
      function copy(text) {
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(text).then(function () { alert('Copiado.'); });
        } else {
          prompt('Copia:', text);
        }
      }
      document.getElementById('copyUrl').onclick = function () { copy(pagePath); };
      document.getElementById('copyKeep').onclick = function () { copy(keepPath); };
    })();
    async function loadStatus() {
      const r = await fetch('status', { cache: 'no-store' });
      return r.json();
    }
    async function postConnect() {
      await fetch('connect', { method: 'POST', headers: { 'Content-Type': 'application/json' } });
    }
    function render(j) {
      var st = document.getElementById('state');
      var qr = document.getElementById('qr');
      var hint = document.getElementById('hint');
      if (!j.enabled) {
        st.textContent = 'WhatsApp deshabilitado en el servidor.';
        qr.innerHTML = '';
        hint.textContent = 'Render: WHATSAPP_ENABLED=true y WHATSAPP_ALLOW_RENDER=true.';
        return;
      }
      st.textContent = 'Estado: ' + (j.state || '—');
      hint.textContent = j.lastError || '';
      if (j.qrCodeDataUrl) {
        qr.innerHTML = '<img src="' + j.qrCodeDataUrl.replace(/"/g, '&quot;') + '" alt="Código QR WhatsApp">';
        if (!hint.textContent) hint.textContent = 'Teléfono: WhatsApp → Dispositivos vinculados → Vincular dispositivo.';
      } else if (j.state === 'connected') {
        qr.innerHTML = '<p><strong>Conectado.</strong> Ya puedes cerrar esta página.</p>';
        hint.textContent = '';
      } else {
        qr.innerHTML = '';
      }
    }
    async function poll() {
      try {
        render(await loadStatus());
      } catch (e) {
        document.getElementById('state').textContent = 'Error de red.';
        document.getElementById('hint').textContent = String(e);
      }
    }
    document.getElementById('connect').addEventListener('click', function () {
      postConnect().then(poll).catch(poll);
    });
    poll();
    setInterval(poll, 2500);
  </script>
</body>
</html>`;
}
