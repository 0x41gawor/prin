# Projekt - development
## Kompilacja:
```sh
p4c --target bmv2 --arch v1model --p4runtime-files p4info.txt -o out/ struthio.p4
```

## Uruchomienie sieci:
```sh
sudo python3 1sw_demo.py --behavioral-exe /usr/bin/simple_switch_grpc --json out/struthio.json
```

## Inicjalizacja Control Plane (dodanie wpisów configuracyjnych)
``` sh
python3 controller.py
```

## Uruchomienie sterownika (runtime CLI)
```sh
python3 -m p4runtime_sh --grpc-addr localhost:9559 --device-id 0 --election-id 0,1 
python3 -m p4runtime_sh --grpc-addr localhost:9559 --device-id 0 --election-id 0,1 --config p4info.txt,out/struthio.json

for entry in table_entry["MyIngress.tbl_arp_lookup"].read():
    print(entry)

for entry in table_entry["MyIngress.tbl_mac_learn"].read():
    print(entry)

for entry in table_entry["MyIngress.tbl_ip_routing"].read():
    print(entry)

for entry in table_entry["MyIngress.tbl_ip_forwarding"].read():
    print(entry)

for entry in table_entry["MyEgress.tbl_mac_update"].read():
    print(entry)
```
## Podsłuchanie 
```sh
sudo tcpdump -i s1-eth1 -w capture.pcap -v
sudo tcpdump -i s1-eth2 -w capture.pcap -v
```