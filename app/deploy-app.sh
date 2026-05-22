#!/bin/bash
set -euo pipefail

install -d /opt/app
install -m 0644 app.py /opt/app/app.py
install -m 0644 app.service /etc/systemd/system/app.service

systemctl daemon-reload
systemctl enable --now app.service
