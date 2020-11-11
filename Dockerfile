FROM node:12-stretch-slim

RUN runDeps="openssl ca-certificates git" \
 && apt-get update \
 && apt-get install -y --no-install-recommends $runDeps \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/frontend \
 && chown -R node /opt/frontend

WORKDIR /opt/frontend/
RUN npm install -g yo @plone/generator-volto

USER node
RUN yo --no-insight @plone/volto my-volto-project --no-interactive

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["eslint"]
