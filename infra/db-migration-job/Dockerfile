FROM postgres@sha256:97ff59a4e30e08d1c11bdcd9455e7832368c0572b576c9092cde2df4ae5552a3

ARG APP_UID=10001
ARG APP_GID=10001

RUN set -eux; \
    if ! getent group app >/dev/null; then addgroup -g "${APP_GID}" app; fi; \
    if ! id -u app >/dev/null 2>&1; then adduser -D -u "${APP_UID}" -G app app; fi

WORKDIR /job
USER app

# Deterministic placeholder entrypoint for Phase-1 migration job image gate.
CMD ["/bin/sh", "-lc", "echo db-migration-job container image built"]
