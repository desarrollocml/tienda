# --- Stage 1: Builder ---
# This stage is used to install all dependencies (including dev) and build the application.
FROM node:20-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Install libc6-compat for some compatibility issues that might arise on Alpine
# https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine
RUN apk add --no-cache libc6-compat

# Copy package.json and lock file(s) first to leverage Docker's build cache
# This step is smart enough to use yarn.lock, package-lock.json, or pnpm-lock.yaml
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./

# Install dependencies based on the lock file found
RUN \
  if [ -f yarn.lock ]; then echo "Installing with yarn..."; yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then echo "Installing with npm ci..."; npm ci; \
  elif [ -f pnpm-lock.yaml ]; then echo "Installing with pnpm..."; corepack enable pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found. Using npm install fallback (not recommended)."; npm install; \
  fi

# Copy the rest of your application code
COPY . .

# Set NODE_ENV to production for the build process
ENV NODE_ENV production

# Execute the build script from package.json
# This script should generate the production files (e.g., in ./build)
RUN \
  if [ -f yarn.lock ]; then echo "Building with yarn..."; yarn run build; \
  elif [ -f package-lock.json ]; then echo "Building with npm..."; npm run build; \
  elif [ -f pnpm-lock.yaml ]; then echo "Building with pnpm..."; pnpm run build; \
  else echo "Building with npm (fallback)..."; npm run build; \
  fi

# --- Stage 2: Runner ---
# This stage is for the final, lightweight production image.
FROM node:20-alpine AS runner

# Set the working directory
WORKDIR /app

# Copy only the production dependencies from the builder stage (more secure and smaller image)
# Using the package manager used in the builder stage
COPY --from=builder /app/package.json ./package.json
RUN \
  if [ -f /app/yarn.lock ]; then echo "Installing production dependencies with yarn..."; yarn install --production --frozen-lockfile; \
  elif [ -f /app/package-lock.json ]; then echo "Installing production dependencies with npm..."; npm install --production --immutable --ignore-scripts; \
  elif [ -f /app/pnpm-lock.yaml ]; then echo "Installing production dependencies with pnpm..."; corepack enable pnpm && pnpm install --prod --frozen-lockfile; \
  else echo "Installing production dependencies with npm (fallback)..."; npm install --production; \
  fi


# Copy the built application code (the output of the build script) from the builder stage
COPY --from=builder /app/build ./build

# Optional: Copy your public directory if you have static assets there not managed by Payload uploads
# Ensure this directory exists in your project root
# COPY --from=builder /app/public ./public

# Configure the application environment for production
ENV NODE_ENV production
# Railway will inject the actual PORT, but setting a default is standard
ENV PORT 3000

# Optional: Create a non-root user for security
# RUN addgroup --system --gid 1001 nodejs \
#     && adduser --system --uid 1001 --shell /bin/sh --no-create-home -G nodejs nodejs
# RUN chown -R nodejs:nodejs /app # Give ownership of the app directory
# USER nodejs # Switch to the non-root user

# Expose the port the application listens on
EXPOSE 3000

# Command to run the application in production
# This should execute your 'start' script defined in package.json
# Assuming your start script runs `node build/server.js`
CMD [ "node", "build/server.js" ]
# Alternative using npm/yarn/pnpm start script (if your start script is just 'node build/server.js'):
# CMD [ "npm", "start" ] # Or "yarn", "start" or "pnpm", "start"