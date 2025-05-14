FROM node:18-alpine AS shortcut_builder
WORKDIR /usr/src/app

# Install dependencies for fetching Bun
RUN apk add --no-cache curl tar

# Install Bun globally
RUN curl -fsSL https://bun.sh/install | bash \
    && mv /root/.bun/bin/bun /usr/local/bin/

# Copy and install deps (skip prepublish)
COPY package.json package-lock.json ./
RUN npm install --ignore-scripts

# Copy your code & run build with Bun
COPY . .
RUN npm run build   

# ── Stage 2: same as above ────────────────────────────────
FROM ghcr.io/sparfenyuk/mcp-proxy:latest
WORKDIR /app
RUN apk update && apk add --no-cache nodejs npm
COPY --from=shortcut_builder /usr/src/app/dist    ./dist
COPY --from=shortcut_builder /usr/src/app/node_modules ./node_modules
COPY --from=shortcut_builder /usr/src/app/package.json ./
EXPOSE 3001
ENTRYPOINT ["mcp-proxy","--pass-environment","--sse-port","3001","--sse-host","0.0.0.0","--","node","dist/index.js"]
