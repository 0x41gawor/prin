## Tabela dopasowanie ternary
& - to iloczyn bitowy
W taki sposób wiele wpisów może pasować do pakietu, więc wybierany jest ten o najwyzszym priorytecie. Więc warto dodawać wpisy z roznymi priorytetami.

## counter i direct_counter
Pod indexami masz różne countery.

Pod spodem jest tablica jak w C i funkcje cnt.instance.count(index) robi po prostu tab[index]++

Direct_counter mozna wywolac tylko w akcji (no bo jest).

Definicja countera jest w bloku Ingress/Egress przed blokiem apply.

Dodefiniuj sobie stala V1MODEL >= 20200408

Program P4 nie jest w stanie sam zapisac do Countera jakies wartosci, on moze tylko ją iterowac o jedną.

Programem z control plane mozesz jedynie odczytac te wartosc.

Czyli na poziomie bitowy to moze albo odczytac bity albo zwiekszyc wartosc reprezentowana o 1.
## verify_checksum

to tez jest taki obiekt (extern??) 

Jesli suma sie nie bedzie zgadac to on ustawia w standard_metadata bit na 0 gdzie trzeba

data - lista pól, który jest sprawdzana
algo - uzywany algorym, defaultowo jest to csum16

W linku masz jak to uzyć, gotowiec trochę z tego jest.

## Update checksum
W ingress egress tego nie wywolasz
inout 0 checksum - to jest pointer do pola gdzie wpisac wartosc sumy kontrolnej
bool condition to jest warunek pod jakim pakiet ma miec to wykonywane

## Jak zapisywac liczby 2 P4

Ta skladania pozwala Ci okreslic na ilu bitach ma byc zapisana dana liczba
`[Nw]L`

Tak, jest tam `w`.

Dla czytelnosci mozesz uzyc znak `_`, on jest ignored przed compiler.


## Przetwarzanie pakietu po bloku ingress
Po kazdym bloku pakiet jest troche niejawnie przetwarzany przez switch. </br>
Jest coś pomiędzy.

Po bloku ingress, mogą stać się 6 akcji, z czego dwie niezależne, a ostatnie 4 rozlaczne.

Jesli my kazalimsy go klonowac to zadzieje sie klonowanie
Jesli my w Ingress kazalismy digest to stanie sie to
a potem moze byc jedno z 4:
- resubmit (pojdzie jeszcze raz na ingress)
- drop
- multicast na jakies porty
- unicast na jakis port
## Przetwarzanie po bloku egress
Anal jak po ingress czytaj slajd. 

Recyrkulacja pakietu - fajny nazwa.



