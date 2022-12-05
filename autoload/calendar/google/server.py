from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs
from textwrap import dedent
import html


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.end_headers()
        queries = parse_qs(urlparse(self.path).query)
        if 'code' in queries:
            self.wfile.write(dedent(f'''
                <!DOCTYPE html>
                <html>
                <head>
                    <style>pre::before {{ content: 'CODE: '; }}</style>
                </head>
                <body>
                    <pre>{html.escape(queries['code'][0])}</pre>
                </body>
                </html>
            ''').encode('utf-8'))
            self.server.shutdown()
        else:
            self.wfile.write(b'<body><pre>Unknown CODE</pre></body>')

    def log_message(self, format, *args):
        pass


with ThreadingHTTPServer(('localhost', 8080), Handler) as server:
    server.serve_forever()
