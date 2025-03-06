#!/bin/bash
DESTINATION=$1
PORT=$2
CHAT=$3

# Clone Odoo directory
git clone --depth=1 https://github.com/jamshaha/odoo-17-docker-compose $DESTINATION
rm -rf $DESTINATION/.git

# Create required directories
mkdir -p $DESTINATION/postgresql
mkdir -p $DESTINATION/enterprise-addons
mkdir -p $DESTINATION/secrets
mkdir -p $DESTINATION/etc/odoo

# Generate secure password if not exists
if [ ! -f "$DESTINATION/secrets/postgres_password.txt" ]; then
    openssl rand -base64 32 > $DESTINATION/secrets/postgres_password.txt
fi

# Change ownership and set restrictive permissions
sudo chown -R $USER:$USER $DESTINATION
sudo chmod -R 700 $DESTINATION
sudo chmod 600 $DESTINATION/secrets/postgres_password.txt

# Check if running on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Running on macOS. Skipping inotify configuration."
else
    # System configuration
    if ! grep -qF "fs.inotify.max_user_watches" /etc/sysctl.conf; then
        echo "fs.inotify.max_user_watches = 524288" | sudo tee -a /etc/sysctl.conf
    fi
    sudo sysctl -p
fi

# Create .env file with ports
cat > $DESTINATION/.env << EOF
ODOO_PORT=$PORT
CHAT_PORT=$CHAT
EOF

# Set file permissions
find $DESTINATION -type f -exec chmod 644 {} \;
find $DESTINATION -type d -exec chmod 755 {} \;
chmod 600 $DESTINATION/secrets/postgres_password.txt

# Run Odoo
docker-compose -f $DESTINATION/docker-compose.yml up -d

echo "Odoo started at http://localhost:$PORT"
echo "Live chat port: $CHAT"
echo "Check your secure password in $DESTINATION/secrets/postgres_password.txt"