#!/bin/sh

# Start the httpd server
mkdir -p /var/www
darkhttpd /var/www \
  --daemon \
  --pidfile /var/run/darkhttp.pid

# Start Consul Template
consul-template \
  -log-level=debug \
  -template=/index.html.ctmpl:/var/www/index.html
