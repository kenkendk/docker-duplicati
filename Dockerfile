# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG DUPLICATI_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config"

RUN \
  echo "**** add mono repository ****" && \
  apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
  echo "deb http://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official.list && \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y \
    mono-devel \
    mono-vbnc \
    unzip && \
  echo "**** install duplicati ****" && \
  if [ -z ${DUPLICATI_RELEASE+x} ]; then \
    DUPLICATI_RELEASE=$(curl -sX GET "https://api.github.com/repos/duplicati/duplicati/releases" \
      | jq -r 'first(.[] | select(.tag_name | contains("canary"))) | .tag_name'); \
  fi && \
  mkdir -p \
    /app/duplicati && \
  duplicati_url=$(curl -s https://api.github.com/repos/duplicati/duplicati/releases/tags/"${DUPLICATI_RELEASE}" |jq -r '.assets[].browser_download_url' |grep '.zip$' |grep -v signatures) || \
    duplicati_url="https://updates.duplicati.com/canary/duplicati-$(echo $DUPLICATI_RELEASE | sed 's|^v[0-9.]*-||').zip" && \
  curl -fso \
    /tmp/duplicati.zip -L \
    "${duplicati_url}" && \
  unzip -q /tmp/duplicati.zip -d /app/duplicati && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 8200
VOLUME /backups /config /source
