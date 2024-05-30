# CPU Port

## Intro / Wyjaśnienie

W sieciach SDN switch P4 oraz sterownik komunikują się za pomocą protkołu warstwy sterowania. Pierwotnym jest Openflow. My w Projekcie używamy P4Runtime.

Podstawowymi wiadomościami w tymże protokole są Packet_In oraz Packet_Out. Postfixy In/Out są z punktu widzenia sterownika.

Switch do sterownika wysyła wiadomość **Packet_In** mówiąc mu "Zobacz, przyszedł do mnie taki pakiet, (co z nim zrobić?)"*

Sterownik do swtich'a wysyła wiadomość **Packet_Out** mówiąc mu "Masz, niech takowy pakiet opuści jeden z Twoich portów".


>*Sterwonik nie odpowiada na to pytanie w bezpośredniej odpowiedzi - nie ma żadnego Packet_In_Reply, to logika/kod sterownika musi assure że potem sterownik pokieruje odpowiednio switch'em.

## Wymagania

Mamy więc dwa scenariusze:

### Switch wysyła Packet_In

Do switcha przychodzi jakiś pakiet, który wedle jakiejś reguły switch decyduje wysłać do sterownika. U nas tą regułą jest, to że "oddajemy" sterownikowi pakiety OSPF. No, bo OSPF to protokół watstwy sterowania. Zobaczmy flow na rysunku.
![](img/1.png)

Czyli swtich mówi do sterownika "Zobacz, przyszedł do mnie taki pakiet na taki port".

Jak powiedzieć switchowi że TEN pakiet ma wysłać do sterownika? To jest proste w P4. Wystarczy ustawić mu `egress_spec` na specjalny numer portu. My w projekcie używamy 510. To nie jest ogólna konwencja i to się ustawia uruchamiając switch.

### Sterownika wysyła Packet_Out

Sterownik sobie wymyśla jakiś pakiet X i mówi do switch'a "Wyślij to portem y". 

![](img/2.png)

## Kod
### Packet_In
Trzeba wykryć że pakiet ma iść do control plane.

Ale najpierw defka headerów pakietów protokołu P4 Runtime:

```p4
@controller_header("packet_out")
header packet_out_header_t {
    bit<16> egress_port;
}

@controller_header("packet_in")
header packet_in_header_t {
    bit<16> ingress_port;
}
```

Teraz zdefiniowanie akcji wysyłania PacketIn do controllera.
```p4
 action send_Packet_In_to_controller() {
        standard_metadata.egress_spec = CPU_PORT;
        hdr.packet_in.ingress_port = (bit<16>)standard_metadata.ingress_port;
        hdr.packet_in.isValid();
    }
```

No i dodanie jej wywołania w logice Ingressu.
```p4
/   / Is this IP packet?
        if (hdr.ethernet.etherType == 0x0800) {
            // Check if ttl is less than 2
            if (hdr.ip.ttl < 2) {
                NoAction();
            }
            else {
                // Check if this packet belongs to some multicast group 
                // (if it does, copy and forward it to specific ports and go directly to egress block)
                tbl_mcast_group.apply();
                // Check if this packet is an OSPF packet
                if (hdr.ip.protocol == OSPF_NUM) {
                    // If it does, send it in Packet_In message to controller
                    send_Packet_In_to_controller();
                }
                // Check the next hop ip address for this packet (based on its ip.dst_addr)
                tbl_ip_routing.apply();
                // Set egress_port for this packet (based on next hop from previous step)
                tbl_ip_forwarding.apply();
            }
        }
```