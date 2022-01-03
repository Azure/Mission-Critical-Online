FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env
WORKDIR /app

COPY . ./
RUN dotnet publish AlwaysOn.HealthService -c Release -o AlwaysOn.HealthService/out

FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app
EXPOSE 80

RUN mkdir -p /tmp/appinsightschannel

COPY --from=build-env /app/AlwaysOn.HealthService/out .
ENTRYPOINT ["dotnet", "AlwaysOn.HealthService.dll"]