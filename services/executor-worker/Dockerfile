FROM mcr.microsoft.com/dotnet/sdk@sha256:478b9038d187e5b5c29bfa8173ded5d29e864b5ad06102a12106380ee01e2e49 AS build

WORKDIR /src
COPY services/executor-worker/dotnet/src/ExecutorWorker/ExecutorWorker.csproj services/executor-worker/dotnet/src/ExecutorWorker/
RUN dotnet restore services/executor-worker/dotnet/src/ExecutorWorker/ExecutorWorker.csproj

COPY services/executor-worker/dotnet/src/ExecutorWorker/ services/executor-worker/dotnet/src/ExecutorWorker/
RUN dotnet publish services/executor-worker/dotnet/src/ExecutorWorker/ExecutorWorker.csproj -c Release -o /out/app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet@sha256:88c86e5469c2b69969e07343193fd3dbe4ff6936d95b994dbfa27348299af111

ARG APP_UID=10001
ARG APP_GID=10001

RUN set -eux; \
    if ! getent group app >/dev/null; then groupadd --gid "${APP_GID}" app; fi; \
    if ! id -u app >/dev/null 2>&1; then useradd --uid "${APP_UID}" --gid app --create-home --shell /usr/sbin/nologin app; fi

WORKDIR /app
ENV DOTNET_EnableDiagnostics=0
COPY --from=build /out/app/ ./
USER app

ENTRYPOINT ["dotnet", "ExecutorWorker.dll"]
