# Dockerfile for Pega 8 Platform

# Base image to extend from
ARG BASE_TOMCAT_IMAGE
ARG DETEMPLATIZE_IMAGE_VERSION=latest

FROM pegasystems/detemplatize:$DETEMPLATIZE_IMAGE_VERSION as detemplatize

FROM $BASE_TOMCAT_IMAGE as release

ARG VERSION
ARG DETEMPLATIZE_IMAGE_VERSION=latest
ARG TOMCAT_MAJOR_VERSION=9

LABEL vendor="Pegasystems Inc." \
      name="Pega Tomcat Node" \
      version=${VERSION:-CUSTOM_BUILD}

# Creating new user and group

RUN groupadd -g 9001 pegauser && \
    useradd -r -u 9001 -g pegauser pegauser


ENV PEGA_DOCKER_VERSION=${VERSION:-CUSTOM_BUILD}
ENV DETEMPLATIZE_IMAGE_VERSION=${DETEMPLATIZE_IMAGE_VERSION}
# Copy detemplatize to base image bin directory
COPY --from=detemplatize /bin/detemplatize /bin/detemplatize
COPY --from=detemplatize /opt/pega/rasp /opt/pega/rasp/

COPY hashes/ /hashes/
COPY keys/ /keys/

# Create directory for storing heapdump
RUN mkdir -p /heapdumps  && \
    chgrp -R 0 /heapdumps && \
    chmod 770 /heapdumps && \
    chown -R pegauser /heapdumps

# Create directory for storing diagnosticfiles
RUN mkdir -p /diagnosticfiles  && \
    chgrp -R 0 /diagnosticfiles && \
    chmod 770 /diagnosticfiles && \
    chown -R pegauser /diagnosticfiles

# Create common directory for mounting configuration and libraries
RUN mkdir -p /opt/pega && \
    chgrp -R 0 /opt/pega && \
    chmod -R g+rw /opt/pega && \
    chown -R pegauser /opt/pega

# Create directory for filesystem repository
RUN  mkdir -p /opt/pega/filerepo  && \
     chgrp -R 0 /opt/pega/filerepo && \
     chmod -R g+rw /opt/pega/filerepo && \
     chown -R pegauser /opt/pega/filerepo

# Create directory for mounting configuration files
RUN  mkdir -p /opt/pega/config  && \
     chgrp -R 0 /opt/pega/config && \
     chmod -R g+rw /opt/pega/config && \
     chown -R pegauser /opt/pega/config

# Create directory for mounting kerberos files(krb5.conf)
RUN  mkdir -p /opt/pega/kerberos  && \
     chgrp -R 0 /opt/pega/kerberos && \
     chmod -R g+rw /opt/pega/kerberos && \
     chown -R pegauser /opt/pega/kerberos

# Create directory for mounting libraries
RUN  mkdir -p /opt/pega/lib  && \
     chgrp -R 0 /opt/pega/lib && \
     chmod -R g+rw /opt/pega/lib && \
     chown -R pegauser /opt/pega/lib

# Create directory for mounting secrets
RUN  mkdir -p /opt/pega/secrets && \
     chgrp -R 0 /opt/pega && \
     chmod -R g+rw /opt/pega/secrets && \
     chown -R pegauser /opt/pega/secrets


# Create directory for extracted prweb.war
RUN mkdir -p /opt/pega/prweb && \
    chgrp -R 0 /opt/pega/prweb && \
    chmod -R g+rw /opt/pega/prweb && \
    chown -R pegauser /opt/pega/prweb

# Create directory for extra stream volume
RUN mkdir -p /opt/pega/streamvol && \
    chgrp -R 0 /opt/pega/streamvol && \
    chmod -R g+rw /opt/pega/streamvol && \
    chown -R pegauser /opt/pega/streamvol

# Create directory for decompressed configurations
RUN  mkdir -p /opt/pega/decompressedconfig  && \
     chgrp -R 0 /opt/pega/decompressedconfig && \
     chmod -R g+rw /opt/pega/decompressedconfig && \
     chown -R pegauser /opt/pega/decompressedconfig

