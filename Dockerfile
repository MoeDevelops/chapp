FROM erlang:alpine

WORKDIR /app

ENV DB_HOST=localhost
ENV DB_PORT=5432
ENV DB_SSL=False
ENV DB_USER=postgres
ENV DB_PASSWORD=postgres
ENV DB_IP_VERSION=IPv4

COPY ./build/erlang-shipment .

EXPOSE 3000

CMD ["./entrypoint.sh", "run"]