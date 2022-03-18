FROM node:16 as builder

WORKDIR /app
COPY . .

RUN /app/config/insertqueries.sh

WORKDIR /app/healthmodelpanel
RUN npm install
RUN mv $(ls -ld ./node_modules/* | grep grafana-healthmodelpanel | awk '{print $9}')/* .
#RUN cd $(ls -ld ./node_modules/* | grep grafana-healthmodelpanel | awk '{print $9}') && pwd
#RUN mv ./node_modules/@nielsams/grafana-healthmodelpanel/* .

FROM grafana/grafana:8.3.4

ENV GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS="alwayson-healthmodelpanel"

WORKDIR /var/lib/grafana/plugins/alwayson-healthmodelpanel/
COPY --from=builder /app/healthmodelpanel/* .
COPY --from=builder /app/config/grafana.ini /etc/grafana
COPY --from=builder /app/config/provisioning /etc/grafana/provisioning

EXPOSE 3000/tcp