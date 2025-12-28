#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
ARG TRINO_VERSION=391

FROM trinodb/trino:${TRINO_VERSION}

ARG CONNECTOR_VERSION=4.3.0-391

USER root:root
RUN \
    apt-get update && \
    apt-get -y -q install unzip ca-certificates wget uuid-runtime gettext && \
    export BASE_VERSION=$(echo $CONNECTOR_VERSION | cut -d '-' -f 1) && \
    wget -q -O /tmp/aerospike.zip "https://www.aerospike.com/artifacts/enterprise/aerospike-trino/$BASE_VERSION/aerospike-trino-$CONNECTOR_VERSION.zip" && \
    unzip -q /tmp/aerospike.zip -d /tmp && \
    mv /tmp/trino-aerospike-$CONNECTOR_VERSION /usr/lib/trino/plugin/aerospike && \
    chown -R trino:trino /usr/lib/trino/plugin/aerospike

# OpenShift runs containers with arbitrary UIDs in the root group (GID 0)
# Using trino:root ownership and 770 permissions for OpenShift compatibility
COPY --chown=trino:root --chmod=770 docker/etc /etc/trino
COPY template setup.sh /tmp/

RUN chmod 0777 /tmp/setup.sh

USER trino:trino

CMD ["/tmp/setup.sh"]