# Create directory for deployment utilities
RUN  mkdir -p /opt/pega/utility && \
     chgrp -R 0 /opt/pega/utility && \
     chmod g+rw /opt/pega/utility && \
     chown -R pegauser /opt/pega/utility

COPY versionchecker/build/libs/versionchecker-1.0.jar /opt/pega/utility/

# Set up an empty JDBC URL which will, if set to a non-empty value, be used in preference
# to the "constructed" JDBC URL
ENV JDBC_URL='' \
    DB_USERNAME='' \
    DB_PASSWORD='' \
    JDBC_CLASS=''

# Load a default PostgreSQL driver on startup
ENV JDBC_DRIVER_URI=''

# Provide variables for the JDBC connection string
ENV JDBC_MAX_ACTIVE=75 \
    JDBC_MIN_IDLE=3 \
    JDBC_MAX_IDLE=25 \
    JDBC_MAX_WAIT=10000 \
    JDBC_INITIAL_SIZE=0 \
    JDBC_CONNECTION_PROPERTIES='' \
    JDBC_TIMEOUT_PROPERTIES='' \
    JDBC_TIMEOUT_PROPERTIES_RW='' \
    JDBC_TIMEOUT_PROPERTIES_RO='' \
    JDBC_TIME_BETWEEN_EVICTIONS=30000 \
    JDBC_MIN_EVICTABLE_IDLE_TIME=60000

# Provide variables for the name of the rules, data, and customerdata schemas
ENV RULES_SCHEMA=rules \
    DATA_SCHEMA=data \
    CUSTOMERDATA_SCHEMA=

#Tomcat user environment variables for pega diagnostic user
ENV PEGA_DIAGNOSTIC_USER='' \
    PEGA_DIAGNOSTIC_PASSWORD=''

# Parameterize variables to customize the tomcat runtime
ENV JAVA_OPTS="" \
    MAX_HEAP="4096m" \
    INITIAL_HEAP="2048m" \
    INDEX_DIRECTORY="NONE" \
    HEAP_DUMP_PATH="/heapdumps" \
    NODE_TYPE="" \
    NODE_TIER="" \
    NODE_SETTINGS="" \
    PEGA_APP_CONTEXT_PATH=prweb \
    PEGA_DEPLOYMENT_DIR=${CATALINA_HOME}/webapps/prweb

# Configure Remote JMX support and bind to port 9001
ENV JMX_PORT=9001 \
    USE_CUSTOM_JMX_CONNECTION=

# Configure Cassandra.
ENV CASSANDRA_CLUSTER=false \
    CASSANDRA_NODES= \
    CASSANDRA_PORT=9042 \
    CASSANDRA_USERNAME= \
    CASSANDRA_PASSWORD= \
    CASSANDRA_CLIENT_ENCRYPTION=false \
    CASSANDRA_CLIENT_AUTH=false \
    CASSANDRA_CLIENT_ENCRYPTION_STORE_TYPE= \
    CASSANDRA_TRUSTSTORE= \
    CASSANDRA_TRUSTSTORE_PASSWORD= \
    CASSANDRA_KEYSTORE= \
    CASSANDRA_KEYSTORE_PASSWORD= \
    CASSANDRA_ASYNC_PROCESSING_ENABLED=false \
    CASSANDRA_KEYSPACES_PREFIX= \
    CASSANDRA_EXTENDED_TOKEN_AWARE_POLICY=false \
    CASSANDRA_LATENCY_AWARE_POLICY=false \
    CASSANDRA_CUSTOM_RETRY_POLICY=false \
    CASSANDRA_CUSTOM_RETRY_POLICY_ENABLED=false \
    CASSANDRA_CUSTOM_RETRY_POLICY_COUNT= \
    CASSANDRA_SPECULATIVE_EXECUTION_POLICY=false \
    CASSANDRA_SPECULATIVE_EXECUTION_POLICY_ENABLED=false \
    CASSANDRA_SPECULATIVE_EXECUTION_DELAY= \
    CASSANDRA_SPECULATIVE_EXECUTION_MAX_EXECUTIONS= \
    CASSANDRA_JMX_METRICS_ENABLED=true \
    CASSANDRA_CSV_METRICS_ENABLED=false \
    CASSANDRA_LOG_METRICS_ENABLED=false

