# renovate: datasource=github-releases depName=aptible/supercronic
ARG SUPERCRONIC_VERSION=v0.2.29

# renovate: datasource=github-releases depName=DarthSim/overmind
ARG OVERMIND_VERSION=v2.4.0

# Binary file names
ARG SUPERCRONIC=supercronic-linux-amd64
ARG OVERMIND=overmind-${OVERMIND_VERSION}-linux-amd64

FROM vaultwarden/server:1.30.5-alpine as vaultwarden

#
# Supercronic
#
FROM alpine:3.19 as supercronic

ARG SUPERCRONIC_VERSION
ARG OVERMIND_VERSION
ARG SUPERCRONIC
ARG OVERMIND

ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/${SUPERCRONIC_VERSION}/${SUPERCRONIC}

WORKDIR /

RUN wget "$SUPERCRONIC_URL" && chmod +x "$SUPERCRONIC"

#
# Overmind
#
FROM alpine:3.19 as overmind

ARG OVERMIND_VERSION
ARG SUPERCRONIC
ARG OVERMIND

ENV OVERMIND_FILE=overmind-${OVERMIND_VERSION}-linux-amd64.gz

ENV OVERMIND_URL=https://github.com/DarthSim/overmind/releases/download/${OVERMIND_VERSION}/${OVERMIND_FILE}

WORKDIR /

RUN wget "$OVERMIND_URL" && gunzip ${OVERMIND_FILE} && chmod +x "$OVERMIND"

#
# Fly app
#
FROM caddy:2.7.6-alpine

ARG SUPERCRONIC
ARG OVERMIND

ENV ROCKET_PROFILE="release" \
  ROCKET_ADDRESS=0.0.0.0 \
  ROCKET_PORT=8080 \
  SSL_CERT_DIR=/etc/ssl/certs

ENV OVERMIND_CAN_DIE=setupmsmtp

RUN apk add --no-cache \
  ca-certificates \
  curl \
  openssl \
  tzdata \
  iptables \
  ip6tables \
  tmux \
  sqlite \
  restic \
  msmtp \
  mailx

VOLUME /data

EXPOSE 80

WORKDIR /

RUN ln -sf /usr/bin/msmtp /usr/bin/sendmail
RUN ln -sf /usr/bin/msmtp /usr/sbin/sendmail

COPY --from=supercronic /${SUPERCRONIC} /usr/bin/supercronic
COPY --from=overmind /${OVERMIND} /usr/bin/overmind

COPY --from=vaultwarden /web-vault ./web-vault
COPY --from=vaultwarden /vaultwarden .

COPY --from=vaultwarden /healthcheck.sh .
COPY --from=vaultwarden /start.sh ./vaultwarden.sh

COPY config/crontab .
COPY config/Procfile .
COPY config/Caddyfile /etc/caddy/Caddyfile
COPY scripts/restic-backup.sh .
COPY scripts/setup-msmtp.sh .

CMD ["overmind", "start"]