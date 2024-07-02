#!/bin/bash

# Update and install necessary packages
sudo apt-get update
sudo apt-get install -y clang cmake build-essential git wget curl

# Install Rust and Cargo
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Install Go
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
source ~/.profile

# Clone the GitHub repository
read -p "Enter the version you want to clone (default: v0.3.2): " version
version=${version:-v0.3.2}
git clone -b $version https://github.com/0glabs/0g-storage-node.git

cd 0g-storage-node
git submodule update --init

# Build the project in release mode
cargo build --release

# Edit the configuration file
CONFIG_FILE="run/config.toml"
echo "Please enter your miner key (must have at least 1 Testnet token):"
read miner_key
public_ip=$(curl -s ifconfig.me)
sed -i "s/miner_key=\"\"/miner_key=\"$miner_key\"/" $CONFIG_FILE
sed -i "s/network_enr_address=\"\"/network_enr_address=\"$public_ip\"/" $CONFIG_FILE

# Create the systemd service file
SERVICE_FILE="/etc/systemd/system/zgs_node.service"
sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=ZGS Node Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$(pwd)/run
ExecStart=$(pwd)/target/release/zgs_node --config config.toml
Restart=always
RestartSec=10
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=zgs_node

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd, enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable zgs_node.service
sudo systemctl start zgs_node.service

echo "Installation and setup complete. The zgs_node service is now running."
