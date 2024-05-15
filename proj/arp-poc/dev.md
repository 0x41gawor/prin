# Projekt - development
## Kompilacja:
```sh
p4c --target bmv2 --arch v1model --p4runtime-files p4info.txt -o out/ arp-responser.p4
```

## Uruchomienie sieci:


## Uruchomienie sterownika (runtime CLI)
```sh
python3 -m p4runtime_sh --grpc-addr localhost:9559 --device-id 0 --election-id 0,1 --config p4info.txt,out/arp-responser.json
```

## Dodanie wpisów
```sh
te = table_entry["MyIngress.arp_lookup"](action="send_arp_reply")
te.match['standard_metadata.ingress_port'] = '1'
te.match['hdr.arp.tpa'] = '10.0.0.3'
te.action['target_mac'] = '00:00:00:04:00:AA'
te.insert()

te = table_entry["MyIngress.arp_lookup"](action="send_arp_reply")
te.match['standard_metadata.ingress_port'] = '2'
te.match['hdr.arp.tpa'] = '10.0.0.4'
te.action['target_mac'] = '00:00:00:04:00:BB'
te.insert()

for entry in table_entry["MyIngress.arp_lookup"].read():
    print(entry)
```

## Podsłuchanie 
```sh
sudo tcpdump -i s1-eth1 -w capture.pcap -v
sudo tcpdump -i s1-eth2 -w capture.pcap -v
```