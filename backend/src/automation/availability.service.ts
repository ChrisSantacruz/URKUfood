import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { StartAvailabilityDto } from './dto/start-availability.dto';
import {
    AvailabilitySession,
    AvailabilitySessionDocument,
    AvailabilitySessionRestaurant,
} from './schemas/availability-session.schema';
import { WhatsappService } from './whatsapp.service';

@Injectable()
export class AvailabilityService {
  private readonly logger = new Logger(AvailabilityService.name);

  constructor(
    @InjectModel(AvailabilitySession.name)
    private readonly availabilitySessionModel: Model<AvailabilitySessionDocument>,
    private readonly whatsappService: WhatsappService,
    private readonly configService: ConfigService,
  ) {}

  async startSession(dto: StartAvailabilityDto) {
    const pollSeed = Date.now().toString(36).toUpperCase();
    const restaurants = dto.restaurants.map((restaurant, index) => {
      const pollName = this.buildPollName(
        restaurant.restaurantName,
        index,
        pollSeed,
      );

      return {
        restaurantId: restaurant.restaurantId,
        restaurantName: restaurant.restaurantName.trim(),
        restaurantPhone: this.normalizePhone(restaurant.restaurantPhone),
        contactName: (restaurant.contactName ?? '').trim(),
        items: restaurant.items.map((item) => ({
          name: item.name.trim(),
          quantity: item.quantity,
        })),
        pollName,
        activePollName: pollName,
        state: 'pending',
        flowStep: 'poll',
        unavailableItemName: '',
        unavailableIngredient: '',
        pendingItemName: '',
        note: '',
        continueChosen: false,
      };
    });

    const session = await this.availabilitySessionModel.create({
      customerPhone: this.normalizePhone(dto.customerPhone),
      deliveryAddress: dto.deliveryAddress.trim(),
      paymentMethod: dto.paymentMethod.trim(),
      status: 'pending',
      restaurants,
    });

    this.logger.log(
      `Availability session ${session.id} created with ${session.restaurants.length} restaurant(s).`,
    );
    this.logger.log(
      `Availability teléfonos normalizados: ${session.restaurants.map((r) => `${r.restaurantName}=${r.restaurantPhone}`).join('; ')}`,
    );

    for (const restaurant of session.restaurants) {
      const result = await this.whatsappService.sendAvailabilityRequest({
        to: restaurant.restaurantPhone,
        body: this.buildRestaurantMessage(session, restaurant),
        pollName: restaurant.pollName,
      });

      const errMsg =
        typeof result === 'object' &&
        result !== null &&
        'error' in result &&
        typeof (result as { error?: unknown }).error === 'string'
          ? (result as { error: string }).error
          : '';
      this.logger.log(
        `Availability send -> session=${session.id} restaurant=${restaurant.restaurantName} phone=${restaurant.restaurantPhone} delivered=${result.delivered}`,
      );

      if (!result.delivered) {
        if (errMsg) {
          this.logger.warn(
            `Availability WhatsApp falló (${restaurant.restaurantName}): ${errMsg}`,
          );
        }
        restaurant.state = 'error';
        restaurant.flowStep = 'resolved';
        restaurant.note =
          errMsg || 'No se pudo enviar la validación por WhatsApp.';
      }
    }

    this.recomputeSessionStatus(session);
    await session.save();
    return this.serializeSession(session);
  }

  async getSession(id: string) {
    const session = await this.availabilitySessionModel.findById(id).lean();
    if (!session) {
      throw new NotFoundException('Validation session not found');
    }

    this.logger.log(
      `Availability poll <- session=${id} status=${session.status} restaurants=${session.restaurants
        .map((restaurant) => `${restaurant.restaurantName}:${restaurant.state}`)
        .join(', ')}`,
    );

    return this.serializeSession(session);
  }

  async continueWithIngredientIssue(id: string, restaurantId: string) {
    const session = await this.availabilitySessionModel.findById(id);
    if (!session) {
      throw new NotFoundException('Validation session not found');
    }

    const restaurant = session.restaurants.find(
      (entry) => entry.restaurantId === restaurantId,
    );
    if (!restaurant) {
      throw new NotFoundException('Restaurant validation not found');
    }

    restaurant.continueChosen = true;
    restaurant.note = restaurant.note.trim().length === 0
      ? 'El cliente decidió continuar con el pedido.'
      : restaurant.note;
    this.recomputeSessionStatus(session);
    await session.save();
    this.logger.log(
      `Availability continue -> session=${id} restaurant=${restaurant.restaurantName} status=${session.status}`,
    );
    return this.serializeSession(session);
  }

