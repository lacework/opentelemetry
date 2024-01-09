FROM alpine:latest

RUN apk --no-cache add curl && apk --no-cache add bash && apk --no-cache add jq
RUN adduser -S telemetry -G users
USER telemetry

WORKDIR /app
COPY ./src/lacework /app

ENTRYPOINT [ "/app/shared/start.sh" ]

#CMD ["-c", "echo ERROR: No job specified&&exit 1"]
