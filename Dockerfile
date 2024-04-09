ARG UBUNTU_VERSION=22.04
FROM ubuntu:$UBUNTU_VERSION
LABEL org.opencontainers.image.authors="mammo0 - https://github.com/mammo0"

# Update package lists and install general dependencies
RUN apt-get update -qq && \
    apt-get upgrade -yq && \
    apt-get install -yq curl libmagic-dev wget logrotate

# Declare arguments
ARG ARKIME_VERSION=5.1.0
ARG ARKIME_DEB_PACKAGE="arkime_${ARKIME_VERSION}-1.ubuntu2204_amd64.deb"

# Set environment variables
ENV ARKIME_VERSION $ARKIME_VERSION
ENV OS_HOST "opensearch"
ENV OS_PORT "9200"
ENV ARKIME_INTERFACE "eth0"
ENV ARKIME_ADMIN_PASSWORD "admin"
ENV ARKIME_HOSTNAME "localhost"
ENV ARKIMEDIR "/opt/arkime"
ENV CAPTURE "off"
ENV VIEWER "on"

# Install Arkime dependencies
RUN apt-get install -yq libwww-perl libjson-perl ethtool libyaml-dev liblua5.4-0 libmaxminddb0 libpcap0.8 libglib2.0-0 libyara8 librdkafka1

# Download and install Arkime
RUN mkdir -p /data && \
    cd /data && \
    curl -L -O "https://github.com/arkime/arkime/releases/download/v${ARKIME_VERSION}/${ARKIME_DEB_PACKAGE}" && \
    dpkg -i "${ARKIME_DEB_PACKAGE}" && \
    apt-get install -f -yq && \
    mv "${ARKIMEDIR}/etc" /data/config && \
    ln -s /data/config "${ARKIMEDIR}/etc" && \
    ln -s /data/logs "${ARKIMEDIR}/logs" && \
    ln -s /data/pcap "${ARKIMEDIR}/raw" && \
    "${ARKIMEDIR}/bin/arkime_update_geo.sh"

# Clean up
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/* && \
    rm "/data/${ARKIME_DEB_PACKAGE}"

# Add scripts
ADD /scripts /data/
RUN chmod 755 /data/*.sh

VOLUME ["/data/pcap", "/data/config", "/data/logs"]
EXPOSE 8005
WORKDIR "$ARKIMEDIR"

ENTRYPOINT ["/data/startarkime.sh"]

