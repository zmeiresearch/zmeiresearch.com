# Builds one of the Jekyll sites (SITE=www|blog) and serves it as static files.
# Build context is the repository root so the shared theme is available.

FROM ruby:3.4-slim AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY Gemfile Gemfile.lock ./
COPY theme/jekyll-theme-zmei.gemspec theme/
RUN bundle install --jobs 4
COPY theme theme

FROM build AS dev
EXPOSE 4000 35729

FROM build AS site
ARG SITE
COPY ${SITE} ${SITE}
RUN JEKYLL_ENV=production bundle exec jekyll build --source ${SITE} --destination /out

FROM caddy:2-alpine
COPY docker/static.Caddyfile /etc/caddy/Caddyfile
COPY --from=site /out /srv
