from http.server import BaseHTTPRequestHandler, HTTPServer

class PaymentAPIHandler(BaseHTTPRequestHandler):
	def do_GET(self):
		if self.path == "/health":
			self.send_response(200)
			self.end_headers()
			self.wfile.write(b"payment-api: healthy\n")
		else:
			self.send_response(404)
			self.end_headers()
			self.wfile.write(b"Not Found\n")

server = HTTPServer(("0.0.0.0", 8080), PaymentAPIHandler)

print("payment-api listening on port 8080")
server.serve_forever()
