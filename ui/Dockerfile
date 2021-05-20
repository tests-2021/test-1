FROM node:12.19-alpine as build

RUN mkdir -p /app
WORKDIR /app
COPY package*.json /app/
RUN npm install
COPY ./ /app/
RUN npm run build --prod

# Stage 2

FROM nginx:1.17.1-alpine
COPY --from=build /app/dist/ui /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 9294
