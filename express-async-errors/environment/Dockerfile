FROM node:22.14.0-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl patch python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /logs

RUN git init /testbed && \
    cd /testbed && \
    git remote add origin https://github.com/expressjs/express.git && \
    git fetch --depth 1 origin refs/tags/4.19.2 && \
    git checkout FETCH_HEAD && \
    rm -rf /testbed/.git

WORKDIR /testbed
RUN npm install
