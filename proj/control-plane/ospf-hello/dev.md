# Projekt - development

## Uruchomienie sieci
```sh
sudo python3 1sw_demo.py --behavioral-exe /usr/bin/simple_switch_grpc --json out/struthio.json
```

## Uruchomienie controllera
```sh
python3 sebae.py
```

## PacketOut Test
### Nasłuchiwanie na porcie 2 switcha
Sebae okresowo wysyła OSPF Hello, więc wystarczy tylko nasłuchiwanie włączyć i po jakimś czasie sobie wyłączyć i pooglądać.
```sh
sudo tcpdump -i s1-eth2 -w capture.pcap -v
```