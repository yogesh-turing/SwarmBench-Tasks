FROM node:20.11.1-bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    bash \
    ca-certificates \
    git \
    openssh-client \
    patch \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /logs

# Clone Node-RED at v3.1.3 — the stable release before all five bugs were fixed.
# Commit 4bb92b43ef18d1fce37b54ba90c578f1c07d98d is the annotated tag 3.1.3.
# If a different exact SHA is needed, run:
#   git ls-remote https://github.com/node-red/node-red.git refs/tags/3.1.3
RUN git init /testbed && \
    cd /testbed && \
    git remote add origin https://github.com/node-red/node-red.git && \
    git fetch --depth 1 origin refs/tags/3.1.3 && \
    git checkout FETCH_HEAD

WORKDIR /testbed

# Install dependencies. --ignore-scripts avoids running the build pipeline
# which would fail without a display; the agent will run builds as needed.
RUN npm install --ignore-scripts --legacy-peer-deps

# Remove git history to prevent the agent from reading commit history and
# discovering the upstream PRs that fix these issues.
RUN rm -rf /testbed/.git

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
