from http.server import BaseHTTPRequestHandler, HTTPServer
import html
import os
import socket
import urllib.request

DATABASE_HOST = os.getenv("DATABASE_HOST", "")
DATABASE_PORT = int(os.getenv("DATABASE_PORT", "5432"))


def metadata(path):
    token_request = urllib.request.Request(
        "http://169.254.169.254/latest/api/token",
        method="PUT",
        headers={"X-aws-ec2-metadata-token-ttl-seconds": "21600"},
    )
    with urllib.request.urlopen(token_request, timeout=2) as response:
        token = response.read().decode()

    request = urllib.request.Request(
        "http://169.254.169.254/latest/meta-data/" + path,
        headers={"X-aws-ec2-metadata-token": token},
    )
    with urllib.request.urlopen(request, timeout=2) as response:
        return response.read().decode()


def database_status():
    try:
        with socket.create_connection((DATABASE_HOST, DATABASE_PORT), timeout=2):
            return "connected"
    except OSError:
        return "unreachable"


def page():
    instance_id = metadata("instance-id")
    private_ip = metadata("local-ipv4")
    availability_zone = metadata("placement/availability-zone")
    db_status = database_status()
    db_class = "ok" if db_status == "connected" else "bad"

    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>App</title>
  <style>
    body {{
      margin: 0;
      background: #f4f7fb;
      color: #1f2937;
      font-family: Arial, Helvetica, sans-serif;
    }}
    main {{
      max-width: 960px;
      margin: 0 auto;
      padding: 40px 20px;
    }}
    header {{
      margin-bottom: 28px;
    }}
    h1 {{
      margin: 0 0 8px;
      font-size: 32px;
    }}
    p {{
      line-height: 1.5;
    }}
    .grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
      gap: 16px;
    }}
    .card {{
      background: white;
      border: 1px solid #d9e2ec;
      border-radius: 8px;
      padding: 18px;
      box-shadow: 0 8px 20px rgba(31, 41, 55, 0.08);
    }}
    .label {{
      color: #64748b;
      font-size: 13px;
      margin-bottom: 6px;
      text-transform: uppercase;
    }}
    .value {{
      font-size: 22px;
      font-weight: 700;
      overflow-wrap: anywhere;
    }}
    .ok {{
      color: #047857;
    }}
    .bad {{
      color: #b91c1c;
    }}
    code {{
      background: #e8eef6;
      border-radius: 4px;
      padding: 2px 5px;
    }}
  </style>
</head>
<body>
  <main>
    <header>
      <h1>App</h1>
    </header>
    <section class="grid">
      <div class="card">
        <div class="label">Instance ID</div>
        <div class="value">{html.escape(instance_id)}</div>
      </div>
      <div class="card">
        <div class="label">Private IP</div>
        <div class="value">{html.escape(private_ip)}</div>
      </div>
      <div class="card">
        <div class="label">Availability Zone</div>
        <div class="value">{html.escape(availability_zone)}</div>
      </div>
      <div class="card">
        <div class="label">Database</div>
        <div class="value {db_class}">{html.escape(db_status)}</div>
      </div>
      <div class="card">
        <div class="label">Database Host</div>
        <div class="value">{html.escape(DATABASE_HOST)}</div>
      </div>
      <div class="card">
        <div class="label">Database Port</div>
        <div class="value">{DATABASE_PORT}</div>
      </div>
      <div class="card">
        <div class="label">Health Check</div>
        <div class="value"><code>/health</code></div>
      </div>
    </section>
  </main>
</body>
</html>
"""


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok\n")
            return

        response = page().encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(response)))
        self.end_headers()
        self.wfile.write(response)

    def log_message(self, format, *args):
        return


HTTPServer(("0.0.0.0", 80), Handler).serve_forever()
