import threading
import p4runtime_sh.shell as sh

from handler import HandlerThread

# Thread of this class sniffs for PacketIn
class SnifferThread(threading.Thread):
    def run(self):
        print("SnifferThread: started...")
        while True:
            for msg in sh.PacketIn().sniff(timeout=5):
                print(f"SnifferThread: PacketIn received")
                handler_thread = HandlerThread(msg.packet)
                handler_thread.start()