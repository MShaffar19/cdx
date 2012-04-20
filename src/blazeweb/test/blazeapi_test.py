import gevent
import gevent.monkey
gevent.monkey.patch_all()
import gevent_zeromq
gevent_zeromq.monkey_patch()
import zmq

import unittest
import simplejson
import numpy as np
import logging
import time
import os
import shelve
import requests

import continuumweb.webzmqproxy as webzmqproxy
import continuumweb.test.test_utils as test_utils
import rpc
import rpc.client
import rpc.server
import arrayserver_app as arrayserver
import blazenode
import blazeconfig
import blazeweb.start as start

logging.basicConfig(level=logging.DEBUG)
log = logging.getLogger(__name__)
logging.debug("starting")

backaddr = "inproc://#1"
frontaddr = "inproc://#2"
addr = "inproc://#3"
baseurl = "http://localhost:5000/data/"    

class BlazeApiTestCase(unittest.TestCase):
    def tearDown(self):
        if hasattr(self, 'rpcserver'):
            self.rpcserver.kill = True
        if hasattr(self, 'broker'):
            self.broker.kill = True
        if hasattr(self, 'rpcserver'):
            test_utils.wait_until(lambda : self.rpcserver.socket.closed)
            print 'rpcserver closed!'
        if hasattr(self, 'broker'):
            def done():
                return self.broker.frontend.closed and self.broker.backend.closed
            test_utils.wait_until(done)
            print 'broker closed!'            
        #we need this to wait for sockets to close, really annoying
        time.sleep(1.0)
        start.shutdown_app()
        self.servert.kill()

    def test_connect(self):
        testroot = os.path.abspath(os.path.dirname(__file__))
        hdfpath = os.path.join(testroot, 'gold.hdf5')
        config = blazeconfig.BlazeConfig(blazeconfig.InMemoryMap(),
                                         blazeconfig.InMemoryMap())
        blazeconfig.generate_config_hdf5('myserver', '/hugodata',
                                         hdfpath, config)
        broker = arrayserver.Broker(frontaddr, backaddr)
        broker.start()
        self.broker = broker
        rpcserver = blazenode.BlazeNode(backaddr, 'TEST', config)
        rpcserver.start()
        self.rpcserver = rpcserver
        test_utils.wait_until(lambda : len(broker.nodes) > 0)
        start.prepare_app(frontaddr)
        self.servert = gevent.spawn(start.start_app)
        time.sleep(0.5)

        s = requests.session()
        result = s.get(
            baseurl + "hugodata/20100217/names",
            timeout = 1.0
            )
        result = simplejson.loads(result.content)
        assert result == ["GDX", "GLD", "USO"]


if __name__ == "__main__":
    unittest.main()
    
