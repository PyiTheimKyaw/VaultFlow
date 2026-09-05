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

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /workspace/apps/vaultflow_server/build/bin/server /app/bin/server
EXPOSE 8080
CMD ["/app/bin/server"]
