<h1 align="center">Python sebae</h1>

<p align="center">
  <img src="img/logo.png"/>
  <br>
  <i>Controller handling OSPF</i>
  <br>
</p>

## Stuktura tego katalogu

- [dev-env](dev-env)
    - Pierwsz krok to przygotowanie środowiska do developowania projektu. Nasz sterownik będzie handlował wiadomości OSPF wysyłane do niego niebezpośrednio, tylko poprzez PacketIn, podobnie z wysyłaniem (poprzez PacketOut). Także cała komunikacja będzie odbywać się za pomocą switcha. Także na początek należy stworzyć środowisko które będzie pozwalało na takowe pobudzanie sterownika. Dzieje to się w tym folderze.