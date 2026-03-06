FROM ruby:3.4.5-alpine3.22 AS builder

WORKDIR /app

# Build-only dependencies required for native gems.
RUN apk add --no-cache \
  build-base \
  postgresql-dev \
  yaml-dev \
  git

COPY Gemfile* .ruby-version ./

ENV BUNDLE_WITHOUT="development:test" \
  BUNDLE_PATH=/app/vendor/bundle

RUN bundle config set deployment 'true' \
  && bundle install --jobs 4 --retry 3

FROM ruby:3.4.5-alpine AS runtime

ENV LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  TZ=Europe/London \
  BUNDLE_DEPLOYMENT=1 \
  BUNDLE_WITHOUT=development:test \
  BUNDLE_PATH=/app/vendor/bundle

WORKDIR /app

# Runtime libraries only.
RUN apk add --no-cache \
  ca-certificates \
  tzdata \
  postgresql-libs \
  yaml \
  jemalloc

RUN addgroup -S appgroup -g 1001 \
  && adduser -S appuser -u 1001 -G appgroup -h /home/appuser

COPY --from=builder /app/vendor/bundle /app/vendor/bundle

# Install RDS trust bundle for PostgreSQL SSL connections.
RUN mkdir -p /home/appuser/.postgresql \
  && wget -qO /home/appuser/.postgresql/root.crt https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem \
  && chown -R appuser:appgroup /home/appuser

COPY --chown=appuser:appgroup . /app

RUN mkdir -p /app/log /app/tmp \
  && chown -R appuser:appgroup /app/log /app/tmp

ARG BUILD_NUMBER
ARG GIT_BRANCH
ARG GIT_REF

ENV BUILD_NUMBER=${BUILD_NUMBER} \
  GIT_BRANCH=${GIT_BRANCH} \
  GIT_REF=${GIT_REF}

USER 1001
