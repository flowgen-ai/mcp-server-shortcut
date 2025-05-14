# ── Stage 1: Build Shortcut MCP server ───────────────────────
FROM node:18-alpine AS shortcut_builder
WORKDIR /usr/src/app

# Copy manifests (package.json, and package-lock.json if you add one later)
COPY package*.json ./

# Install all dependencies (creates node_modules and a lockfile if missing)
RUN npm install

# Copy source and build
COPY . .
RUN npm run build

# ── Stage 2: Python MCP-Proxy + Shortcut server ───────────────
FROM ghcr.io/sparfenyuk/mcp-proxy:latest
WORKDIR /app

# Install Node so we can run the JS bundle
RUN apk update && apk add --no-cache nodejs npm

# Copy built server and its dependencies
COPY --from=shortcut_builder /usr/src/app/dist ./dist
COPY --from=shortcut_builder /usr/src/app/node_modules ./node_modules
COPY --from=shortcut_builder /usr/src/app/package.json ./

# Expose the same SSE port
EXPOSE 3001

# Start MCP-Proxy (SSE→stdio) then launch the Shortcut MCP server
ENTRYPOINT ["mcp-proxy","--pass-environment","--sse-port","3001","--sse-host","0.0.0.0","--","node","dist/index.js"]
