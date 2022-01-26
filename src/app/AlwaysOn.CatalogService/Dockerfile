FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env
WORKDIR /app
COPY . ./
RUN dotnet publish AlwaysOn.CatalogService -c Release -o AlwaysOn.CatalogService/out

FROM mcr.microsoft.com/dotnet/aspnet:6.0

RUN apt-get update && apt-get upgrade -y \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /tmp/appinsightschannel
RUN groupadd -r workload && useradd --no-log-init -r -g workload workload
USER workload

WORKDIR /app
COPY --from=build-env /app/AlwaysOn.CatalogService/out .

EXPOSE 80
ENTRYPOINT ["dotnet", "AlwaysOn.CatalogService.dll"]