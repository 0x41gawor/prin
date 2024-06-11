# Projekt - development
## Uruchomienie sieci
```sh
sudo python3 1sw_demo.py --behavioral-exe /usr/bin/simple_switch_grpc --json out/struthio.json
```

## Uruchomienie controllera
```sh
python3 sebae/main.py
```

## PacketIn Test
Na terminalu mininet
```sh
h1 python3 test.py
```

To spowoduje wysłanie pakietu OSPF Hello z hosta h1 do switcha.

Switch przekazę go na CPU port i powinniśmy zobaczyć go w terminalu sterownika.

Uwaga:
To średnio działa. Czasem się ten pakiet pojawia czasem nie. Rób tak, że przez te pierwsze 5 sekund sniffera nawal jak najwięcej pakietów z hosta. Potem ten sniffer jakoś się zacina. Ogólnie zauważyłem, że jak nie uda Ci się w pierwszą iteracje to potem już nigdy. Do dupy to jest.
