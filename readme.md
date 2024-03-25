# Lab 3
## Poczynione kroki
### 1. Przygotowanie
- Instalacja kompilatora P4
- Instalacja swticha bmv2
- Instalcja Mininet

- zapoznanie się z plikiem [1sw_demo.py](1sw_demo.py)
- kompilacja [template.p4](template.p4) (aby otrzymac plik json)
```sh
p4c --target bmv2 --arch v1model template.p4
```
- odnalezienie pliku binarnego switcha bmv2 `/usr/bin/simple_switch`
- uruchomienie `1sw_demo.md` z odpowiednimi argumentami
```sh
sudo python3 1sw_demo.py --behavioral-exe=/usr/bin/simple_switch --json template.json
```
Skrypt ten uruchomia Mininet CLI i w nim mozna wykonać debugging (ale jeszcze nie wiem jak). Ping test między hostami nie działa, tak jak oczekiwano.

Note: Na wszelki wypadek nalezy wykonać
```sh
sudo mn -c
```
### 2. Development programu P4
Zadania z instrukcji podzieliłem następująco:
- Przekazywania pakietów między interfejsami -->    **Zad1**
- Dodawania lub usuwania tagu VLAN           -->    **Zad2**
#### Zad 1
Switch ma dwa interfejsy `eth1` i `eth2`.

W topologii są jedynie dwa hosty, switch ma tylko dwa interfejsy dlatego najprostszym rozwiązaniem bedzie zaprogramowanie tak switcha, aby pakiety z `eth1` były przekazywane na `eth2` i na odwrót.

```p4
/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) 
{
	apply 
	{
		if (standard_metadata.ingress_port == 1) {
            standard_metadata.egress_spec = 2; // Forward from eth1 to eth2
        } else if (standard_metadata.ingress_port == 2) {
            standard_metadata.egress_spec = 1; // Forward from eth2 to eth1
        }
	}
}
```

Jednakże to proste rozwiązanie nie jest w żaden sposób skalowane, posłużyło jedynie jako test środowiska developerskiego.
```sh
p4c --target bmv2 --arch v1model zad1.p4
```

```sh
sudo python3 1sw_demo.py --behavioral-exe=/usr/bin/simple_switch --json zad1.json
```

Bardziej ogólne rozwiązanie tzn. takie, które pozwala, aby w topologii sieci było więcej niż dwa hosty korzysta z tablic.

Tablice pozwolą na to, aby zapisywać w nich mapowania, mówiące o tym na który interfejs wyjściowy kierowac pakiet, gdy wejdzie na dany port wejściowy. 


Względem [template.p4](template.p4) należy zmodyfikować jedynie blok `MyIngress`.
```p4
control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) 
{
	// zdefiniowanie akcji, ktora ustawia port wyjsciowy na taki jaki jest na wejsciu akcji
	action set_output_interface(bit<9> out_port) {
 		standard_metadata.egress_spec = out_port;
	}
	// ta tablea "mapuje interfejsy/porty" - stąd jej nazwa
	// kluczem do przeszukiwania wpisów jest port wejściowy, dopasowanie ma byc typu 'exact'(identyczne)
	// akcje to albo set_output_interface zdefiniowane wyzej, albo brak akcji w przypadku braku dopasowania
	// rozmiar to 256 wspisów, tyle ile 1 bajt pozwala
	table interface_mapper {
		key = {
			standard_metadata.ingress_port: exact;
		}
		actions = {
			set_output_interface;
			NoAction;
		}
		size = 256; // Correctly specify the size outside of the actions block
	}

	apply 
	{	
		interface_mapper.apply();
	}
}
```

Nasŧepnie uruchomic CLI do control plane switcha i dodac odpowiedni wpisy do tabeli:
```sh
python3 runtime_CLI.py --thrift-port 9090
RuntimeCmd> table_add interface_mapper set_output_interface 1 => 2
RuntimeCmd> table_add interface_mapper set_output_interface 2 => 1
```

W Mininet ping juz wtedy działa:
