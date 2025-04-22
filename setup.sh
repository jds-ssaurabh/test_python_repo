#!/bin/bash

DOMAIN_NAME="gurucool.gotdns.ch"
MYSQL_USER="myuser"
MYSQL_PASS="Str0ngPass@123"
MYSQL_DB="myapp_db"
PYTHON_VERSION="3.12"

# 1. System Update
sudo apt update && sudo apt upgrade -y

# 2. Install core packages
sudo apt install -y python3 python3-pip python3-venv nginx mysql-server ufw curl unzip software-properties-common

# 3. Setup Python venv
mkdir -p ~/myapp && cd ~/myapp
python3 -m venv myenv
source myenv/bin/activate
pip install fastapi uvicorn[standard] jinja2 mysql-connector-python

# 4. Setup MySQL user + db
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# 5. Configure UFW
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# 6. Setup Nginx
sudo tee /etc/nginx/sites-available/fastapi > /dev/null <<EOL
server {
    listen 80;
    server_name $DOMAIN_NAME;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name $DOMAIN_NAME;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/fastapi /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 7. Setup Certbot + HTTPS
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d $DOMAIN_NAME --non-interactive --agree-tos -m youremail@example.com --redirect

# 8. Setup systemd service (Optional)
# You can add a gunicorn or uvicorn service here later

echo "🎉 Setup complete for $DOMAIN_NAME"
