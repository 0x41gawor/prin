# OSPF Hello

```python
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
```

W tym miejscu w `send_hello` damy jako payload bajty przygotowane przez scapy jako pakiet OSPF.

