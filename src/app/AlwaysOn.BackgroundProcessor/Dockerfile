FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env
WORKDIR /app

COPY . ./
RUN dotnet publish AlwaysOn.BackgroundProcessor -c Release -o AlwaysOn.BackgroundProcessor/out

FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /app

RUN mkdir -p /tmp/appinsightschannel

COPY --from=build-env /app/AlwaysOn.BackgroundProcessor/out .
ENTRYPOINT ["dotnet", "AlwaysOn.BackgroundProcessor.dll"]