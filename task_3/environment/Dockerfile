FROM node:22-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /logs

# lodash v4.18.1 — annotated tag peels to this commit
RUN git init /testbed && \
    cd /testbed && \
    git remote add origin https://github.com/lodash/lodash.git && \
    git fetch --depth 1 origin 43a045eb3f4294a442fd735a34b9f4303c71ac0b && \
    git checkout FETCH_HEAD

WORKDIR /testbed
RUN rm -rf .git

RUN npm ci