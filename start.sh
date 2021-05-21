#!/bin/bash

cd server
docker build . -t test-1-server

cd ../calculator
docker build . -t test-1-calculator

cd ../fast-calculator
docker build . -t test-1-fast-calculator

docker-compose up
