FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    patch \
    python3 \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /logs

# lodash v4.18.1 — annotated tag peels to this commit
RUN git init /lodash && \
    cd /lodash && \
    git remote add origin https://github.com/lodash/lodash.git && \
    git fetch --depth 1 origin 861d34919461c153cc1eaf92c39dc27e09446408 && \
    git checkout FETCH_HEAD

WORKDIR /lodash
RUN rm -rf .git

RUN npm ci
