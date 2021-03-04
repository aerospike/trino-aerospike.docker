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
ARG TRINO_VERSION=351

FROM trinodb/trino:${TRINO_VERSION}

ARG CONNECTOR_VERSION=1.0.0

USER root:root
RUN \
    yum -y -q install unzip wget uuid-runtime gettext && \
    wget -q -O /tmp/aerospike.zip "https://www.aerospike.com/artifacts/enterprise/aerospike-trino/$CONNECTOR_VERSION/aerospike-trino-$CONNECTOR_VERSION.zip" && \
    unzip -q /tmp/aerospike.zip -d /tmp && \
    mv /tmp/trino-aerospike-$CONNECTOR_VERSION /usr/lib/trino/plugin/aerospike && \
    chown -R trino:trino /usr/lib/trino/plugin/aerospike

COPY --chown=trino:trino docker/etc /usr/lib/trino/etc
COPY template setup.sh /tmp/

RUN chmod 0777 /tmp/setup.sh

USER trino:trino

CMD ["/tmp/setup.sh"]
