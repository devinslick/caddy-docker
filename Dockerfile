#
# Builder
#
FROM abiosoft/caddy:builder as builder

ARG version="0.11.3"
ARG plugins="git,filebrowser,cors,realip,expires,cache"

# process wrapper
RUN go get -v github.com/abiosoft/parent

RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=false /bin/sh /usr/bin/builder.sh

#
# Final stage
#
FROM alpine:3.8
LABEL maintainer "Devin Slick <devin.slick@gmail.com>"

ARG version="0.11.3"
LABEL caddy_version="$version"

# Let's Encrypt Agreement
ENV ACME_AGREE="false"

# Telemetry Stats
ENV ENABLE_TELEMETRY="false"

RUN apk add --no-cache openssh-client git

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443
VOLUME /root/.caddy /srv
VOLUME /data
WORKDIR /srv

COPY Caddyfile /etc/Caddyfile

# install process wrapper
COPY --from=builder /go/bin/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
