#!/bin/sh

helm install --set pwd=`pwd` internet-monitoring docker-compose/
