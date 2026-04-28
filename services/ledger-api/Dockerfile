FROM mcr.microsoft.com/dotnet/sdk@sha256:1d5e6f2c1ece7d5826bafc8a7f2d54db2c6478a0f2bd1c995d05a37c0be4783e AS build

WORKDIR /src
COPY services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj services/ledger-api/dotnet/src/LedgerApi/
RUN dotnet restore services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj

COPY services/ledger-api/dotnet/src/LedgerApi/ services/ledger-api/dotnet/src/LedgerApi/
RUN dotnet publish services/ledger-api/dotnet/src/LedgerApi/LedgerApi.csproj -c Release -o /out/app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet@sha256:ed557d471a2b702b72fd1fd4835040bbbdfbd2532ae78cfc90546773d88a91d7

ARG APP_UID=10001
ARG APP_GID=10001

RUN set -eux; \
    if ! getent group app >/dev/null; then groupadd --gid "${APP_GID}" app; fi; \
    if ! id -u app >/dev/null 2>&1; then useradd --uid "${APP_UID}" --gid app --create-home --shell /usr/sbin/nologin app; fi

WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
COPY --from=build /out/app/ ./
COPY src/supervisory-dashboard ./src/supervisory-dashboard
USER app

ENTRYPOINT ["dotnet", "LedgerApi.dll"]
