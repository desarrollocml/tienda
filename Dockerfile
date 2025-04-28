# --- Stage 1: Builder ---
# This stage is used to install all dependencies (including dev) and build the application.
# We use a Node.js LTS image based on Alpine for a good balance of features and size.
FROM node:20-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Install libc6-compat for some compatibility issues that might arise on Alpine
# See: https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine
RUN apk add --no-cache libc6-compat

# Copy package.json and lock file(s) first to leverage Docker's build cache.
# If these files don't change, Docker won't rerun the dependency installation step.
# This step is smart enough to use yarn.lock, package-lock.json, or pnpm-lock.yaml
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./

# Install dependencies based on the lock file found.
# Using --frozen-lockfile or --immutable ensures repeatable builds.
# --- CORRECTED TO SINGLE LINE ---
RUN if [ -f yarn.lock ]; then echo "Installing with yarn..."; yarn install --frozen-lockfile; elif [ -f package-lock.json ]; then echo "Installing with npm ci..."; npm ci; elif [ -f pnpm-lock.yaml ]; then echo "Installing with pnpm..."; corepack enable pnpm && pnpm install --frozen-lockfile; else echo "Lockfile not found. Using npm install fallback (not recommended)."; npm install; fi
# --- END CORRECTED LINE ---

# Copy the rest of your application code
COPY . .

# Set NODE_ENV to production for the build process.
# This can affect build outputs or optimisations.
ENV NODE_ENV production

# Execute the build script from package.json.
# This script should compile your Payload CMS application, typically generating
# the production files into a directory like './build'.
# --- CORRECTED TO SINGLE LINE ---
RUN if [ -f yarn.lock ]; then echo "Building with yarn..."; yarn run build; elif [ -f package-lock.json ]; then echo "Building with npm..."; npm run build; elif [ -f pnpm-lock.yaml ]; then echo "Building with pnpm..."; pnpm run build; else echo "Building with npm (fallback)..."; npm run build; fi
# --- END CORRECTED LINE ---


# --- Stage 2: Runner ---
# This stage is for the final, lightweight production image.
# It copies only the build output and production dependencies.
FROM node:20-alpine AS runner

# Set the working directory
WORKDIR /app

# Copy only the package.json from the builder stage. We need this to install
# just the production dependencies in this stage.
COPY --from=builder /app/package.json ./package.json

# Install *only* the production dependencies.
# This keeps the final image size down and improves security by not including dev dependencies.
# --- CORRECTED TO SINGLE LINE ---
RUN if [ -f /app/yarn.lock ]; then echo "Installing production dependencies with yarn..."; yarn install --production --frozen-lockfile; elif [ -f /app/package-lock.json ]; then echo "Installing production dependencies with npm..."; npm install --production --immutable --ignore-scripts; elif [ -f /app/pnpm-lock.yaml ]; then echo "Installing production dependencies with pnpm..."; corepack enable pnpm && pnpm install --prod --frozen-lockfile; else echo "Installing production dependencies with npm (fallback)..."; npm install --production; fi
# --- END CORRECTED LINE ---

# Copy the built application code (the output of the build script from the builder stage).
# Adjust './build' if your build script outputs to a different directory.
COPY --from=builder /app/build ./build

# Optional: Copy your 'public' directory if you have static assets there
# that are not managed by Payload's upload fields and need to be served.
# Make sure this directory exists in your project root if uncommenting.
# COPY --from=builder /app/public ./public

# Configure the application environment for production.
ENV NODE_ENV production
# Railway will inject the actual PORT via a container environment variable,
# but setting a default like 3000 is a common practice.
ENV PORT 3000

# Recommended: Create a non-root user and run the container as this user for security.
# RUN addgroup --system --gid 1001 nodejs \
#     && adduser --system --uid 1001 --shell /bin/sh --no-create-home -G nodejs nodejs
# RUN chown -R nodejs:nodejs /app # Give ownership of the app directory to the new user
# USER nodejs # Switch subsequent commands to run as the new user

# Declare the port the application listens on. Used by Docker and orchestration tools.
EXPOSE 3000

# Define the command to run the application when the container starts.
# This should execute your 'start' script defined in package.json.
# We assume your start script runs something like `node build/server.js`.
# The [ "node", "build/server.js" ] format is preferred as it works directly
# without needing a shell and is compatible with signals.
CMD [ "node", "build/server.js" ]

# Alternative using the 'start' script via npm/yarn/pnpm (slightly less direct):
# CMD [ "npm", "start" ] # Or [ "yarn", "start" ] or [ "pnpm", "start" ]