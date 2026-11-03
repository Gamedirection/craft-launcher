# syntax=docker/dockerfile:1
# Self-hosted web build of the launcher (fork branch `self-hosted-links`). At run time the
# entrypoint writes craft-links.json from CRAFT_LINK_* variables, so each card's main button
# opens that app's self-hosted instance instead of offering a download.
ARG RUST_VERSION=1.99
ARG NGINX_VERSION=1.28-alpine

FROM rust:${RUST_VERSION}-slim-bookworm AS builder
ARG TRUNK_VERSION=0.21.14
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && rustup target add wasm32-unknown-unknown
RUN set -eu; \
    case "$(uname -m)" in x86_64) arch=x86_64 ;; aarch64) arch=aarch64 ;; *) exit 1 ;; esac; \
    asset="trunk-${arch}-unknown-linux-musl.tar.gz"; \
    url="https://github.com/trunk-rs/trunk/releases/download/v${TRUNK_VERSION}"; \
    cd /tmp; \
    curl --proto '=https' -fsSL --retry 3 "$url/$asset" -o "$asset"; \
    curl --proto '=https' -fsSL --retry 3 "$url/$asset.sha256" -o "$asset.sha256"; \
    printf '%s  %s\n' "$(cat "$asset.sha256")" "$asset" | sha256sum -c -; \
    tar -xzf "$asset" -C /usr/local/bin trunk; \
    rm "$asset" "$asset.sha256"
WORKDIR /src
COPY . .
WORKDIR /src/apps/artcraft-launcher-web
ARG CARGO_PROFILE_WASM_RELEASE_LTO=thin
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/src/target \
    --mount=type=cache,target=/root/.cache/trunk \
    trunk build --release --locked --cargo-profile wasm-release \
    && test -s /src/dist/web/index.html \
    && gzip -9 -k /src/dist/web/*.wasm /src/dist/web/*.js /src/dist/web/index.html

FROM nginx:${NGINX_VERSION}
COPY packaging/docker/nginx.conf /etc/nginx/nginx.conf
COPY packaging/docker/40-craft-links.sh /docker-entrypoint.d/40-craft-links.sh
COPY --from=builder /src/dist/web/ /usr/share/nginx/html/
COPY LICENSE-MIT LICENSE-APACHE /usr/share/nginx/html/
RUN chmod +x /docker-entrypoint.d/40-craft-links.sh
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
