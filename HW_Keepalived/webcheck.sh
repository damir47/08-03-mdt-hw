#!/bin/bash

if nc -zv 10.0.2.199 80; then
	echo "port open"
else
	echo "port closed"
	exit 1
fi

if [ -f /var/www/html/index.html ]; then
  echo "index.html found"
else
  echo "index.html not found"
  exit 2
fi
exit 0
