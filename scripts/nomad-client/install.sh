#!/usr/bin/env bash
set -e

echo "Installing Nomad dependencies..."
sudo apt-get update &>/dev/null
sudo apt-get install unzip &>/dev/null

echo "Fetching Nomad..."
cd /tmp
curl -s -L -o nomad.zip https://releases.hashicorp.com/nomad/0.3.0/nomad_0.3.0_linux_amd64.zip

echo "Installing Nomad..."
unzip nomad.zip >/dev/null
sudo chmod +x nomad
sudo mv nomad /usr/local/bin/nomad
sudo mkdir -p /etc/nomad.d

# Setup nomad directories
sudo mkdir -p /opt/nomad
sudo mkdir -p /opt/nomad/data
sudo mkdir -p /opt/nomad/jobs

echo "Installing Upstart service..."
sudo tee /etc/init/nomad.conf > /dev/null <<"EOF"
description "Nomad"

start on vagrant-ready or runlevel [2345]
stop on runlevel [!2345]

respawn

console log

script
  if [ -f "/etc/service/nomad" ]; then
    . /etc/service/nomad
  fi

  exec /usr/local/bin/nomad agent \
    -config="/etc/nomad.d" \
    ${NOMAD_FLAGS} \
    >>/var/log/nomad.log 2>&1
end script
EOF

echo "Starting Nomad..."
sudo service nomad start

echo "Registering Nomad with Consul..."
sudo tee /etc/consul.d/nomad-client.json > /dev/null <<"EOF"
{
  "service": {
    "name": "nomad-client",
    "port": 4646,
    "check": {
      "tcp": "localhost:4646",
      "interval": "10s",
      "timeout": "1s"
    }
  }
}
EOF

echo "Restarting Consul to register Nomad service..."
sudo service consul restart
