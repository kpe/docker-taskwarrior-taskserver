#
# gcsfuse builder
#
FROM golang:1.18.4-alpine as gcsfuse
ARG GCSFUSE_VERSION=0.41.4
ENV GO111MODULE=off
RUN \
 apk --update --no-cache add git fuse fuse-dev make g++ linux-headers \
 && go get -d github.com/googlecloudplatform/gcsfuse \
 && go install github.com/googlecloudplatform/gcsfuse/tools/build_gcsfuse \
 && build_gcsfuse ${GOPATH}/src/github.com/googlecloudplatform/gcsfuse /tmp ${GCSFUSE_VERSION}
RUN \
 mkdir /tmp/work \
 && wget https://bindfs.org/downloads/bindfs-1.17.0.tar.gz -O- | tar xzv -C /tmp/work \
 && cd /tmp/work/bindfs-1.17.0 \
 && ./configure && make install

#
# taskwarrior's taskserver builder
#
FROM alpine as builder

ARG VERSION=1.2.0
RUN apk update \
 && apk add git curl make cmake g++ gnutls-dev util-linux-dev \
 && curl -sL https://github.com/GothenburgBitFactory/taskserver/archive/refs/tags/s${VERSION}.tar.gz | tar xzv -C /tmp \
 && cd /tmp/taskserver-s${VERSION} \
 && echo -e "\n#include<limits.h>\n" >> src/Directory.h \
 && cmake . \
 && make DESTDIR=/dist install \
 && cp -R pki /dist/pki

#
# taskserver image
#
FROM alpine

RUN apk add --update --no-cache bash ca-certificates fuse gnutls gnutls-utils libuuid libstdc++

COPY --from=gcsfuse /usr/local/bin/bindfs   /usr/bin/bindfs
COPY --from=gcsfuse /tmp/bin/gcsfuse        /usr/bin
COPY --from=gcsfuse /tmp/sbin/mount.gcsfuse /usr/sbin
COPY --from=builder /dist/usr/local /usr/local
COPY --from=builder /dist/pki /pki
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN ln -s /usr/sbin/mount.gcsfuse /usr/sbin/mount.fuse.gcsfuse
RUN adduser -S -u 1000 taskd
RUN mkdir -p /data /gcs && chown -R taskd /data /pki /gcs

#
# provide GCS_BUCKET name
#
ENV GCS_BUCKET=my-taskwarrior-bucket
ENV GCS_TASKS_DIR=tasks
ENV FQDN=localhost
ENV GCS_FUSE_OPTS=

RUN echo -e "\nuser_allow_other\n" > /etc/fuse.conf

USER taskd
# ENV GCS_FUSE_OPTS=-debug_gcs, --debug_fuse, --debug_http, --debug_fs, --debug_mutex --log-file=
#                   --key_file=


ENV TASKDATA=/data
ENTRYPOINT bash -c "gcsfuse -o allow_other $GCS_FUSE_OPTS ${GCS_BUCKET} /gcs && mkdir -p /gcs/${GCS_TASKS_DIR} && bindfs /gcs/${GCS_TASKS_DIR} ${TASKDATA} && /docker-entrypoint.sh"
