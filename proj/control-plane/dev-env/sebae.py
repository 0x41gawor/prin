import threading
import time
import p4runtime_sh.shell as sh

# Initialize the P4Runtime shell
sh.setup(
    device_id=0,
    grpc_addr='localhost:9559',
    election_id=(0, 1),
)

# Thread of this class sniffs for PacketIn
class SnifferThread(threading.Thread):
    def run(self):
        print("Sniffer thread started started!\n")
        while True:
            for msg in sh.PacketIn().sniff(timeout=5):
                print(f"SnifferThread: PacketIn received: {msg.packet.payload} \n")

# Thread of this class sends OSPF Hello message every HELLO_INT seconds
class HelloSenderThread(threading.Thread):
    def run(self):
        while True:
            self.send_hello()
            time.sleep(2)

    def send_hello(self):
        p = sh.PacketOut(payload=b'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBC', egress_port='2')
        p.send()
        print("HelloSenderThread: Message sent \n")

if __name__ == "__main__":

    sniffer_thread = SnifferThread()
    sniffer_thread.start()

    hello_sender_thread = HelloSenderThread()
    hello_sender_thread.start()

    sniffer_thread.join()
    hello_sender_thread.join()

    sh.teardown()