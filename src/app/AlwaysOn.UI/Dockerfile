FROM node:15.14 as build-env
WORKDIR /app

COPY . ./
RUN npm install && \
    npm run build

FROM nginx:alpine
COPY --from=build-env /app/dist /usr/share/nginx/html
EXPOSE 80