# Create build environment
FROM node:17.8.0 as build-env

# enable node 17 support for vue-cli
ENV NODE_OPTIONS=--openssl-legacy-provider

WORKDIR /app
COPY . ./
RUN npm install && \
    npm run build

# Create application container
FROM mcr.microsoft.com/oss/nginx/nginx:1.17.5-alpine
# Copy build artifacts from previous stage build-env
COPY --from=build-env /app/dist /usr/share/nginx/html
EXPOSE 80