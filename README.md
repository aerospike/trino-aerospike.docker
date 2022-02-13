# trino-aerospike-docker
[Trino](https://trino.io/) with the [Aeropsike connector](https://www.aerospike.com/enterprise/download/connectors/aerospike-trino) Docker Image.

## Quickstart
Build a Docker image.
Make sure to adjust the server and the connector configuration in the `docker/etc` folder.
You can pass the `TRINO_VERSION` and the `CONNECTOR_VERSION` [arguments](https://docs.docker.com/engine/reference/builder/#arg) with the docker build command.
```bash
docker build . -t trino-aerospike
```

To launch it, execute the following:
```bash
docker run --rm -p 8080:8080 --name trino-aerospike trino-aerospike
```

*[optional]* If you plan to set up TLS between Aerospike and Trino, copy the TLS related files over to the Docker image by updating the Dockerfile. See the environment variables list below for more information on the TLS related properties.
Here’s an example of the line added to the Dockerfile to copy files from the local `docker/etc` directory over to the Docker image: `COPY --chown=trino:trino docker/etc /etc/trino`.

Below is the list of environment variables you can specify to configure the Trino server and the Aerospike connector using the [-e](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file) option.

| Variable | Description | Default Value |
| -------- | ----------- | ------------- |
| AS_HOSTLIST | Aerospike host list, a comma separated list of potential hosts to seed the cluster. |  |
| TABLE_DESC_DIR | Path of the directory containing table description files.<sup>[1](#schema-folder)</sup> | /etc/trino/aerospike |
| SPLIT_NUMBER | Number of Trino splits. See Parallelism section for more information. | 4 |
| CACHE_TTL_MS | Number of milliseconds to keep the inferred schema cached. | 1800000 |
| STRICT_SCHEMAS | Use a strict schema.<sup>[2](#strict-schema)</sup> | false |
| DEFAULT_SET_NAME | Table name for the default set. This is used when your namespace has a null set or no sets. | __default |
| RECORD_KEY_NAME | Column name for the record's primary key. Use this in the WHERE clause for queries involving primary key (PK) comparisons. | __key |
| RECORD_KEY_HIDDEN | If set to false, the primary key column will be available in the result set. | true |
| INSERT_REQUIRE_KEY | Require the primary key on INSERT queries. Although we recommend that you provide a primary key, you can choose not to by setting this property to false, in which case a UUID is generated for the PK. You can view it by setting aerospike.record-key-hidden to false for future queries. | true |
| CASE_INSENSITIVE_IDENTIFIERS | Enables case-insensitive name resolution. Has minor performance penalty when enabled. | false |
| AS_TLS_ENABLED | Enable secure TLS connection. | false |
| AS_TLS_STORE_TYPE | The type of the keystore. | jks |
| AS_TLS_KEYSTORE_PATH | Keystore file path. | |
| AS_TLS_KEYSTORE_PASSWORD | Keystore password. | |
| AS_TLS_KEY_PASSWORD | Key password. | |
| AS_TLS_TRUSTSTORE_PATH | Truststore file path. | |
| AS_TLS_TRUSTSTORE_PASSWORD | Truststore password. | |
| AS_TLS_FOR_LOGIN_ONLY | Use TLS connection only for login authentication. | false |
| TRINO_DISCOVERY_URI | The URI to the Discovery server. This should be the URI of the Trino coordinator. Replace the default value to match the host and port of the Trino coordinator. This URI must not end in a slash. | http://localhost:8080 |
| TRINO_NODE_TYPE | The Trino node type, can be either `coordinator` or `worker`. | `single-node` |

<sup name="schema-folder">1</sup> To set the required schema configuration, bind-mount the table description folder on `docker run`.
```
-v "$(pwd)"/docker/etc/aerospike:/etc/trino/aerospike
```

Wait for the following message log line:
```
INFO	main	io.trino.server.Server	======== SERVER STARTED ========
```

The Trino server is now running on `localhost:8080` (the default port).

## Multi-Node Trino Cluster
To run a Trino cluster of one coordinator and one worker:
* Start a Trino coordinator.
```
docker run --rm -p 8080:8080 -e TRINO_NODE_TYPE=coordinator -e AS_HOSTLIST=docker.for.mac.host.internal:3000 --name trino-aerospike-coordinator trino-aerospike
```
* Start a Trino worker<sup>[1](#worker)</sup>, specify the `TRINO_DISCOVERY_URI` to be the URI of the Trino coordinator.
```
docker run --rm -e TRINO_NODE_TYPE=worker -e AS_HOSTLIST=docker.for.mac.host.internal:3000 -e TRINO_DISCOVERY_URI=http://172.17.0.3:8080 --name trino-aerospike-worker trino-aerospike
```
<sup name="worker">1</sup> Run this command number of times with different container names to add more workers.

## Aerospike Connector Configuration Properties
The following configuration properties are available:

| Property name | Description | Default value |
| --- | --- | --- |
| aerospike.hostname | Aerospike hostname. Hostname will be ignored if hostlist is specified. | localhost |
| aerospike.port | Aerospike port. | 3000 |
| aerospike.hostlist | Aerospike host list, a comma separated list of potential hosts to seed the cluster. | null |
| aerospike.table-desc-dir | Path of the directory containing table description files. | etc/aerospike |
| aerospike.split-number | Number of Trino splits. See Parallelism section for more information.| 16 |
| aerospike.cache-ttl-ms | Schema inference cache TTL in milliseconds. | 1800000 |
| aerospike.default-set-name | Table name for the default set. | __default |
| aerospike.strict-schemas | Use a strict schema.<sup>[1](#strict-schema)</sup> | false |
| aerospike.record-key-name | Column name for the record's primary key. | __key |
| aerospike.record-key-hidden | If set to false, the primary key column will be available in the result set. | true |
| aerospike.enable-statistics | Generate [statistics](https://trino.io/docs/current/optimizer/statistics.html) for [Cost-Based Optimization (CBO)](https://trino.io/docs/current/optimizer.html). Currently, the Trino connector only supports the row count. Please make sure to turn on CBO in Trino. | false |
| aerospike.insert-require-key | Require the primary key on INSERT queries. Although we recommend that you provide a primary key, you can choose not to by setting this property to false, in which case a UUID is generated for the PK. You can view it by setting aerospike.record-key-hidden to false for future queries. | true |
| aerospike.case-insensitive-identifiers | Enables case-insensitive name resolution. Has minor performance penalty when enabled. | false |

<sup name="strict-schema">1</sup> Since Trino is a SQL engine, it assumes that the underlying data store (Aerospike in this case) follows a strict schema for all the records within a table. However, Aerospike is a No-SQL DB and is schemaless. Hence a single bin (mapped to a Trino column) within a set (mapped to a Trino table) could technically hold values of multiple [Aerospike supported types](https://www.aerospike.com/docs/guide/data-types.html). The Trino connector reconciles this incompatibility with help of certain rules. Please choose the configuration that suits your use case. The strict configuration (aerospike.strict-schemas = true) could be used when you have modeled your data in Aerospike to adhere to a strict schema i.e. each record within the set has the same structure.
1. **aerospike.strict-schemas = false (default)**  
If none of the column types in the user-specified schema match the bin types of a record in Aerospike, a record with NULLs is returned in the result set.  
If the above mismatch is limited to fewer columns in the user-specified schema then NULL would be returned for those columns in the result set. **Note: there is no way to tell apart a NULL due to missing value in the original data set and the NULL due to mismatch, at this point. Hence, the user would have to treat all NULLs as missing values.** The columns that are not a part of the schema will be automatically filtered out in the result set by the connector.
2. **aerospike.strict-schemas = true**  
If a mismatch between the user-specified schema and the schema of a record in Aerospike is detected at the bin/column level, your query will error out.

### Aerospike client policy configuration properties

| Property name | Description | Default value |
| --- | --- | --- |
| aerospike.clientpolicy.user | User authentication to cluster. | null |
| aerospike.clientpolicy.password | Password authentication to cluster. | null |
| aerospike.clientpolicy.clusterName | Expected cluster name. | null |
| aerospike.clientpolicy.authMode | Authentication mode to use when user/password is defined (INTERNAL, EXTERNAL, EXTERNAL_INSECURE)<sup>[1](#auth-mode)</sup>. | INTERNAL |
| aerospike.clientpolicy.connPoolsPerNode | Number of synchronous connection pools used for each node. | 1 |
| aerospike.clientpolicy.maxConnsPerNode | Maximum number of synchronous connections allowed per server node. | 300 |
| aerospike.clientpolicy.maxSocketIdle | Maximum socket idle in seconds. Socket connection pools will discard sockets that have been idle longer than the maximum. | 55 |
| aerospike.clientpolicy.tendInterval | Interval in milliseconds between cluster tends by maintenance thread. | 1000 |
| aerospike.clientpolicy.timeout | Initial host connection timeout in milliseconds. The timeout when opening a connection to the server host for the first time. | 1000 |
| aerospike.clientpolicy.failIfNotConnected | Throw exception if all seed connections fail on cluster instantiation. | true |
| aerospike.clientpolicy.sharedThreadPool | Is threadPool shared between other client instances or classes. If threadPool is not shared (default), threadPool will be shutdown when the client instance is closed. | false |
| aerospike.clientpolicy.useServicesAlternate | Should use "services-alternate" instead of "services" in info request during cluster tending. | false |

<sup name="auth-mode">1</sup> **INTERNAL** - Use internal authentication only. Hashed password is stored on the server. Do not send clear password. This is the default.  
**EXTERNAL** - Use external authentication (like LDAP). Specific external authentication is configured on server. If TLS defined, send clear password on node login via TLS. Throw exception if TLS is not defined.  
**EXTERNAL_INSECURE** - Use external authentication (like LDAP). Specific external authentication is configured on server. Send clear password on node login whether or not TLS is defined. This mode should only be used for testing purposes because it is not secure authentication.

### Aerospike scan policy configuration properties

| Property name | Description | Default value |
| --- | --- | --- |
| aerospike.scanpolicy.recordsPerSecond | Limit returned records per second (rps) rate for each server. Do not apply rps limit if recordsPerSecond is zero. | 0 |
| aerospike.scanpolicy.maxConcurrentNodes | Maximum number of concurrent requests to server nodes at any point in time. Issue requests to all server nodes in parallel if maxConcurrentNodes is zero. | 0 |

## Security

Trino supports [Authentication](https://trino.io/docs/current/security.html) of users that connect to it via various clients such as Jupyter notebook, BI tools, and CLI.
The below section describes how you can additionally set up authentication and authorization to make sure only authorized users can read and/or write to Aerospike DB.

### Session properties
You can change the default value of a session property by using [SET SESSION](https://trino.io/docs/current/sql/set-session.html).
They are set separately for each catalog by prefixing them with the catalog name. There is no sharing of properties across catalogs, even if the catalogs use the same connector.

`SET SESSION aerospike.client_policy_user = 'admin';`

| Property name | Description | Default value |
| --- | --- | --- |
| client_policy_user | User authentication to cluster. | `aerospike.clientpolicy.user` configuration value |
| client_policy_password | Password authentication to cluster. | `aerospike.clientpolicy.password` configuration value |

If you are using [internal](#auth-mode) authentication, make sure that the user and the password are provisioned in the Aerospike DB along with the associated roles.
See [Configuring access control](https://aerospike.com/docs/operations/configure/security/access-control/index.html) for more information.

### Aerospike client policy TLS configuration properties

| Property name | Description | Default value |
| --- | --- | --- |
| aerospike.clientpolicy.tls.enabled | Enable secure TLS connection. | false |
| aerospike.clientpolicy.tls.storeType | The type of the keystore. | jks |
| aerospike.clientpolicy.tls.keystorePath | Keystore file path. | null |
| aerospike.clientpolicy.tls.keystorePassword | Keystore password. | null |
| aerospike.clientpolicy.tls.keyPassword | Key password. | null |
| aerospike.clientpolicy.tls.truststorePath | Truststore file path. | null |
| aerospike.clientpolicy.tls.truststorePassword | Truststore password. | null |
| aerospike.clientpolicy.tls.forLoginOnly | Use TLS connection only for login authentication. | false |
| aerospike.clientpolicy.tls.allowedCiphers | A comma separated list of allowable TLS ciphers to use for the secure connection. | Default ciphers defined by JVM |
| aerospike.clientpolicy.tls.allowedProtocols | A comma separated list of allowable TLS protocols to use for the secure connection. | TLSv1.2 |

## Parallelism
Aerospike connector supports up to `Integer.MAX_VALUE` splits (i.e. 2^31-1 Trino splits) for parallel partition scans by Trino workers. 
Splits is the unit of parallelism in Trino. Hence, we can support up to ~2B Trino worker threads (configurable by setting task.max-worker-threads in Trino). 
Setting this value too high may cause a drop in performance due to context switching.

## Data mapping
### Data Sources

| Aerospike | Trino |
| --- | --- |
| cluster | catalog |
| namespace | schema |
| set | table |
| record | row |
| bin | column |

### Variable types

| Aerospike | Trino |
| --- | --- |
| byte[] | VARBINARY |
| String | VARCHAR |
| Integer | INTEGER |
| Long | BIGINT |
| Double | DOUBLE |
| Float | DOUBLE |
| Boolean | BOOLEAN |
| Byte | TINYINT |
| Value.ListValue | [JSON](https://trino.io/docs/current/functions/json.html) |
| Value.MapValue | [JSON](https://trino.io/docs/current/functions/json.html) |
| Value.GeoJSONValue | [JSON](https://trino.io/docs/current/functions/json.html) |
| Value.HLLValue | HYPER_LOG_LOG |
