# Projekt - development
## Kompilacja:
```sh
p4c --target bmv2 --arch v1model --p4runtime-files p4info.txt -o out/ struthio.p4
```

## PacketIn Test

### Uruchomienie sieci:
```sh
sudo python3 1sw_demo.py --behavioral-exe /usr/bin/simple_switch_grpc --json out/struthio.json
```

### Włączenie nasłuchiwania w control plane
```sh
python3 -m p4runtime_sh --grpc-addr localhost:9559 --device-id 0 --election-id 0,1 --config p4info.txt,out/struthio.json

for msg in packet_in.sniff(timeout=5):
  print(msg)

packet_in.sniff(lambda m: print(m), timeout=5)
```

### wysłanie z h1 pakietu do switcha
```sh
h1 python3 test_packet_in.py
```

## PacketOut Test

