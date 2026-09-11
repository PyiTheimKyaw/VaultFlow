# Build from the repository root so workspace packages are available:
#   docker build -f apps/vaultflow_server/Dockerfile -t vaultflow-api .
FROM dart:stable AS build
WORKDIR /workspace
COPY pubspec.yaml analysis_options.yaml ./
COPY packages/vf_core packages/vf_core
COPY packages/vf_protocol packages/vf_protocol
COPY apps/vaultflow_server apps/vaultflow_server
# The workspace root lists Flutter packages too; give the container a trimmed
# workspace that only contains pure-Dart members.
RUN printf 'name: vaultflow_workspace\npublish_to: none\nenvironment:\n  sdk: ^3.13.0\nworkspace:\n  - apps/vaultflow_server\n  - packages/vf_core\n  - packages/vf_protocol\n' > pubspec.yaml
RUN dart pub get
RUN dart pub global activate dart_frog_cli
WORKDIR /workspace/apps/vaultflow_server
RUN /root/.pub-cache/bin/dart_frog build
RUN dart compile exe build/bin/server.dart -o build/bin/server

# Slim Debian instead of scratch so the image has CA certificates (S3 over
# TLS, Sentry) and curl for the container health check.
FROM debian:bookworm-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --create-home vaultflow
COPY --from=build /workspace/apps/vaultflow_server/build/bin/server /app/bin/server
COPY --from=build /workspace/apps/vaultflow_server/migrations /app/migrations
USER vaultflow
WORKDIR /app
EXPOSE 8080
HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD curl -sf http://localhost:8080/health || exit 1
CMD ["/app/bin/server"]
