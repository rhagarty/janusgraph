#
# NOTE: THIS FILE IS GENERATED VIA "update.sh"
# DO NOT EDIT IT DIRECTLY; CHANGES WILL BE OVERWRITTEN.
#
# Copyright 2019 JanusGraph Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM debian:buster-slim as builder

ARG JANUS_VERSION=0.5.3
ARG YQ_VERSION=3.4.1

ENV JANUS_VERSION=${JANUS_VERSION} \
    JANUS_HOME=/opt/janusgraph

WORKDIR /opt

RUN apt update -y && apt install -y gpg unzip curl && \
    curl -fSL https://github.com/JanusGraph/janusgraph/releases/download/v${JANUS_VERSION}/janusgraph-${JANUS_VERSION}.zip -o janusgraph.zip && \
    curl -fSL https://github.com/JanusGraph/janusgraph/releases/download/v${JANUS_VERSION}/janusgraph-${JANUS_VERSION}.zip.asc -o janusgraph.zip.asc && \
    curl -fSL https://github.com/JanusGraph/janusgraph/releases/download/v${JANUS_VERSION}/KEYS -o KEYS && \
    curl -fSL https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 -o yq && \
    gpg --import KEYS && \
    gpg --batch --verify janusgraph.zip.asc janusgraph.zip && \
    unzip janusgraph.zip && \
    mv janusgraph-${JANUS_VERSION} /opt/janusgraph && \
    rm -rf ${JANUS_HOME}/elasticsearch && \
    rm -rf ${JANUS_HOME}/javadocs && \
    rm -rf ${JANUS_HOME}/log && \
    rm -rf ${JANUS_HOME}/examples

COPY conf/janusgraph-berkeleyje-lucene-server.properties conf/log4j-server.properties ${JANUS_HOME}/conf/gremlin-server/
COPY conf/janusgraph-cql-server.properties conf/log4j-server.properties ${JANUS_HOME}/conf/gremlin-server/
COPY scripts/remote-connect.groovy ${JANUS_HOME}/scripts/
# COPY conf/gremlin-server.yaml ${JANUS_HOME}/conf/gremlin-server/

FROM openjdk:8-jre-slim-buster

RUN apt update -y && apt install -y gpg unzip curl nano

ARG CREATED=test
ARG REVISION=test
ARG JANUS_VERSION=0.5.3

ENV JANUS_VERSION=${JANUS_VERSION} \
    JANUS_HOME=/opt/janusgraph \
    JANUS_CONFIG_DIR=/etc/opt/janusgraph \
    JANUS_DATA_DIR=/var/lib/janusgraph \
    JANUS_SERVER_TIMEOUT=30 \
    JANUS_STORAGE_TIMEOUT=60 \
    # JANUS_PROPS_TEMPLATE=berkeleyje-lucene \
    JANUS_PROPS_TEMPLATE=cql \
    JANUS_INITDB_DIR=/docker-entrypoint-initdb.d \
    janusgraph.index.search.directory=/var/lib/janusgraph/index \
    janusgraph.storage.directory=/var/lib/janusgraph/data \
    gremlinserver.graphs.graph=/etc/opt/janusgraph/janusgraph.properties \
    gremlinserver.threadPoolWorker=1 \
    gremlinserver.gremlinPool=8 \
    gremlinserver.host=0 \
    gremlinserver.channelizer=org.apache.tinkerpop.gremlin.server.channel.WsAndHttpChannelizer

RUN groupadd -r janusgraph --gid=999 && \
    useradd -r -g janusgraph --uid=999 -d ${JANUS_DATA_DIR} janusgraph && \
    apt-get update -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends krb5-user && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/janusgraph/ /opt/janusgraph/
COPY --from=builder /opt/yq /usr/bin/yq
COPY docker-entrypoint.sh /usr/local/bin/
COPY load-initdb.sh /usr/local/bin/

RUN chmod 755 /usr/local/bin/docker-entrypoint.sh && \
    chmod 755 /usr/local/bin/load-initdb.sh && \
    chmod 755 /usr/bin/yq && \
    mkdir -p ${JANUS_INITDB_DIR} ${JANUS_CONFIG_DIR} ${JANUS_DATA_DIR} && \
    # chown -R janusgraph:0 ${JANUS_HOME} ${JANUS_INITDB_DIR} ${JANUS_CONFIG_DIR} ${JANUS_DATA_DIR}
    chgrp -R 0 ${JANUS_HOME} ${JANUS_INITDB_DIR} ${JANUS_CONFIG_DIR} ${JANUS_DATA_DIR} && \
    chmod -R g=u ${JANUS_HOME} ${JANUS_INITDB_DIR} ${JANUS_CONFIG_DIR} ${JANUS_DATA_DIR}

RUN chmod u+x /opt/janusgraph/bin/gremlin.sh
RUN chmod u+x /opt/janusgraph/conf/remote.yaml
