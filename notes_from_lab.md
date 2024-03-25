simple switch CLI to gada do switch protokołem OpenFlow

Bmv2 to switch który mozna uruchomić w Mininet.

Skrypt Mininet jest 
YOUR_CAPS_FUNCTIONALITY_HEREYOUR_CAPS_FUNCTIONALITY_HEREYOUR_CAPS_FUNCTIONALITY_HERE
```
switch = self.addSwtich("name", sw_path=..., json_path=..)
```
sw_path to sciezka do binarki ze switchem powinno byc /usr/local/bin/simple_switch
json_path to sciezka do Twojego softa zrobionego z P4.

Trift port to 9090.fdsfsaffd

Pobierz oba skrypty ze slajdu 

jak juz uruchomisz siec, to mozesz uzyc runtime_CLI
table_add
table_set_default
table_delete

To jest protokół Trift.

YOUR_CAPS_FUNCTIONALITY_HEREYOUR_CAPS_FUNCTIONALITY_HEREYOUR_CAPS_FUNCTIONALITY_HEREYOUR_CAPS_FUNCTIONALITY_HERE
v1model - szkielet programu P4

#include<core.p4> - defka podstawowych obiektów
#include<v1model.p4> - model switcha, który będzie używany

header czym sie rozni od struct
header ma niejawne jedno pole validity bool bit, który mówi czy dane w instancji obiektu tego headera są poprawne

Typy danych są.

uzywaj bit<N>, nie uzywaj int w header, error (to chyba enum na errory z Parsera) no i typedef mozesz sobie uzywac.


Bloki kontrolne trzeba wprost powiedziec kompilatorowi co jest co.

# tabele
    fdsgsddfdsfdsgfdsfdsgfgsssfdsgsd
dzisiaj nie ma potzeby uzywania action profile albo action selection

i w jakims bloku kontrolnym mozna wywolac tabele
afdsafsaada

## klucze
na slajdzie kox
epression to moze byc pole naglowka np. adres docelowy ip, adres mac, dowolne wyrazenia co zwracaja wartosc, moga byc tez operatory matematyczne/bitowe  
match_kind - exact, range, itd
annotation A

## akcjefdasfasfsafsfsdfnfdsu
Tutoriale P4:


# Jak zaczac

musisz miec zainstalowany mininet
oraz te dwie rzeczy z warsztat 2

[Ten plik](https://github.com/p4lang/behavioral-model/blob/main/mininet/p4_mininet.py) to libka. 
[Ten plik](https://github.com/p4lang/behavioral-model/blob/main/mininet/1sw_demo.py) to skrypt python, ktory uruchamia mininet ktory ma topologia 1sw (czyli topologia 1 switch + ileś hostów (domyślnie są dwa)). Uzywany switch w tej topologii to nie jest jakiś ovs czy cos, tylko wlasnie [bmv2](https://github.com/p4lang/behavioral-model). No i w tym skrypcie jako parametr podajesz sciezke do jsona, który jest binarka na "hardware" tego switcha. Jak otrzymać tego json'a? napisać kod w języku P4 skompliować.
Producenci switchy udostępniaja API do ich hardware, a ten json to opisuje dzialanie switcha na wlasnie tym API, a ten json to się otrzymuje po skompilowaniu kodu P4.

Czyli workflow wyglada tak:
- pisze się kod w P4
- kompiluje go z tego otrzeymuje sie json
- potem ten json wklada sie w switch
- no i switch jest zaprogramowany 

Twoje worklow wyglada tak:
- pobierasz plik 1sw_demo.py
- dajesz argument z Twoim plikiem json
- Twoj plik json to weź skompiluj ten kod co dal Palimaka
- w CLI minneta testujesz
- jak wszystko git to mozesz sie zabrac za deveopment P4