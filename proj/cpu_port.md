# CPU PORT

Zanim zrobisz parser emit jakiś nagłówek to zrób najpierw ze ten nagłówek set valid


Jak sprawdzic czy to pakiet od controllera?
Check if packet out header is valid (nie ze if ingress_port=CPU_PORT)


# Mamy kod co działa, gdzie on jest?

`demo.py` - tu jest sieć mininet
`contr_test.py` - tam jest wpisana konfiguracja sieci (wpisy do tablic switcha jakie ma zrobic sterownik)
`packet_in.py` - tym wysylasz do switcha wiadomość packet_in
`p4_mininet` - są zmienione args.extend
Packet out testujesz tak ze uruchamiasz p4runtime shell i tam są komendy na dc jak to stestować. Pamiętaj ze pakiet musi być odpowiednio dłuuuuugi.