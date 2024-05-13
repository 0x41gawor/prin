import p4runtime_sh.shell as sh

# How long in [s] controller will listen for digests.
# After that time, for loop will release thread and output can be shown
# Sniffing blocks the thread
# The script each TIMESOUT seconds will print digests that came in this time interval
TIMEOUT = 5

# Setup gRPC connection and configure P4Runtime
sh.setup(
    device_id=0,
    grpc_addr='localhost:9559',
    election_id=(0, 1),  # (high, low)
    config=sh.FwdPipeConfig('p4info.txt', 'out/template.json')
)

# Set up a digest entry
d = sh.DigestEntry('learn_digest_t')
d.ack_timeout_ns = 1000000000
d.max_timeout_ns = 1000000000
d.max_list_size = 100
d.insert()

print("Listening for digests...\n")

try:
    while True:
        try:
            for e in sh.DigestList().sniff(timeout=TIMEOUT):
                print("===========Incoming Digest============\n")
                print(e)
                print(type(repr(e.digest.data[0].struct.members[0].bitstring)))
                print(repr(e.digest.data[0].struct.members[0].bitstring))
                print(repr(e.digest.data[0].struct.members[1].bitstring))
        except KeyboardInterrupt:
                print("Interrupted by user, cleaning up...")
                sh.teardown() 
                print("Session closed gracefully.")
                exit()

        print("====Kolejna iteracja====")
except KeyboardInterrupt:
    print("Interrupted by user, cleaning up...")
    sh.teardown() 
    print("Session closed gracefully.")
    exit()

print("Listening for digests ended")
sh.teardown()
