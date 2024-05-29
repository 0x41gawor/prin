# OSPF

## Nagłówek OSPF

version zawsze 2
Type - 1 lub 4
Packet Lenght - długość pokietu od pola version az do włączni z payload.
Router ID i Area ID sobie przypomnij.

Nie robimy żadnej autentykacji, więc AuType daj 0, a authenticaion nie ma znaczenia co tam jest daj same `1` np.

Walidacja nagłówka przychodzących wiadomości OSPF.
Wersja 2
Suma kontrol - sprawdź checksum
ID obszaru - taki jak wpisany
AuType ma być 0
Inny odrzuć

## Wiadomość Hello

Wiadomość Hello nie podlega ani routingowi ani forwardingowi. 

Na hello nie ma odpowiedzi, po prostu sąsiad krzyczy "elo jestem" i nie trzeba mu odpowiadać.

Controller wysyła cyklicznie (co HelloInterval = 30s) do switch'a Packet_OUT z wiadomością OSPF:Hello, controller musi mieć dedykowany wątek do tego.

Ten dedykowany wątek to niech wysyła Hello, potem uśpienie na 30s i znowu w pętli tak
Oddzielny wątek to obsługa digest.
A kolejny to obsługa odbierania wiadomości OSPF.

### Obieranie 
W controllerze trzymasz liste sąsiadów. I trasy do nich.

Hello zawiera dwa dodatkowe pola w nagłówku.

Waliduj czy HelloInt od sąsiada jest taki sam jak Twój.

## 
Pola od Options to nie używaj, ustawiaj na 0.

## Wiadomość LSU

Numer sekwencyjny to id rozgłoszenia LSU, więc dzieki temu router, który (przez pętle rutingowe) dostanie jeszcze raz LSU o takim samym seq_num, to wie, że to już procesował.

Pole Router ID nie ulega zmianie więc po tym wiadomo kto był pierwotnym nadawcą LSU.

Algorytm

1. Sprawdzasz router ID if Twoje to reject
2. Sprawdzasz seq_num w scope tego router ID to reject
3. Robisz Dijkstre 
4. Rozsyłanie. Tu obsługa TTL itd. ale to imo data plane robi. W control plane tylko TTL z OSPF.

### Nagłówek
Scap. Uwaga ten nagłówek jest customowy na potrzeby zajęć.

#### LSA
Link State Advertisment ma 3 4-ro bajtowe pola. Mówi on 

### Przykład tras
Gateway nie jest w OSPF, nie bierze udziału w OSPF, więc tam Router ID dajemy 0.

Dzięki tym wiadomością wiadomo, kto jest z kim połączony i jak między nimi jest sieć.

I dzięki temu jak jakiś router ma wysłać coś do podsieci jakiejś to wie do jakiego routera tam.

Jak ktoś rozglosi ze ma podsieci 0.0.0.0 z Router ID 0 to on ma tam internet cały.

## Akutlizacja tras
Listę tras do danego routera, posortuj według liczby hopów. No bo jeśli router A i B rozgłasza tę samą podsieć to router C musi zadecydować na który rutować.

## Parametry
my mamy 14

# Ocenianie projektu

Testem jest dogadanie się sama ze sobą.