  async cancelSession(id: string) {
    const session = await this.availabilitySessionModel.findById(id);
    if (!session) {
      throw new NotFoundException('Validation session not found');
    }

    session.status = 'cancelled';
    await session.save();
    this.logger.log(`Availability cancel -> session=${id}`);
    return this.serializeSession(session);
  }

  private buildPollName(
    restaurantName: string,
    index: number,
    pollSeed: string,
  ) {
    return `Validación ${index + 1} · ${restaurantName.trim()} · ${pollSeed}`;
  }

  private buildRestaurantMessage(
    session: AvailabilitySessionDocument,
    restaurant: AvailabilitySessionRestaurant,
  ) {
    const items = restaurant.items
      .map((item, index) => `${index + 1}. ${item.quantity}x ${item.name}`)
      .join('\n');
    const greeting = restaurant.contactName.trim().length === 0
      ? 'Hola'
      : `Hola ${restaurant.contactName.trim()}`;

    return [
      `${greeting}, te escribe La Carta para validar un pedido antes del cobro.`,
      '',
      'Pedido solicitado:',
      items,
      '',
      'Dirección de entrega:',
      session.deliveryAddress,
      '',
      'Por favor responde la encuesta con una de estas opciones:',
      '1. Confirmado',
      '2. Plato no disponible',
      '3. Ingrediente no disponible',
      '',
      'Si eliges una novedad, el bot te pedirá el detalle enseguida.',
    ].join('\n');
  }

  private recomputeSessionStatus(session: AvailabilitySessionDocument) {
    if (session.status === 'cancelled' || session.status === 'completed') {
      return;
    }

    const hasSendError = session.restaurants.some(
      (restaurant) => restaurant.state === 'error',
    );
    if (hasSendError) {
      session.status = 'whatsapp_error';
      return;
    }

    const hasDishUnavailable = session.restaurants.some(
      (restaurant) => restaurant.state === 'dish_unavailable',
    );
    if (hasDishUnavailable) {
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

    const pendingRestaurants = session.restaurants.some(
      (restaurant) => restaurant.state === 'pending',
    );
    if (pendingRestaurants) {
      session.status = 'pending';
      return;
    }

    session.status = 'ready';
  }

  private normalizePhone(value: string) {
    let digits = value.replace(/[^0-9]/g, '');
    const cc = this.configService
      .get<string>('WHATSAPP_PHONE_DEFAULT_CC')
      ?.trim();
    if (
      cc &&
      digits.length > 0 &&
      !digits.startsWith(cc) &&
      /^[1-9]\d{0,3}$/.test(cc)
    ) {
      digits = `${cc}${digits}`;
    }
    return digits;
  }

  private serializeSession(session: {
    id?: string;
    _id?: { toString(): string };
    status: string;
    restaurants: Array<{
      restaurantId: string;
      restaurantName: string;
      restaurantPhone: string;
      items: Array<{ name: string; quantity: number }>;
      state: string;
      unavailableItemName?: string;
      unavailableIngredient?: string;
      note?: string;
      continueChosen?: boolean;
    }>;
  }) {
    const sessionId = session.id ?? session._id?.toString() ?? '';
    return {
      'id': sessionId,
      'status': session.status,
      'restaurants': session.restaurants.map((restaurant) => {
        return {
          'restaurantId': restaurant.restaurantId,
          'restaurantName': restaurant.restaurantName,
          'restaurantPhone': restaurant.restaurantPhone,
          'items': restaurant.items
            .map((item) => ({
              'name': item.name,
              'quantity': item.quantity,
            })),
          'state': restaurant.state,
          'unavailableItemName': restaurant.unavailableItemName ?? '',
          'unavailableIngredient': restaurant.unavailableIngredient ?? '',
          'note': restaurant.note ?? '',
          'continueChosen': restaurant.continueChosen ?? false,
        };
      }),
    };
  }
}