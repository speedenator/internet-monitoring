#!/bin/sh

./helm-uninstall.sh
echo -n "sleeping 60..."
sleep 60
echo "done"
./helm-install.sh

