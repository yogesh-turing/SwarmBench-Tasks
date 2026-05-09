FROM node:20.11.1-bullseye

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl patch python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /logs

RUN git init /testbed && \
    cd /testbed && \
    git remote add origin https://github.com/expressjs/body-parser.git && \
    git fetch --depth 1 origin df2def57974da6de89fdf391c9ae73b7f6eec293 && \
    git checkout FETCH_HEAD && \
    rm -rf /testbed/.git

WORKDIR /testbed
ENV NODE_ENV=test
RUN npm install
CMD ["bash"]