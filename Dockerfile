# ── Stage 1: Build with Bun ────────────────────────────────
FROM oven/bun:1 AS shortcut_builder
WORKDIR /usr/src/app

# 1. Copy manifests and install
COPY package.json bunfig.toml ./
RUN bun install --frozen-lockfile

# 2. Bring in code & bundle
COPY . .
RUN bun build ./index.ts --outfile dist/index.js --target node

# ── Stage 2: Python MCP-Proxy + Shortcut server ────────────
FROM ghcr.io/sparfenyuk/mcp-proxy:latest
WORKDIR /app

# Install Node for runtime
RUN apk update && apk add --no-cache nodejs npm

# Copy built bundle and deps
COPY --from=shortcut_builder /usr/src/app/dist    ./dist
COPY --from=shortcut_builder /usr/src/app/node_modules ./node_modules
COPY --from=shortcut_builder /usr/src/app/package.json ./

EXPOSE 3001

ENTRYPOINT ["mcp-proxy","--pass-environment","--sse-port","3001","--sse-host","0.0.0.0","--","node","dist/index.js"]
