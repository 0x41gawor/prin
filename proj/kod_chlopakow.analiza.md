## Zdefiniowane headers
- ethernet
- ipv4
- tcp
- udp
## Zdefiniowane struct
```p4
struct learn_t {
    bit<48> srcMAC;
    bit<9>  ingress_port;
    bit<32> srcIP;
}
```

To pewnie bedzie gdzies wysylane. Digest? czy cos

## Zdefiniowane customowe metadane

```p4
struct metadata {
	routing_metadata_t routing;
	learn_t learn;
}
```
Routing metadata to `nhop_ipv4` typu adres IP, więc jest to metadana przekazywana z Ingress do Egress na temat next-hop.


## Parser
Parsuje Ethernet.
Jeśli ether_type wskazuje na IP, to IP.
Potem jeśli pakiet jest TCP lub UDP to też

## VerifyChecksum

Najpierw do obliczenia sumy kontrolnej idzie ipv4.

Potem jeśli pakiet jest TCP to też nagłówek tcp jest wliczany. UDP analogicznie.

## Ingress

## Akcje
### ipv4_forward()

Przyjmuje adres next-hop jako param.

Wpisuje ten next hop do metadanych pakietu oraz zmniejsza ttl.

### set_dmac()

Przyjmuje jako param:
- adres destination mac
- port wyjściowy

ustawia port wyjsiowy dla pakietu
oraz podmienia w eth dst_mac

Czyli wykorzystywane podczas forwardowania pakietu, tak zeby wyszlo odpowiednim portem oraz mialo dobry dst_mac (urządzenia po drugiej stronie łącza tego portu).

### mac_learn()

Wpisuje do struktury learn_t:
- ethernet src_mac
- port wejściowy
- ip src_ip

I wysyła ją digestem.

## Tabele

### smac
Kluczem tej tabeli jest ethernet src_mac a akcją mac_learn()

Czyli gdy przyjdzie pakiet, który ma eth.src_mac nieznany nam to się go uczymy.
I mamy w tabeli

| eth.src_mac | ingress_port | ip.src_addr

### routing_table

Kluczem jest ip.dst_addr

Akcją jest ip_forward()

Czyli klasyczny routing. 

W control plane mamy powiedziane jaki ip.dst_addr ma jaki next-hop.mac_addr

### switching table
Kluczem jest meta.routing.nhop_ipv4 czyli adres ustawiony w routing table().

Akcją jest set_dmac() czyli jak routing table na podstawie adresu ip.dst_addr powie nam jaki jest adres next-hop, to teraz ten adres next-hop jest kluczem i w tabeli odszukujemy dla niego na jaki port wyjściowy kierować pakiet oraz na jaki adres MAC podmienić eth.dst_mac.

### ip table
### tcp table
### udp table
Tu jak w tablicy mamy wpis danego portu to pakiet jest odrzucany.

# Egress
## Akcje
### set_smac()
Ustawia adres eth.src_mac na ten z parametru
## Tablice
### mac_rewriting_table()
Kluczem jest port wyjściowy pakietu, akcją set_mac()

Czyli mamy tablice, która mówi na jaki adres mac trzeba podmienić eth.src_mac w pakiecie, gdy wychodzi on danym portem.

# Flow Opisz całe flow.