import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type AvailabilitySessionDocument = HydratedDocument<AvailabilitySession>;

@Schema({ _id: false })
export class AvailabilitySessionItem {
  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({ required: true, min: 1 })
  quantity!: number;
}

export const AvailabilitySessionItemSchema = SchemaFactory.createForClass(
  AvailabilitySessionItem,
);

@Schema({ _id: false })
export class AvailabilitySessionRestaurant {
  @Prop({ required: true, trim: true })
  restaurantId!: string;

  @Prop({ required: true, trim: true })
  restaurantName!: string;

  @Prop({ required: true, trim: true })
  restaurantPhone!: string;

  @Prop({ default: '', trim: true })
  contactName!: string;

  @Prop({ type: [AvailabilitySessionItemSchema], default: [] })
  items!: AvailabilitySessionItem[];

  @Prop({ required: true, trim: true })
  pollName!: string;

  @Prop({ default: '', trim: true })
  activePollName!: string;

  @Prop({
    required: true,
    enum: [
      'pending',
      'confirmed',
      'dish_unavailable',
      'ingredient_unavailable',
      'error',
    ],
    default: 'pending',
  })
  state!: string;

  @Prop({
    required: true,
    enum: [
      'poll',
      'dish_number',
      'ingredient_dish_number',
      'ingredient_name',
      'resolved',
    ],
    default: 'poll',
  })
  flowStep!: string;

  @Prop({ default: '' })
  unavailableItemName!: string;

  @Prop({ default: '' })
  unavailableIngredient!: string;

  @Prop({ default: '' })
  pendingItemName!: string;

  @Prop({ default: '' })
  note!: string;

  @Prop({ default: false })
  continueChosen!: boolean;
}

export const AvailabilitySessionRestaurantSchema =
  SchemaFactory.createForClass(AvailabilitySessionRestaurant);

@Schema({ timestamps: true })
export class AvailabilitySession {
  @Prop({ required: true, trim: true })
  customerPhone!: string;

  @Prop({ required: true, trim: true })
  deliveryAddress!: string;

  @Prop({ required: true, trim: true })
  paymentMethod!: string;

  @Prop({
    required: true,
    enum: [
      'pending',
      'action_required',
      'ready',
      'blocked',
      'whatsapp_error',
      'cancelled',
      'completed',
    ],
    default: 'pending',
  })
  status!: string;

  @Prop({ type: [AvailabilitySessionRestaurantSchema], default: [] })
  restaurants!: AvailabilitySessionRestaurant[];
}

export const AvailabilitySessionSchema =
  SchemaFactory.createForClass(AvailabilitySession);