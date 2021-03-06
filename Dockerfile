# Build envyaml for current system.
FROM golang:1.8 AS prep_env2yaml

ADD env2yaml/env2yaml.go .

RUN go get gopkg.in/yaml.v2 && \
    mkdir env2yaml && \
    mv env2yaml.go env2yaml/ && \
    cd env2yaml/ && \
    go build

# This Dockerfile was generated from templates/Dockerfile.j2
FROM centos:7

# Install Java and the "which" command, which is needed by Logstash's shell
# scripts.
# Minimal distributions also require findutils tar gzip (procps for integration tests)
RUN yum update -y && yum install -y procps findutils tar gzip which shadow-utils && \
    yum clean all

# Provide a non-root user to run the process.
RUN groupadd --gid 1000 logstash && \
    adduser --uid 1000 --gid 1000 \
      --home-dir /usr/share/logstash --no-create-home \
      logstash

# Add Logstash itself.
RUN curl -Lo - https://artifacts.elastic.co/downloads/logstash/logstash-7.10.1-linux-aarch64.tar.gz | \
    tar zxf - -C /usr/share && \
    mv /usr/share/logstash-7.10.1 /usr/share/logstash && \
    chown --recursive logstash:logstash /usr/share/logstash/ && \
    chown -R logstash:root /usr/share/logstash && \
    chmod -R g=u /usr/share/logstash && \
    mkdir /licenses/ && \
    mv /usr/share/logstash/NOTICE.TXT /licenses/NOTICE.TXT && \
    mv /usr/share/logstash/LICENSE.txt /licenses/LICENSE.txt && \
    find /usr/share/logstash -type d -exec chmod g+s {} \; && \
    ln -s /usr/share/logstash /opt/logstash

# RUN curl -Lo - https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_aarch64_linux_hotspot_11.0.8_10.tar.gz | \
#    tar zxvf - -C /temp
#RUN rm -rf /usr/share/logstash/jdk
#RUN mkdir /usr/share/logstash/jdk
#RUN curl -L -O https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.8%2B10/OpenJDK11U-jdk_aarch64_linux_hotspot_11.0.8_10.tar.gz
#RUN tar -xvf OpenJDK11U-jdk_aarch64_linux_hotspot_11.0.8_10.tar.gz
#RUN mv ./jdk-11.*/* /usr/share/logstash/jdk
#RUN rm -rf jdk-11.*

WORKDIR /usr/share/logstash

ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/logstash/bin:$PATH

# Provide a minimal configuration, so that simple invocations will provide
# a good experience.
ADD config/pipelines.yml config/pipelines.yml
ADD config/logstash-full.yml config/logstash.yml
ADD config/log4j2.properties config/
ADD pipeline/default.conf pipeline/logstash.conf
RUN chown --recursive logstash:root config/ pipeline/

# Ensure Logstash gets the correct locale by default.
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Place the startup wrapper script.
ADD bin/docker-entrypoint /usr/local/bin/
RUN chmod 0755 /usr/local/bin/docker-entrypoint

USER 1000

# ADD env2yaml/env2yaml /usr/local/bin/
COPY --from=prep_env2yaml --chown=logstash:root /go/env2yaml/env2yaml /usr/local/bin/

EXPOSE 9600 5044


LABEL  org.label-schema.schema-version="1.0" \
  org.label-schema.vendor="Elastic" \
  org.opencontainers.image.vendor="Elastic" \
  org.label-schema.name="logstash" \
  org.opencontainers.image.title="logstash" \
  org.label-schema.version="7.10.1" \
  org.opencontainers.image.version="7.10.1" \
  org.label-schema.url="https://www.elastic.co/products/logstash" \
  org.label-schema.vcs-url="https://github.com/elastic/logstash" \
  org.label-schema.license="Elastic License" \
  org.opencontainers.image.licenses="Elastic License" \
  org.opencontainers.image.description="Logstash is a free and open server-side data processing pipeline that ingests data from a multitude of sources, transforms it, and then sends it to your favorite 'stash.'" \
  org.label-schema.build-date=2020-12-05T03:00:47Z \
org.opencontainers.image.created=2020-12-05T03:00:47Z


ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
