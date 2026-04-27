FROM mcr.microsoft.com/dotnet/sdk@sha256:1d5e6f2c1ece7d5826bafc8a7f2d54db2c6478a0f2bd1c995d05a37c0be4783e AS build

WORKDIR /src
COPY services/executor-worker/dotnet/src/ExecutorWorker/ExecutorWorker.csproj services/executor-worker/dotnet/src/ExecutorWorker/
RUN dotnet restore services/executor-worker/dotnet/src/ExecutorWorker/ExecutorWorker.csproj

COPY services/executor-worker/dotnet/src/ExecutorWorker/ services/executor-worker/dotnet/src/ExecutorWorker/
RUN dotnet publish services/executor-worker/dotnet/src/ExecutorWorker/ExecutorWorker.csproj -c Release -o /out/app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet@sha256:ed557d471a2b702b72fd1fd4835040bbbdfbd2532ae78cfc90546773d88a91d7

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
