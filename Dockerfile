# ════ Stage 1: Build Angular App ════════════════════
FROM node:18-alpine AS build

WORKDIR /app

# Copy package files first for Docker layer cache
COPY package*.json ./

# Install all npm dependencies
RUN npm install

# Copy all Angular source code
COPY . .

# Build Angular for production (TypeScript → static files)
RUN npm run build -- --configuration production

# ════ Stage 2: Serve with Nginx ═════════════════════
FROM nginx:alpine

# Remove default Nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# Copy compiled Angular output from Stage 1
COPY --from=build /app/dist/my-angular-app /usr/share/nginx/html

# Copy our custom Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
