# Stage 1: Build React app
FROM node:18-alpine as builder

WORKDIR /app
COPY . .

RUN npm install
RUN npm run build

# Stage 2: Serve with "serve"
FROM node:18-alpine

WORKDIR /app
RUN npm install -g serve
COPY --from=builder /app/build ./build

EXPOSE 8080
CMD ["serve", "-s", "build", "-l", "8080"]
