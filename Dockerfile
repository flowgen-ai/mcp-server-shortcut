# ── Stage 1: Build Shortcut MCP server ───────────────────────
FROM node:18-alpine AS shortcut_builder
WORKDIR /usr/src/app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Build TS → JS
COPY . .
RUN npm run build

# ── Stage 2: Python MCP-Proxy + Shortcut server ───────────────
FROM ghcr.io/sparfenyuk/mcp-proxy:latest
WORKDIR /app

# Install node so we can run the JS bundle
RUN apk update && apk add --no-cache nodejs npm

# Copy over the built server and its node_modules
COPY --from=shortcut_builder /usr/src/app/dist ./dist
COPY --from=shortcut_builder /usr/src/app/node_modules ./node_modules
COPY --from=shortcut_builder /usr/src/app/package.json ./

# Expose the SSE port (same as before)
EXPOSE 3001

# Start MCP-Proxy (SSE→stdio) then launch the Shortcut MCP server
ENTRYPOINT [
  "mcp-proxy",
    "--pass-environment",
    "--sse-port", "3001",
    "--sse-host", "0.0.0.0",
  "--",
  "node", "dist/index.js"
]
