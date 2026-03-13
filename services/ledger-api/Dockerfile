FROM mcr.microsoft.com/dotnet/aspnet@sha256:88c86e5469c2b69969e07343193fd3dbe4ff6936d95b994dbfa27348299af111

ARG APP_UID=10001
ARG APP_GID=10001

RUN set -eux; \
    if ! getent group app >/dev/null; then groupadd --gid "${APP_GID}" app; fi; \
    if ! id -u app >/dev/null 2>&1; then useradd --uid "${APP_UID}" --gid app --create-home --shell /usr/sbin/nologin app; fi

WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
COPY .publish/app/ ./
COPY .publish/src/supervisory-dashboard ./src/supervisory-dashboard
COPY .publish/scripts ./scripts
COPY .publish/evidence ./evidence
USER app

ENTRYPOINT ["dotnet", "LedgerApi.dll"]
