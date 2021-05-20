#!/usr/bin/env sh
set -eu

envsubst '${CALC_HOST} ${CALC_PORT}' < /etc/nginx/conf.d/nginx.conf.template > /etc/nginx/conf.d/nginx.conf

exec "$@"