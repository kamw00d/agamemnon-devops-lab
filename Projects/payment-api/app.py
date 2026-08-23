import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

class PaymentAPIHandler(BaseHTTPRequestHandler):
	def do_GET(self):
		if self.path == "/health":
			self.send_response(200)
			self.end_headers()
			self.wfile.write(b"payment-api: healthy\n")

		elif self.path == "/whereami":
			hostname = socket.gethostname()
			self.send_response(200)
			self.end_headers()
			self.wfile.write(f"payment-api running on: {hostname}\n".encode())

		else:
			self.send_response(404)
			self.end_headers()
			self.wfile.write(b"Not Found\n")

PORT = int(os.getenv("PORT", "8080"))

server = HTTPServer(("0.0.0.0", PORT), PaymentAPIHandler)

print(f"payment-api listening on port {PORT}")
server.serve_forever()
