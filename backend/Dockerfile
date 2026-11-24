# The SolaCliq API as a container image (deploy/README.md).
#   docker build -t solacliq-api:<commit> backend
# Migrations are compiled into the binary and run at every start.

# Build: dependencies first, in their own layer, so a code change
# rebuilds only the crate.
FROM docker.io/library/rust:1.98-bookworm AS build
WORKDIR /src
# Fewer jobs than cores: a release build of this crate otherwise peaks
# above 4 GB.
ENV CARGO_BUILD_JOBS=4
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo 'fn main() {}' > src/main.rs && touch src/lib.rs \
    && cargo build --release --locked \
    && rm -rf src
COPY migrations migrations
COPY src src
# Newer than the placeholder build, so cargo rebuilds the crate itself.
RUN touch src/main.rs src/lib.rs && cargo build --release --locked

# Run: the binary, CA certificates (R2, Gmail and FCM are HTTPS) and
# curl for the health check; nothing else.
FROM docker.io/library/debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --no-create-home --shell /usr/sbin/nologin solacliq
COPY --from=build /src/target/release/backend /usr/local/bin/solacliq-api
USER 10001
ENV BIND_ADDR=0.0.0.0:8080 LOG_JSON=true
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --start-period=30s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/api/v1/health || exit 1
ENTRYPOINT ["solacliq-api"]
