FROM node:16 as builder

WORKDIR /app
COPY . .

WORKDIR /app/config
RUN chmod +x insertqueries.sh && ./insertqueries.sh

WORKDIR /app/healthmodelpanel
RUN npm install

FROM grafana/grafana:8.3.4

ENV GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS="healthmodelpanel"

WORKDIR /var/lib/grafana/plugins/alwayson-healthmodelpanel/
COPY --from=builder /app/healthmodelpanel/* .
COPY --from=builder /app/config/grafana.ini /etc/grafana
COPY --from=builder /app/config/provisioning /etc/grafana/provisioning

EXPOSE 3000/tcp