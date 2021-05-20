FROM nginx:1.19.10

COPY entrypoint.sh ./
RUN ["chmod", "+x", "./entrypoint.sh"]

COPY ./index.html /usr/share/nginx/html/index.html
COPY ./nginx.conf.template /etc/nginx/conf.d/nginx.conf.template

ENTRYPOINT ["./entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]