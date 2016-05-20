#!/usr/bin/env python3

import gevent.monkey
gevent.monkey.patch_all()

import argparse
import json
import re
import string
import socket
import urllib.parse
import webbrowser

import flask
import gevent.pool
import gevent.pywsgi
import requests

app = flask.Flask(__name__, template_folder='.')

config = {
    'host': '127.0.0.1',
    'port': 48230,
    'blur': 60,
    'no_censor': False,
    'no_colors': False,
    'no_browser': False,
    'width': 5,
    'height': 3,
}

@app.route('/')
def index():
    return flask.render_template('main.html.tpl', config=config)

@app.route('/users')
def list_users():
    page = requests.get('https://chaturbate.com/').text
    user_names = re.findall(r'<div class="details">\s*<div class="title">\s*<a\s*href=\s*"/(.+?)/">', page)
    pool = gevent.pool.Pool(10)
    stream_urls = pool.map(get_user_stream, user_names)
    users = [{'name': name, 'stream': stream} for name, stream in zip(user_names, stream_urls) if stream]
    return flask.Response(json.dumps(users), mimetype='application/json')

def get_user_stream(user):
    page = requests.get('https://chaturbate.com/{}/?use_html_chat=1'.format(user)).text
    match = re.search('<video .*src="(.+?)"', page)
    if not match:
        return ''
    playlist = match.group(1).replace(' ', '%20')
    playlist = urllib.parse.urlparse(playlist)
    server_number = re.sub('[^\d]', '', playlist.netloc.split('.')[0])
    return '/streams/{}{}'.format(server_number, playlist.path)

@app.route('/streams/<int:server>/<path:path>')
def get_stream_file(server, path):
    full_url = 'http://edge{}.stream.highwebmedia.com:1935/{}'.format(server, path)
    resp = requests.get(full_url, stream=True)
    content = resp.iter_content(chunk_size=2 ** 16)
    status_code = resp.status_code
    content_type = resp.headers.get('content-type', 'application/octet-stream')
    return flask.Response(content, status=status_code, mimetype=content_type)

def get_args_config():
    parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--host', default=config['host'], help=
        'The host the server will bind to. Use 0.0.0.0 for all interfaces.')
    parser.add_argument('--port', type=int, default=config['port'], help=
        'The port the server will bind to.')
    parser.add_argument('--width', type=int, default=config['width'], help=
        'Number of elements used from left to right.')
    parser.add_argument('--height', type=int, default=config['height'], help=
        'Number of elements used from top to bottom.')
    parser.add_argument('--blur', type=int, default=config['blur'], help=
        'Pixels used in the gaussian blur.')
    parser.add_argument('--no-censor', action='store_true', help=
        'Disables gaussian blur.')
    parser.add_argument('--no-colors', action='store_true', help=
        'Disables hue rotation.')
    return vars(parser.parse_args())

def make_socket():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind((config['host'], config['port']))
    sock.listen(5)
    return sock

def start_wsgi_server():
    sock = make_socket()
    server = gevent.pywsgi.WSGIServer(sock, app)
    server.serve_forever()

if __name__ == '__main__':
    try:
        config = get_args_config()
        print('Listening on http://{}:{}'.format(config['host'], config['port']))
        start_wsgi_server()
    except Exception as e:
        print(repr(e))
        print('Press enter to exit')
        _ = input()
