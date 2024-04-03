from mininet.topo import Topo
from mininet.net import Mininet
from mininet.util import dumpNodeConnections
from mininet.log import setLogLevel
from mininet.node import Controller, RemoteController
from mininet.cli import CLI
from mininet.link import TCLink

class CustomTopology(Topo):
    def build(self):
        # Add hosts and switches
        h1 = self.addHost('h1')
        h2 = self.addHost('h2')
        s1 = self.addSwitch('s1')
        s2 = self.addSwitch('s2')
        s3 = self.addSwitch('s3')
        s4 = self.addSwitch('s4')
        s5 = self.addSwitch('s5')
        
        # Add links with the respective delays
        self.addLink(h1, s1, delay='5ms')
        self.addLink(s1, s2, delay='2ms')
        self.addLink(s1, s3, delay='5ms')
        self.addLink(s1, s4, delay='5ms')
        self.addLink(s2, s3, delay='10ms')
        self.addLink(s3, s4, delay='5ms')
        self.addLink(s4, s5, delay='5ms')
        self.addLink(s2, s5, delay='3ms')
        self.addLink(s3, s5, delay='5ms')
        self.addLink(h2, s5, delay='5ms')

def runCustomTopo():
    # Create and start the network
    topo = CustomTopology()
    net = Mininet(topo=topo, link=TCLink, controller=lambda name: RemoteController(name, ip='127.0.0.1'))
    net.start()
    
    # Dump host connections
    dumpNodeConnections(net.hosts)
    
    # Start CLI
    CLI(net)
    
    # Stop the network
    net.stop()

# This is to avoid running the topology if this script is imported elsewhere
if __name__ == '__main__':
    # Tell mininet to print useful information
    setLogLevel('info')
    runCustomTopo()


