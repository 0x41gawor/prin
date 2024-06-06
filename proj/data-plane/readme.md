<h1 align="center">Struthio</h1>

<p align="center">
  <img src="mac_learning-poc/img/logo.png"/>
  <br>
  <i>Simple P4 switch with OSPF support</i>
  <br>
</p>

## Struktura tego katalogu

Wymagania na projekt są w [tym pdfie](Lab6projekt.pdf).

Zostały one podzielone na 4 części oraz zrealizowane jako oddzielne mini-projekty (ProofOfConcepts) w sposób iteracyjny (tzn. każdy następny projekt bazuje na kodzie poprzedniego).
- [arp-poc](arp-poc) - switch odpowiada na zapytania ARP
- [mac-learning-poc](mac_learning-poc) - switch uczy się podłączonych do siebie hostów (ich adresów mac oraz ip) i na tej podstawie robi forwarding
- [multicast-poc](multicast-poc) - swtich obsługuje grupy multicast
- [cpu_port-poc](cpu_port-poc) - swtich potrafi wymieniać wiadomości PacketIn/PacketOut ze sterownikiem poprzez port CPU.

Tym o to sposobem w [cpu_port-poc](cpu_port-poc) jest gotowy kod na projekt z data plane.