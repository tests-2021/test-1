#!/bin/bash

cd server
docker build . -t test-1-server

cd ../calculator
docker build . -t test-1-calculator

docker-compose up
