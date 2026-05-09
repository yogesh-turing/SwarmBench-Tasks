FROM node:20.18.3-bookworm-slim

RUN apt-get update && apt-get install -y git python3 && rm -rf /var/lib/apt/lists/*

WORKDIR /testbed
RUN git clone --depth=1 --branch v3.29.5 https://github.com/fastify/fastify.git . \
    && rm -rf /testbed/.git \
    && npm install

RUN mkdir -p /logs/verifier
