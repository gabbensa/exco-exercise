import os
import socket
from flask import Flask

app = Flask(__name__)

APP_VERSION = os.getenv("APP_VERSION", "1.0.0")
MESSAGE = os.getenv("APP_MESSAGE", "Hello from the EX.CO exercise!")

@app.get("/")
def home():
    return f"""<!doctype html>
<html>
  <body style="font-family: sans-serif; text-align: center; margin-top: 4rem">
    <h1>{MESSAGE}</h1>
    <p>Version: <strong>{APP_VERSION}</strong></p>
    <p>Served by pod: <strong>{socket.gethostname()}</strong></p>
  </body>
</html>"""

@app.get("/healthz")
def healthz():
    return "ok", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)