# Configure search nodes. Empty string falls back to search being done on the nodes themselves.
ENV PEGA_SEARCH_URL=

# Configure hazelcast. By default, hazelcast runs in embedded mode.
ENV HZ_CLIENT_MODE=false \
    HZ_VERSION=v4 \
    HZ_DISCOVERY_K8S= \
    HZ_CLUSTER_NAME= \
    HZ_SERVER_HOSTNAME= \
    HZ_CS_AUTH_USERNAME= \
    HZ_CS_AUTH_PASSWORD= \
    HZ_SSL_ENABLED= \
    HZ_SSL_PROTOCOL= \
    HZ_SSL_CUSTOM_CLASS= \
    HZ_SSL_KEY_STORE_NAME= \
    HZ_SSL_KEYSTORE_PASSWORD= \
    HZ_SSL_ALGO= \
    HZ_SSL_TRUST_STORE_NAME= \
    HZ_SSL_TRUSTSTORE_PASSWORD= \
    HIGHLY_SECURE_CRYPTO_MODE_ENABLED=

# Configure custom artifactory authentication details if it is secured with Basic or APIKey Authentication which is used for downloading JDBC driver.
ENV CUSTOM_ARTIFACTORY_USERNAME= \
    CUSTOM_ARTIFACTORY_PASSWORD= \
    CUSTOM_ARTIFACTORY_APIKEY_HEADER= \
    CUSTOM_ARTIFACTORY_APIKEY= \
    ENABLE_CUSTOM_ARTIFACTORY_SSL_VERIFICATION=false

#Set up volume for persistent Kafka data storage
RUN  mkdir -p /opt/pega/kafkadata && \
     chgrp -R 0 /opt/pega/kafkadata && \
     chmod -R g+rw /opt/pega/kafkadata && \
     chown -R pegauser /opt/pega/kafkadata

