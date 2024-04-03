# Printer -  Simple IP router 
## Business reqs
### IP Router
#### Opis
**Routing**
User wpisuje do tabeli wpis:
- docelowy adres IP (adres hosta) (to jest kluczem przeszukiwania tabeli)
- na jaki port kierowac ten pakiet (czyli za pomoca, ktorego portu mamy osiagnac dany host docelowy) (to jest parametr akcji)
- adres MAC next-hopa, ktory ma zostac wpisany w pakiet w warstwie ETH (zeby next-hop go nie odrzucil na L2)
**TTL**
Dodatkowo pakiet IP ma mieć odczytywane pole TTL i odrzucane jesli jest ono mniejsze niz 2. 
**Checksum**
Dodatkowo aktualizowac ma sie suma kontrolna.
#### Reqs
- [ ] Routing
- [ ] TTL
- [ ] checksum
#### Co to implikuje
Sieć złożona z dwóch hostów oraz switcha. Wszystkie urządzenia mają mieć przypisane statyczne adresy IP oraz MAC. Trzeba to zdefiniować w [1sw_demo.py](1sw_demo.py).

**checksum**
Na poprzednich zajeciach nie musielismy tego robic bo nic nie zmienialismy w protokole IP. Hosty bedą odrzucać pakiety ze zła sumą kontrolną, więc od tego nalezy zacząć implementację.
#### Testy
**Routing**
Mozna wymyslec topologie oraz jakie wpisy dodac do tabeli zeby przetestowac ruting.
**TTL**
Po odpaleniu Mininet mozesz wejsc w jego iptables i dodac zeby wszystkie pakiety IP wysylal z TTL 1.
```sh
Mininet CLI> h1 iptables -t mangle -A POSTROUTING -j TTL --ttl-set 2
```
**checksum**
Jesli bedzie bledna to host odrzuci. 

### IP Filter
#### Opis
Use wpisuje do tabeli wpis, który reprezentuje trójkę, która identyfikuje pakiet jaki należy odrzucać. Ta trójka to:
- docelowy adres IP
- protokół warstwy transportowej
- port

np. `{10.0.0.1, TCP. 80}`

ale moze też być wildcard czyli np. `{10.0.0.1, TCP, *}` to tego będzie Ci potrzebny ten ternary operator.
#### Reqs
- [ ] Basic filter
- [ ] Wildcards
#### Co to implikuje 
Nic.
#### Testy
Przez mininet mozna wejsc na hosty przez xterm do ich shell'a i uzyc scapy. Na jednym uruchamia sie klient a na drugim serwer i mozna testowac connections TCP lub UDP.

> Note: scapy bedzie trzeba za kazdym razem instalowac podczas runtime. Albo mozesz zmodyfikowac skrypt [1sw_demo.py](1sw_demo.py)

Alternatywą dla scapy jest [nc](https://linux.die.net/man/1/nc).
**Basic filter**
Można wymyślec wpisy do tabeli i potem scapy'm generować ruch.
**Wildcards**
Po stronie Trift będzie to samo. Inne tylko testy na scapy.
### Stats
#### Opis
Router ma zbierac statystyki dotyczące ...(lista poniżej). User za pomocą Trift moze sobie je querować. Nie wiem jeszcze jakie komendy trift to robią.

**Jakie staty:**
- Dla każdego portu liczba pakietów
	- odebranych
	- przeslanych dalej
	- wyslnaych
- Dla całego switcha
	- liczba pakietów odrzuconych

Każdy port na warstwie fizycznej najniższej ma Receiver oraz Transceiver. Więc jak mówimy o porcie, to on w danej sytuacji (procesowania single pakietu) pełni rolę albo Tx albo Rx.
Pojęcia odebrać/wysłać pakiet są w odeniesiu do swtich - external world. Więc odebrać może tylko Rx. Wysłać tylko Tx. Pojęcie przesłać dalej jest w obrębie switcha, więc może to zrobić jedynie Rx.


### Topologia
![](img/1.png)

Tak nalezy zmodyfikować plik [1sw_demo.py](1sw_demo.py).

Na tym rysunku dodaj maske podsieci /24 do adresów IP bo to sugeruje maske 32 jak nie ma jej.
