<h1 align="center">Python sebae</h1>

<p align="center">
  <img src="img/logo.png"/>
  <br>
  <i>Controller handling OSPF</i>
  <br>
</p>

## Stuktura tego katalogu

- [dev-env](dev-env/)
    - Pierwsz krok to przygotowanie środowiska do developowania projektu. Nasz sterownik będzie handlował wiadomości OSPF wysyłane do niego niebezpośrednio, tylko poprzez PacketIn, podobnie z wysyłaniem (poprzez PacketOut). Także cała komunikacja będzie odbywać się za pomocą switcha. Także na początek należy stworzyć środowisko które będzie pozwalało na takowe pobudzanie sterownika. Dzieje to się w tym folderze.
- [ospf-hello](ospf-hello/)
    - Ten krok polega na rozkminieniu jak stworzyć wiadomość OSPF Hello w scapy, a następnie ją wysłać. Bazą kodu jest [dev-env](dev-env/). OSPF-Hello  jest wysyłane co HELLO_INTERVAL sekund przez sterownik. Wystarczy zaobserwować te pakity w tcpdump.
- [handler](handler/)
    - Ten krok polega na zaimplementowaniu pierwszego kroku handlera. Tzn wątek sniffer jest w stanie wykryć PacketIn i rozpocząć nowy worker thread typu `handler`. Handler będzie obsługiwał pakiety OSPF: Hello i LSU zmieniając jakoś wewnętrzny struktury danych. Pierwszy krok polega na obsłudze wiadomości OSPF-Hello.

  
