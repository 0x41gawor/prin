# Development Environment Setup
## Prerequisities
Ubuntu OS:
```sh
ejek@brh-vm:~/prin$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.3 LTS
Release:        22.04
Codename:       jammy
ejek@brh-vm:~/prin$ 
```
## Steps
- Instalacja kompilatora P4
- Instalacja swticha bmv2
- Instalcja Mininet


## Instalacja kompilatora P4
https://github.com/p4lang/p4c?tab=readme-ov-file#ubuntu

```sh
. /etc/os-release
echo "deb http://download.opensuse.org/repositories/home:/p4lang/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/home:p4lang.list
curl -fsSL "https://download.opensuse.org/repositories/home:p4lang/xUbuntu_${VERSION_ID}/Release.key" | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_p4lang.gpg > /dev/null
sudo apt update
sudo apt install p4lang-bmv2
```
Test
```sh
p4c -h
```
## Instalacja switch bmv2
https://github.com/p4lang/behavioral-model?tab=readme-ov-file#ubuntu

```sh
sudo apt install p4lang-bmv2
```

## Instalacja Mininet
```sh
sudo apt update
sudo apt upgrade -y
sudo apt install mininet -y
sudo mn --test pingall
```

## Instalacja P4 Runtime
```sh
pip3 install --upgrade git+https://github.com/p4lang/p4runtime-shell.git#egg=p4runtime-shell
```
