#!/usr/bin/env python3
"""
Rootpath - vulnerable web service (legitimate feature only, for now).
Provides a simple network diagnostic tool: ping a host and show the result.
"""

import re
import subprocess
from flask import Flask, request, render_template_string

app = Flask(__name__)

PAGE = """
<!doctype html>
<title>Rootpath Diagnostic Tool</title>
<h1>Network Diagnostic Tool</h1>
<form method="POST">
    <label>Host to ping:</label>
    <input type="text" name="host" placeholder="e.g. 192.168.56.1">
    <input type="submit" value="Ping">
</form>
{% if output %}
<h2>Result</h2>
<pre>{{ output }}</pre>
{% endif %}
"""

# Only allow simple hostnames / IPv4 addresses for now.
HOST_PATTERN = re.compile(r"^[a-zA-Z0-9.\-]+$")


@app.route("/", methods=["GET", "POST"])
def index():
    output = None
    if request.method == "POST":
        host = request.form.get("host", "")
        if HOST_PATTERN.match(host):
            result = subprocess.run(
                ["ping", "-c", "1", host],
                capture_output=True,
                text=True,
                timeout=5,
            )
            output = result.stdout + result.stderr
        else:
            output = "Invalid host format."
    return render_template_string(PAGE, output=output)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
