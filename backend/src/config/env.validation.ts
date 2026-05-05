import { plainToInstance } from 'class-transformer';
import {
    IsNotEmpty,
    IsNumberString,
    IsOptional,
    IsString,
    validateSync,
} from 'class-validator';

class EnvironmentVariables {
  @IsNumberString()
  PORT!: string;

  @IsString()
  @IsNotEmpty()
  MONGODB_URI!: string;

  @IsString()
  @IsNotEmpty()
  JWT_SECRET!: string;

  @IsString()
  @IsNotEmpty()
  JWT_EXPIRES_IN!: string;

  @IsString()
  @IsNotEmpty()
  PUBLIC_BASE_URL!: string;

  @IsOptional()
  @IsString()
  UPLOADS_DIR?: string;

  @IsOptional()
  @IsString()
  GOOGLE_CLIENT_ID?: string;

  @IsOptional()
  @IsString()
  SMTP_HOST?: string;

  @IsOptional()
  @IsNumberString()
  SMTP_PORT?: string;

  @IsOptional()
  @IsString()
  SMTP_SECURE?: string;

  @IsOptional()
  @IsString()
  SMTP_USER?: string;

  @IsOptional()
  @IsString()
  SMTP_PASS?: string;

  @IsOptional()
  @IsString()
  SMTP_FROM?: string;

  @IsOptional()
  @IsString()
  SMTP_TLS_REJECT_UNAUTHORIZED?: string;

  @IsOptional()
  @IsString()
  FCM_PROJECT_ID?: string;

  @IsOptional()
  @IsString()
  FCM_CLIENT_EMAIL?: string;

  @IsOptional()
  @IsString()
  FCM_PRIVATE_KEY?: string;

  @IsString()
  @IsNotEmpty()
  WHATSAPP_ENABLED!: string;

  @IsOptional()
  @IsString()
  WHATSAPP_ALLOW_RENDER?: string;

  @IsOptional()
  @IsString()
  WHATSAPP_QR_PAGE_TOKEN?: string;

  /** Ej. 57 — si el número no empieza por este prefijo, se antepone (pedidos/disponibilidad). */
  @IsOptional()
  @IsString()
  WHATSAPP_PHONE_DEFAULT_CC?: string;

  @IsOptional()
  @IsString()
  WHATSAPP_CONNECT_DELAY_MS?: string;

  @IsOptional()
  @IsString()
  WHATSAPP_READY_WAIT_MS?: string;

  @IsString()
  @IsNotEmpty()
  WHATSAPP_FROM!: string;

  @IsString()
  @IsNotEmpty()
  WHATSAPP_SESSION_DIR!: string;

  @IsString()
  WHATSAPP_NOTIFY_TO!: string;

  @IsString()
  WHATSAPP_TEST_RECIPIENT!: string;

  @IsString()
  @IsNotEmpty()
  WHATSAPP_AUTO_REPLY_ENABLED!: string;

  @IsString()
  @IsNotEmpty()
  WHATSAPP_AUTO_REPLY_TEXT!: string;
}

function sanitizeEnvValue(value: unknown) {
  if (typeof value !== 'string') {
    return value;
  }

  const trimmed = value.trim();
  if (trimmed.length >= 2) {
    const startsWithDoubleQuote =
      trimmed.startsWith('"') && trimmed.endsWith('"');
    const startsWithSingleQuote =
      trimmed.startsWith("'") && trimmed.endsWith("'");

    if (startsWithDoubleQuote || startsWithSingleQuote) {
      return trimmed.slice(1, -1).trim();
    }
  }

  return trimmed;
}

export function validateEnvironment(config: Record<string, unknown>) {
  const sanitizedConfig = Object.fromEntries(
    Object.entries(config).map(([key, value]) => [
      key,
      sanitizeEnvValue(value),
    ]),
  );

  const validatedConfig = plainToInstance(
    EnvironmentVariables,
    sanitizedConfig,
    {
      enableImplicitConversion: true,
    },
  );

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    throw new Error(errors.toString());
  }

  return validatedConfig;
}
