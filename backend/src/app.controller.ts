import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AppService } from './app.service';

@ApiTags('health')
@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  getHealth() {
    return this.appService.getHealth();
  }

  /** Peso mínimo para UptimeRobot / cron: evita que Render free “duerma” el servicio. */
  @Get('keepalive')
  keepalive() {
    return { ok: true, t: new Date().toISOString() };
  }
}
