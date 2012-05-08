import gevent
import gevent.monkey
gevent.monkey.patch_all()
import gevent_zeromq
gevent_zeromq.monkey_patch()
import zmq

from gevent.queue import Queue
from gevent.pywsgi import WSGIServer

from app import app
import views
import time

import continuumweb.webzmqproxy as webzmqproxy
pubsub = "inproc://apppub"
pushpull = "inproc://apppull"

def prepare_app(reqrepaddr, ctx=None):
    app.debug = True
    app.proxy = webzmqproxy.Proxy(reqrepaddr, pushpull, pubsub, ctx=ctx)
    app.proxy.start()
    app.proxyclient = webzmqproxy.ProxyClient(pushpull, pubsub, ctx=ctx)
    app.proxyclient.start()
    app.rpcclient = webzmqproxy.ProxyRPCClient(app.proxyclient)
    return app

def start_app():
    http_server = WSGIServer(('', 5000), app)
    http_server.serve_forever()

def shutdown_app():
    print 'shutting down app!'
    app.proxy.kill = True
    app.proxyclient.kill = True
    
if __name__ == "__main__":
    import sys
    reqrepaddr = sys.argv[1]
    import logging
    logging.basicConfig(level=logging.DEBUG)
    prepare_app(reqrepaddr)
    start_app()
