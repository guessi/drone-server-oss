ARG DRONE_VERSION_TAG=v1.7.0

FROM golang:1.13-alpine as builder

RUN apk add -U --no-cache build-base ca-certificates git
WORKDIR ${GOPATH}/src/github.com/drone/drone
RUN git clone https://github.com/drone/drone.git . \
 && git checkout ${DRONE_VERSION_TAG}

RUN GOOS=linux GOARCH=amd64 go build \
      -ldflags '-extldflags "-static"' -tags 'oss nolimit' \
      -o /opt/drone-server ./cmd/drone-server

#
# the following content is reference from the upstream repo:
# - https://github.com/drone/drone/tree/master/docker
#
# the only difference is the binary of `drone-server`
#
FROM alpine:3.11

RUN [ ! -e /etc/nsswitch.conf ] && echo 'hosts: files dns' > /etc/nsswitch.conf

ENV GODEBUG netdns=go \
    XDG_CACHE_HOME=/data \
    DRONE_DATABASE_DRIVER=sqlite3 \
    DRONE_DATABASE_DATASOURCE=/data/database.sqlite \
    DRONE_RUNNER_OS=linux \
    DRONE_RUNNER_ARCH=amd64 \
    DRONE_SERVER_PORT=:80 \
    DRONE_SERVER_HOST=localhost \
    DRONE_DATADOG_ENABLED=true \
    DRONE_DATADOG_ENDPOINT=https://stats.drone.ci/api/v1/series

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /opt/drone-server /bin/

EXPOSE 80 443

VOLUME /data

ENTRYPOINT ["/bin/drone-server"]
