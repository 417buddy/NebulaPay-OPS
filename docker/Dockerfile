# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY apps/payment-api/package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy source and build
COPY apps/payment-api/ ./
RUN npm run build

# Production stage
FROM node:20-alpine AS production

# Security: Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Copy built artifacts from builder
COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./

# Switch to non-root user
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health/live', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

# Expose port
EXPOSE 3000

# Start application
CMD ["node", "dist/index.js"]