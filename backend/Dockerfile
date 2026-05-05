FROM node:20-bullseye AS builder

WORKDIR /usr/src/app

# Copiar package.json antes para caché
COPY package*.json ./

# Instalar dependencias completas (incluye dev) para poder compilar
RUN npm ci

# Copiar el resto y compilar
COPY . .
RUN npm run build

FROM node:20-bullseye AS runner
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependencias del sistema necesarias para Chromium en la imagen final
RUN set -eux; \
  attempt=0; max=5; \
  until [ "$attempt" -ge "$max" ]; do \
    apt-get update && apt-get install -y -o Acquire::Retries=3 --no-install-recommends \
      wget gnupg ca-certificates fonts-liberation \
      libnss3 libxss1 libx11-xcb1 libasound2 libatk1.0-0 libatk-bridge2.0-0 \
      libcups2 libxcomposite1 libxdamage1 libxrandr2 libgbm1 libgtk-3-0 libxrender1 libxtst6 && break || true; \
    attempt=$((attempt+1)); \
    echo "apt install attempt $attempt/$max failed, retrying in 5s..."; \
    sleep 5; \
  done; \
  rm -rf /var/lib/apt/lists/*;

# Instalar Google Chrome estable en la imagen final
RUN set -eux; \
  wget -q -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; \
  attempt=0; max=5; \
  until [ "$attempt" -ge "$max" ]; do \
    apt-get update && apt-get install -y -o Acquire::Retries=3 --no-install-recommends /tmp/google-chrome-stable_current_amd64.deb && break || true; \
    attempt=$((attempt+1)); \
    echo "chrome install attempt $attempt/$max failed, retrying in 5s..."; \
    sleep 5; \
  done; \
  rm -f /tmp/google-chrome-stable_current_amd64.deb; \
  rm -rf /var/lib/apt/lists/*;

WORKDIR /usr/src/app

# Copiar solo dependencias de producción para mantener la imagen ligera
COPY package*.json ./
RUN npm ci --omit=dev

# Copiar artefactos compilados desde el stage builder
COPY --from=builder /usr/src/app/dist ./dist

# Crear carpetas necesarias y establecer permisos antes de cambiar a usuario no-root
ENV NODE_ENV=production
ENV WHATSAPP_SESSION_DIR=/data/session
ENV WHATSAPP_CHROME_PATH=/usr/bin/google-chrome-stable
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable
ENV PUPPETEER_CACHE_DIR=/usr/src/app/.cache/puppeteer
RUN set -eux; \
  mkdir -p /data/session /usr/src/app/uploads /usr/src/app/.cache/puppeteer /usr/src/app/.wwebjs_auth; \
  chown -R node:node /data/session /usr/src/app/uploads /usr/src/app/.cache /usr/src/app/.wwebjs_auth; \
  chmod -R 0755 /usr/src/app/uploads /usr/src/app/.cache /usr/src/app/.wwebjs_auth || true

EXPOSE 3000

USER node
CMD ["node","dist/main"]
