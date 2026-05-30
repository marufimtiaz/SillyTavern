FROM node:lts-alpine3.23

ARG APP_HOME=/home/node/app

ENV NODE_ENV=production

# Install dependencies
RUN apk add --no-cache \
    gcompat \
    tini \
    git \
    git-lfs \
    su-exec \
    shadow \
    dos2unix

WORKDIR ${APP_HOME}

# Copy package files first for better layer caching
COPY --chown=node:node package*.json ./

RUN npm ci \
    --no-audit \
    --no-fund \
    --loglevel=error \
    --no-progress \
    --omit=dev \
    --ignore-scripts \
 && npm cache clean --force

# Copy application
COPY --chown=node:node . .

# Create required directories
RUN mkdir -p \
      config \
      data \
      plugins \
      public/scripts/extensions/third-party \
      backups \
 && chown -R node:node \
      config \
      data \
      plugins \
      public/scripts/extensions/third-party \
      backups

# Build frontend libraries
RUN node ./docker/build-lib.js

# Prepare entrypoint
RUN mv ./docker/docker-entrypoint.sh ./ \
 && chmod +x ./docker-entrypoint.sh \
 && dos2unix ./docker-entrypoint.sh \
 && rm -rf ./docker

# Git safety for extensions
RUN git config --global --add safe.directory "*"

EXPOSE 8000

ENTRYPOINT ["tini", "--", "./docker-entrypoint.sh"]