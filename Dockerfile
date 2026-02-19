# ════ Stage 1: Build Angular App ════════════════════
FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build -- --configuration production


# ════ Stage 2: Serve with Nginx ═════════════════════
FROM nginx:alpine

# Remove default Nginx welcome page
RUN rm -rf /usr/share/nginx/html/*

# Copy compiled Angular output
COPY --from=build /app/dist/my-angular-app /usr/share/nginx/html

# 🔴 THIS IS THE FIX (MANDATORY)
RUN chown -R nginx:nginx /usr/share/nginx/html \
    && chmod -R 755 /usr/share/nginx/html

# Copy custom Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
