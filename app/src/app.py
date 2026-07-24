#!/usr/bin/env python3
"""
Rootpath - vulnerable web service (VULNERABLE VERSION).
Contains an intentional OS command-injection vulnerability in the
'host' parameter, for educational purposes only.
"""

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


@app.route("/", methods=["GET", "POST"])
def index():
    output = None
    if request.method == "POST":
        host = request.form.get("host", "")
        # VULNERABLE: user input is concatenated into a shell string
        # and executed with shell=True, allowing command injection.
        command = f"ping -c 1 {host}"
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=5,
        )
        output = result.stdout + result.stderr
    return render_template_string(PAGE, output=output)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