# Fetches the packages and latest versions.
RUN apt-get update && \
    apt-get install -y gpg && \
    rm -rf /var/lib/apt/lists/*

# download necessary jars
RUN mkdir -p /opt/pega/prometheus && \
    mkdir -p /opt/pega/bcfips && \
    curl -sL -o /opt/pega/prometheus/jmx_prometheus_javaagent.jar https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.18.0/jmx_prometheus_javaagent-0.18.0.jar && \
    curl -sL -o /tmp/jmx_prometheus_javaagent-0.18.0.jar.asc https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.18.0/jmx_prometheus_javaagent-0.18.0.jar.asc && \
    gpg --import /keys/prometheus.asc && \
    gpg --verify /tmp/jmx_prometheus_javaagent-0.18.0.jar.asc /opt/pega/prometheus/jmx_prometheus_javaagent.jar && \
    rm /tmp/jmx_prometheus_javaagent-0.18.0.jar.asc && \
    # Updating Bouncy Castle jars versions below?  As these are used for FIPS 140-3 support, the versions below should
    # only be replaced with FIPS certified library versions.  See https://www.bouncycastle.org/download/bouncy-castle-java-fips/#latest --
    # paying particular attention to the "Distribution Files (JAR Format)".  The jars below correspond to BC-FJA 2.0.0.
    curl -sL -o /opt/pega/bcfips/bc-fips-2.0.0.jar https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/2.0.0/bc-fips-2.0.0.jar && \
    curl -sL -o /tmp/bc-fips-2.0.0.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/2.0.0/bc-fips-2.0.0.jar.asc && \
    curl -sL -o /opt/pega/bcfips/bctls-fips-2.0.19.jar https://repo1.maven.org/maven2/org/bouncycastle/bctls-fips/2.0.19/bctls-fips-2.0.19.jar && \
    curl -sL -o /tmp/bctls-fips-2.0.19.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bctls-fips/2.0.19/bctls-fips-2.0.19.jar.asc && \
    curl -sL -o /opt/pega/bcfips/bcpkix-fips-2.0.7.jar https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-fips/2.0.7/bcpkix-fips-2.0.7.jar && \
    curl -sL -o /tmp/bcpkix-fips-2.0.7.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bcpkix-fips/2.0.7/bcpkix-fips-2.0.7.jar.asc && \
    curl -sL -o /opt/pega/bcfips/bcutil-fips-2.0.3.jar https://repo1.maven.org/maven2/org/bouncycastle/bcutil-fips/2.0.3/bcutil-fips-2.0.3.jar && \
    curl -sL -o /tmp/bcutil-fips-2.0.3.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bcutil-fips/2.0.3/bcutil-fips-2.0.3.jar.asc && \
    curl -sL -o /opt/pega/bcfips/bcmail-fips-2.0.5.jar https://repo1.maven.org/maven2/org/bouncycastle/bcmail-fips/2.0.5/bcmail-fips-2.0.5.jar && \
    curl -sL -o /tmp/bcmail-fips-2.0.5.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bcmail-fips/2.0.5/bcmail-fips-2.0.5.jar.asc && \
    curl -sL -o /opt/pega/bcfips/bcjmail-fips-2.0.5.jar https://repo1.maven.org/maven2/org/bouncycastle/bcjmail-fips/2.0.5/bcjmail-fips-2.0.5.jar && \
    curl -sL -o /tmp/bcjmail-fips-2.0.5.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bcjmail-fips/2.0.5/bcjmail-fips-2.0.5.jar.asc && \
    curl -sL -o /opt/pega/bcfips/bcpg-fips-2.0.9.jar https://repo1.maven.org/maven2/org/bouncycastle/bcpg-fips/2.0.9/bcpg-fips-2.0.9.jar && \
    curl -sL -o /tmp/bcpg-fips-2.0.9.jar.asc https://repo1.maven.org/maven2/org/bouncycastle/bcpg-fips/2.0.9/bcpg-fips-2.0.9.jar.asc && \
    gpg --import /keys/bc_maven_public_key.asc && \
    gpg --verify /tmp/bc-fips-2.0.0.jar.asc /opt/pega/bcfips/bc-fips-2.0.0.jar && \
    rm /tmp/bc-fips-2.0.0.jar.asc && \
    gpg --verify /tmp/bctls-fips-2.0.19.jar.asc /opt/pega/bcfips/bctls-fips-2.0.19.jar && \
    rm /tmp/bctls-fips-2.0.19.jar.asc && \
    gpg --verify /tmp/bcpkix-fips-2.0.7.jar.asc /opt/pega/bcfips/bcpkix-fips-2.0.7.jar && \
    rm /tmp/bcpkix-fips-2.0.7.jar.asc  && \
    gpg --verify /tmp/bcutil-fips-2.0.3.jar.asc /opt/pega/bcfips/bcutil-fips-2.0.3.jar && \
    rm /tmp/bcutil-fips-2.0.3.jar.asc && \
    gpg --verify /tmp/bcmail-fips-2.0.5.jar.asc /opt/pega/bcfips/bcmail-fips-2.0.5.jar && \
    rm /tmp/bcmail-fips-2.0.5.jar.asc && \
    gpg --verify /tmp/bcjmail-fips-2.0.5.jar.asc /opt/pega/bcfips/bcjmail-fips-2.0.5.jar && \
    rm /tmp/bcjmail-fips-2.0.5.jar.asc && \
    gpg --verify /tmp/bcpg-fips-2.0.9.jar.asc /opt/pega/bcfips/bcpg-fips-2.0.9.jar && \
    rm /tmp/bcpg-fips-2.0.9.jar.asc && \
    chgrp -R 0 /opt/pega/prometheus && \
    chmod -R g+rw /opt/pega/prometheus && \
    chown -R pegauser /opt/pega/prometheus && \
    chmod 440 /opt/pega/prometheus/jmx_prometheus_javaagent.jar

# Should not be called when building image on Fedora based OS. Safe call with Debian based OS like Ubuntu.
RUN apt-get autoremove --purge -y gpg

# Setup dir for cert files
RUN  mkdir -p /opt/pega/certs  && \
     chgrp -R 0 /opt/pega/certs && \
     chmod -R g+rw /opt/pega/certs && \
     chown -R pegauser /opt/pega/certs

#Set up dir for certificate of custom artifactory
RUN  mkdir -p /opt/pega/artifactory/cert && \
     chgrp -R 0 /opt/pega/artifactory/cert && \
     chmod -R g+rw /opt/pega/artifactory/cert && \
     chown -R pegauser /opt/pega/artifactory/cert

# Setup dir for tlscert file
RUN  mkdir -p /opt/pega/tomcatcertsmount  && \
     chgrp -R 0 /opt/pega/tomcatcertsmount && \
     chmod -R g+rw /opt/pega/tomcatcertsmount && \
     chown -R pegauser /opt/pega/tomcatcertsmount

#give permissions and ownership to pegauser for lib/security
RUN chmod -R g+rw ${JAVA_HOME}/lib/security && \
    chown -R pegauser ${JAVA_HOME}/lib/security

# Remove existing webapps
RUN rm -rf ${CATALINA_HOME}/webapps/*

# Copy in tomcat configuration and application files
COPY tomcat-webapps ${CATALINA_HOME}/webapps/
COPY tomcat-bin ${CATALINA_HOME}/bin/
COPY tomcat-conf ${CATALINA_HOME}/conf/
COPY scripts /scripts
COPY tomcat-versioned-artifacts/${TOMCAT_MAJOR_VERSION}/root_web.xml ${CATALINA_HOME}/webapps/ROOT/WEB-INF/web.xml


# Update access of required directories to allow not running in root for openshift
RUN chmod -R g+rw ${CATALINA_HOME}/logs  && \
    chmod -R g+rw ${CATALINA_HOME}/lib  && \
    chmod -R g+rw ${CATALINA_HOME}/work  && \
    chmod -R g+rw ${CATALINA_HOME}/conf  && \
    chmod -R g+rw ${CATALINA_HOME}/bin  && \
    chmod -R g+rw ${CATALINA_HOME}/webapps && \
    chmod -R g+x /scripts && \
    chown -R pegauser /scripts && \
    chmod g+r ${CATALINA_HOME}/conf/web.xml && \
    chown -R pegauser ${CATALINA_HOME}  && \
    mkdir /search_index && \
    chmod -R g+w /search_index && \
    chown -R pegauser /search_index

#switched the user to pegauser
USER pegauser

#running in pegauser context
RUN chmod 770 /scripts/docker-entrypoint.sh

ENTRYPOINT ["/scripts/docker-entrypoint.sh"]
CMD ["run"]

# Expose required ports

# HTTP is 8080, JMX is 9001, prometheus is 9090, Hazelcast is 5701-5710, Ignite is 47100, REST for Kafka is 7003
EXPOSE 8080 9001 9090 5701-5710 47100 7003

# Used by Docker if this image is used outside of a Kubernetes context.
# Kubernetes ignores this check and uses the liveness/readiness probes instead.
HEALTHCHECK --interval=5m --timeout=3s CMD jcmd 0 VM.uptime || exit 1

# *****Target for test environment*****

FROM release as qualitytest
USER root
RUN mkdir /tests && \
    chown -R pegauser /tests
COPY tests /tests
RUN chmod -R 777 /tests
USER pegauser
FROM release
