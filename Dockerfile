FROM erlang:latest

WORKDIR /app

ENV HOST=localhost
ENV PORT=5432
ENV SSL=False
ENV USER=postgres
ENV PASSWORD=example
ENV IP_VERSION=IPv4

COPY ./build/erlang-shipment .

EXPOSE 3000

CMD ["./entrypoint.sh", "run"]