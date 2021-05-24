FROM node:10-alpine as build-step
RUN mkdir -p /app
WORKDIR /app
COPY . /app
RUN npm install
RUN npm install -g @angular/cli@1.7.4
