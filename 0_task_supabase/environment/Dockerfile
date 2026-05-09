FROM node:22-alpine

# Required by swarm-kimi-single installer, which executes: apt-get update && apt-get install -y curl
RUN apk add --no-cache git patch bash python3 ca-certificates apt curl

# Alpine doesn't provide Debian apt repositories; shim apt-get calls used by the agent installer.
RUN printf '%s\n' \
    '#!/bin/sh' \
    'set -eu' \
    '' \
    'if [ "${1:-}" = "update" ]; then' \
    '  exit 0' \
    'fi' \
    '' \
    'if [ "${1:-}" = "install" ]; then' \
    '  shift' \
    '  while [ "${1:-}" = "-y" ] || [ "${1:-}" = "--no-install-recommends" ]; do' \
    '    shift' \
    '  done' \
    '  if [ "$#" -eq 0 ]; then' \
    '    exit 0' \
    '  fi' \
    '  exec apk add --no-cache "$@"' \
    'fi' \
    '' \
    'exec /usr/bin/apt-get "$@"' \
    > /usr/local/bin/apt-get \
    && chmod +x /usr/local/bin/apt-get

# Clone Directus at v11.17.2 - the commit before all four bug fixes were applied.
# This gives us a reproducible baseline where all four issues are present.
RUN git init /testbed && \
    cd /testbed && \
    git remote add origin https://github.com/supabase/supabase.git && \
    git fetch --depth 1 origin 08ccfc4b18ae7ae14b148d61aafcfc428996d61a && \
    git checkout FETCH_HEAD && \
    rm -rf /testbed/.git

WORKDIR /testbed
