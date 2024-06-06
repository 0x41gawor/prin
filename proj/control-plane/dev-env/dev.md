# Projekt - development
## Kompilacja:
```sh
p4c --target bmv2 --arch v1model --p4runtime-files p4info.txt -o out/ struthio.p4
```
## Uruchomienie sieci
```sh
sudo python3 1sw_demo.py --behavioral-exe /usr/bin/simple_switch_grpc --json out/struthio.json
```

## Uruchomienie controllera
```sh
python3 sebae
```

## PacketIn Test
### wysłanie z h1 pakietu do switcha
```sh
h1 python3 test_packet_in.py
```

Sterownik powinien zobaczyc to jakos PacketIn.

## PacketOut Test
### Nasłuchiwanie na porcie 2 switcha
Sebae okresowo wysyła OSPF Hello, więc wystarczy tylko nasłuchiwanie włączyć i po jakimś czasie sobie wyłączyć i pooglądać.
```sh
sudo tcpdump -i s1-eth2 -w capture.pcap -v
```