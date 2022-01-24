FROM node:17.4.0 as build-env
WORKDIR /app

# enable node 17 support for vue-cli
ENV NODE_OPTIONS=--openssl-legacy-provider

COPY . ./
RUN npm install && \
    npm run build

FROM nginx:alpine
COPY --from=build-env /app/dist /usr/share/nginx/html
EXPOSE 80