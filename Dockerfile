# ── Stage 1: Build Shortcut MCP server ───────────────────────
FROM node:18-alpine AS shortcut_builder
WORKDIR /usr/src/app

# 1. Copy only package manifests
COPY package.json package-lock.json ./

# 2. Install deps but IGNORE scripts (skip prepublish/prepare)
RUN npm install --ignore-scripts                                   

# 3. Bring in your application code
COPY . .                                                           

# 4. Run the build (this runs 'build' then 'postbuild')
RUN npm run build                                                   

# ── Stage 2: Python MCP-Proxy + Shortcut server ───────────────
FROM ghcr.io/sparfenyuk/mcp-proxy:latest
WORKDIR /app

# Install Node to run the JS bundle
RUN apk update && apk add --no-cache nodejs npm                   

# Copy the built server and its dependencies
COPY --from=shortcut_builder /usr/src/app/dist    ./dist
COPY --from=shortcut_builder /usr/src/app/node_modules ./node_modules
COPY --from=shortcut_builder /usr/src/app/package.json ./

# Expose the same SSE port
EXPOSE 3001

# Start MCP-Proxy (SSE→stdio) then launch the Shortcut MCP server
ENTRYPOINT ["mcp-proxy","--pass-environment","--sse-port","3001","--sse-host","0.0.0.0","--","node","dist/index.js"]
