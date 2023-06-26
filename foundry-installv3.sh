#!/usr/bin/env bash

# FoundryVTT download URL
FOUNDRY_URL=""
# Your desired hostname for Foundry example="foundry.example.com" default=""
FOUNDRY_HOSTNAME=""
# Location to save FoundryVTT app default="/opt/foundryvtt"
FOUNDRY_APP_DIR="/opt/foundryvtt"
# Location to save FoundryVTT assets/modules/systems default="/opt/foundrydata"
FOUNDRY_DATA_DIR="/opt/foundrydata"
# Port number for FoundryVTT default="30000" increment by 1 for additional instances
FOUNDRY_PORT="30000"
# Name for PM2 for daemon management default="foundry"
FOUNDRY_PM2_NAME="foundry"
# Username of non-root user to manage Foundry default="foundry"
FOUNDRY_USER="foundry"

# Perform initial setup for new Foundry installs
while true; do

read -p "Is this the first install? (y/n) " yn

case $yn in 
	[yY] ) echo "Setting up first install..."
      # Setup Foundry Install
      mkdir -p "$FOUNDRY_APP_DIR" "$FOUNDRY_DATA_DIR"
      wget -O "$FOUNDRY_APP_DIR/foundryvtt.zip" "$FOUNDRY_URL"
      
      # Update Date Time
      sed -i -e '$aNTP=time.google.com' /etc/systemd/timesyncd.conf
      sudo timedatectl set-ntp true
      sudo systemctl restart systemd-timesyncd.service
      
      # Update the OS Packages
      sudo apt update
      sudo apt upgrade -y
      
      # Setup Node prerequisites
      curl -sL https://deb.nodesource.com/setup_18.x | sudo bash -
      
      # Setup Caddy prerequisites
      apt install -y debian-keyring debian-archive-keyring apt-transport-https
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' |
      sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
      curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' |
      sudo tee /etc/apt/sources.list.d/caddy-stable.list
      apt update
      
      # Install Caddy and Node
      apt install -y libssl-dev npm unzip nodejs caddy

      # Create system user to manage Foundry
      useradd -r $FOUNDRY_USER

      # Install PM2 for daemon management
      npm install pm2@latest -g

      # Allow PM2 to start at boot
      pm2 startup

    break;;
	[nN] ) echo "Installing additional instance..."
		break;;
	* ) echo invalid response
esac

done

# Install Foundry
unzip "$FOUNDRY_APP_DIR/foundryvtt.zip" -d "$FOUNDRY_APP_DIR"

# Give non-root user ownership for Foundry directories
chown -R $FOUNDRY_USER:$FOUNDRY_USER "$FOUNDRY_APP_DIR" "$FOUNDRY_DATA_DIR"

# Give Foundry time to generate the options.json file
echo "Initializing FoundryVTT..."
timeout 10 node $FOUNDRY_APP_DIR/resources/app/main.js

# Initialize PM2 for daemon management
pm2 start "$FOUNDRY_APP_DIR/resources/app/main.js" --name $FOUNDRY_PM2_NAME --user foundry -- --dataPath="$FOUNDRY_DATA_DIR"
pm2 save
sleep 3
pm2 stop $FOUNDRY_PM2_NAME

# Configure Caddy for HTTPS proxying
cat >> /etc/caddy/Caddyfile <<EOF
${FOUNDRY_HOSTNAME} {
  @http {
    protocol http
  }
  redir @http https://${FOUNDRY_HOSTNAME}
  reverse_proxy localhost:$FOUNDRY_PORT
}
EOF

# Configure Foundry for HTTPS proxying
cat > "$FOUNDRY_DATA_DIR/Config/options.json" <<EOF
{
  "dataPath": "${FOUNDRY_DATA_DIR}",
  "compressStatic": true,
  "fullscreen": false,
  "hostname": "${FOUNDRY_HOSTNAME}",
  "language": "en.core",
  "localHostname": null,
  "port": $FOUNDRY_PORT,
  "protocol": null,
  "proxyPort": null,
  "proxySSL": false,
  "routePrefix": null,
  "updateChannel": "stable",
  "upnp": true,
  "upnpLeaseDuration": null,
  "awsConfig": null,
  "passwordSalt": null,
  "sslCert": null,
  "sslKey": null,
  "world": null,
  "serviceConfig": null
}
EOF

# Restart Foundry to take proxying into account
pm2 start $FOUNDRY_PM2_NAME

# Re-start Caddy
systemctl restart caddy

echo "FoundryVTT setup complete! Please access your instance here: https://$FOUNDRY_HOSTNAME"
