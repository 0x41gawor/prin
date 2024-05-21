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

Gdy przychodzi pakiet na Ingress to:
- najpierw patrzymy, czy znamy host nadawcy (mac learning), jeśli tak to idziemy dalej, jeśli nie to digest do control plane leci.
- patrzymy w tablice routingu i szukamy jaki jest next-hop dla pakietu tego, jeśli brak to dropujemy pakiet
- Na podstawie next-hop ustawiamy pakietowi egress_port
Pakiet leci na Eggress:
- Tutaj podmiana eth.src_mac i eth.dst_mac na podstawie egress_port

Flow ale z tablicami i akcjami

Ingress:
- Przychodzi pakiet, szukamy czy mamy w `tbl_mac_learn` jego eth.src_addr. Jeśli nie to wysyłamy digestem trójkę `{ingress_port, packet.eth.src_addr, packet.ip.src_addr}`.
-- Controller w tym momencie może do `tbl_mac_learn` dodać tę trójkę. 
-- Controller w tym momencie może do `tbl_ip_routing` dodać wpis, że gdy dst_addr jest taki (packet.ip.src_addr), to next-hop ustawić należy taki (packet.ip.src_addr)
-- Controller w tym momencie może do `tbl_forwarding` dodać wpis, że gdy next-hop jest taki, to mamy go na tym porcie
-- Controller w tym momencie może do `tbl_mac_update` dodać wpis, że na tym egress_port (ingress_port) w egress (przy wychodzeniu pakietu) trzeba podmieniać na:
    -  eth.src_mac - to z configu
    -  eth.dst_mac - to z trojki element packet.eth.src_addr
- Patrzymy w `tbl_routng`, kluczem jest packet.ip.dst_addr, a dostajemy next-hop
- Patrzymy w `tbl_ip_forwarding` kluczem jest next-hop, a dostajemy egress_port
- Ustawiamy pakietowi egress_port
Egress:
- Patrzymy `tbl_mac_update`, kluczem jest egress_port (port którym wyjdzie pakiet) a parametrem akcji updated_src_mac, updated_dst_mac, które zostaną odpwiednio wpisane do packet.eth.src_mac i packet.eth.dst_mac


Więc mamy tabele takie:
- `port_config` ona mówi o tym jakie porty mają przypisane ip_addr i mac_addr. Ona jest tylko w Control Plane, to jest pseudo tabela. Nie mam jej w P4. Nie jest querowana.
- `tbl_mac_learn` ona mowi o tym jakie znamy (my - switch) hosty. Host to trójka {port, eth_addr, ip_addr}, ale implementacyjnie będzie to tylko adres mac.
- `tbl_ip_routing` ona mowi o tym jaki jest next-hop na podstawie ip.dst_addr. Wpisy tutaj można dodawać też ręcznie z control plane (w przypadku sieci odległych).<br>
`key{dst: ip_addr}, match{next_hop: ip_addr}`
- `tbl_ip_forwarding` ona mówi o tym na jakim porcie wyjściowym mamy dany ip_addr hosta po drugiej stronie łącza <br>
`key{next_hop: ip_addr} match{egress_port: int}`
- `tbl_mac_update` ona mówi jak zupdateować adresy MAC w nagłówku eth, gdy pakiet wychodzi danym portem <br>
`key{egress_port: int} match{src_mac: eth_addr, dst_mac: eth_addr}`

