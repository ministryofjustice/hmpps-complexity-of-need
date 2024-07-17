FROM ruby:3.3.4-slim-bullseye

RUN \
  set -ex \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install \
    -y \
    --no-install-recommends \
    locales \
  && sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen \
  && dpkg-reconfigure --frontend=noninteractive locales \
  && update-locale LANG=en_GB.UTF-8 \
  && apt-get clean

ENV \
  LANG=en_GB.UTF-8 \
  LANGUAGE=en_GB.UTF-8 \
  LC_ALL=en_GB.UTF-8

ARG BUILD_NUMBER
ARG GIT_BRANCH
ARG GIT_REF

ENV BUILD_NUMBER=${BUILD_NUMBER}
ENV GIT_BRANCH=${GIT_BRANCH}
ENV GIT_REF=${GIT_REF}

WORKDIR /app

RUN \
  set -ex \
  && apt-get update && apt-get install \
    -y \
    --no-install-recommends \
    curl \
    build-essential \
    libpq-dev \
    libjemalloc-dev \
  && timedatectl set-timezone Europe/London || true \
  && gem update bundler --no-document \
  && apt-get clean

RUN mkdir -p /home/appuser/.postgresql && \
  curl https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem \
    > /home/appuser/.postgresql/root.crt

COPY Gemfile* .ruby-version ./

RUN bundle install --without development test --jobs 2 --retry 3

COPY . /app

# Record the SHA1 git commit reference in /app/RELEASE
# This file is automatically used by Sentry to track releases
RUN echo -n "$GIT_REF" > /app/RELEASE

RUN useradd appuser -u 1001 --user-group --home /home/appuser && \
  chown -R appuser:appuser /app && \
  chown -R appuser:appuser /home/appuser

USER 1001
