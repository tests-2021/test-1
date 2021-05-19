#!/bin/bash

cd server
docker build . -t test-1-server

cd ../calculator
docker build . -t test-1-calculator

cd ../ui
docker build . -t test-1-ui

docker-compose up
