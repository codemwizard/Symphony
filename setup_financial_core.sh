#!/bin/bash
set -e

mkdir -p FinancialCore/src/FinancialCore.Api
mkdir -p FinancialCore/src/FinancialCore.Domain
mkdir -p FinancialCore/src/FinancialCore.Application
mkdir -p FinancialCore/src/FinancialCore.Infrastructure
mkdir -p FinancialCore/tests/FinancialCore.Tests

cd FinancialCore
if [ ! -f FinancialCore.sln ]; then
    dotnet new sln -n FinancialCore
fi

cd src/FinancialCore.Api
if [ ! -f FinancialCore.Api.csproj ]; then
    dotnet new webapi -f net10.0
    rm -f WeatherForecast.cs Controllers/WeatherForecastController.cs
fi

cd ../FinancialCore.Domain
if [ ! -f FinancialCore.Domain.csproj ]; then
    dotnet new classlib -f net10.0
    rm -f Class1.cs
fi

cd ../FinancialCore.Application
if [ ! -f FinancialCore.Application.csproj ]; then
    dotnet new classlib -f net10.0
    rm -f Class1.cs
fi

cd ../FinancialCore.Infrastructure
if [ ! -f FinancialCore.Infrastructure.csproj ]; then
    dotnet new classlib -f net10.0
    rm -f Class1.cs
fi

cd ../../tests/FinancialCore.Tests
if [ ! -f FinancialCore.Tests.csproj ]; then
    dotnet new xunit -f net10.0
    rm -f UnitTest1.cs
fi

cd ../..
dotnet sln add src/FinancialCore.Api/FinancialCore.Api.csproj
dotnet sln add src/FinancialCore.Domain/FinancialCore.Domain.csproj
dotnet sln add src/FinancialCore.Application/FinancialCore.Application.csproj
dotnet sln add src/FinancialCore.Infrastructure/FinancialCore.Infrastructure.csproj
dotnet sln add tests/FinancialCore.Tests/FinancialCore.Tests.csproj

cd src/FinancialCore.Api
dotnet add reference ../FinancialCore.Application/FinancialCore.Application.csproj
dotnet add reference ../FinancialCore.Infrastructure/FinancialCore.Infrastructure.csproj

cd ../FinancialCore.Application
dotnet add reference ../FinancialCore.Domain/FinancialCore.Domain.csproj

cd ../FinancialCore.Infrastructure
dotnet add reference ../FinancialCore.Domain/FinancialCore.Domain.csproj

cd ../../tests/FinancialCore.Tests
dotnet add reference ../../src/FinancialCore.Domain/FinancialCore.Domain.csproj
dotnet add reference ../../src/FinancialCore.Application/FinancialCore.Application.csproj
dotnet add reference ../../src/FinancialCore.Infrastructure/FinancialCore.Infrastructure.csproj
dotnet add reference ../../src/FinancialCore.Api/FinancialCore.Api.csproj
