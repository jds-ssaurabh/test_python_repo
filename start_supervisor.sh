#!/bin/bash

# === Basic config ===
PYTHON_USER=youruser
PYTHON_APP_DIR="/home/$PYTHON_USER/my-python-app"
PYTHON_VENV_DIR="/home/$PYTHON_USER/venv"
PYTHON_ENTRY="main:app"

NODE_APP_DIR="/home/$PYTHON_USER/my-node-app"
NODE_ENTRY="server.js"

# === Install supervisor ===
echo "🔧 Installing Supervisor..."
sudo apt update
sudo apt install -y supervisor

# === Python App Supervisor Config ===
echo "⚙️ Configuring Python app..."
sudo tee /etc/supervisor/conf.d/python_app.conf > /dev/null <<EOF
[program:python_app]
directory=$PYTHON_APP_DIR
command=$PYTHON_VENV_DIR/bin/uvicorn $PYTHON_ENTRY --host 0.0.0.0 --port 8000
autostart=true
autorestart=true
stderr_logfile=/var/log/python_app.err.log
stdout_logfile=/var/log/python_app.out.log
user=$PYTHON_USER
EOF

# === Node App Supervisor Config ===
echo "⚙️ Configuring Node app..."
NODE_BIN=$(which node)
sudo tee /etc/supervisor/conf.d/node_app.conf > /dev/null <<EOF
[program:node_app]
directory=$NODE_APP_DIR
command=$NODE_BIN $NODE_ENTRY
autostart=true
autorestart=true
stderr_logfile=/var/log/node_app.err.log
stdout_logfile=/var/log/node_app.out.log
user=$PYTHON_USER
EOF

# === Reload Supervisor ===
echo "🔁 Reloading Supervisor..."
sudo supervisorctl reread
sudo supervisorctl update

# === Start Apps ===
echo "🚀 Starting Apps..."
sudo supervisorctl start python_app
sudo supervisorctl start node_app

echo "✅ All done! Use 'sudo supervisorctl status' to check process status."
