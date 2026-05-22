#!/bin/bash
set -euo pipefail

mkdir -p /opt/database-placeholder

cat > /opt/database-placeholder/server.py <<'PY'
import socket

HOST = "0.0.0.0"
PORT = int("${database_port}")

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as server:
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((HOST, PORT))
    server.listen()

    while True:
        connection, _ = server.accept()
        with connection:
            connection.sendall(b"database placeholder\n")
PY

cat > /etc/systemd/system/database-placeholder.service <<'SERVICE'
[Unit]
Description=Simple TCP database placeholder
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/python3 /opt/database-placeholder/server.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable --now database-placeholder.service
