#!/bin/sh

#
cat > /restart-haproxy.sh <<"EOF"
#!/bin/sh
if [ -f /var/run/haproxy.pid ]; then
  haproxy -f /haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid)
else
  haproxy -f /haproxy.cfg -p /var/run/haproxy.pid
fi

cat /haproxy.cfg
exit 0
EOF
chmod +x /restart-haproxy.sh

# Start Consul Template and haproxy.
consul-template \
  -log-level=debug \
  -template="/haproxy.cfg.ctmpl:/haproxy.cfg:/restart-haproxy.sh"
