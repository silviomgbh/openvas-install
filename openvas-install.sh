#!/bin/bash

# Script para instalação do OpenVAS (Greenbone Vulnerability Scanner)
# Testado em Ubuntu 22.04 / Debian 11

set -e  # Sai ao primeiro erro

echo "🟢 Iniciando instalação do OpenVAS..."

# Atualiza sistema e instala dependências básicas
apt update && apt upgrade -y
apt install -y cmake g++ libglib2.0-dev libgnutls28-dev \
  libpcap-dev libgpgme-dev libksba-dev libldap2-dev \
  libnet1-dev libssh-gcrypt-dev libhiredis-dev \
  libxml2-dev libmicrohttpd-dev libxml2-utils libxslt1-dev \
  uuid-dev curl git pkg-config libpaho-mqtt-dev \
  libical-dev python3 python3-pip python3-setuptools \
  python3-packaging python3-lxml \
  gcc libsqlite3-dev libical-dev libpaho-mqtt-dev \
  nmap redis-server postgresql postgresql-contrib

# Cria pasta padrão
mkdir -p /opt/openvas-src
cd /opt/openvas-src

# Clona repositórios Greenbone
echo "🔽 Clonando repositórios..."
git clone https://github.com/greenbone/gvm-libs.git
git clone https://github.com/greenbone/openvas-scanner.git
git clone https://github.com/greenbone/gvmd.git
git clone https://github.com/greenbone/gsad.git

# Compila gvm-libs
echo "🔧 Compilando gvm-libs..."
cd gvm-libs
mkdir build && cd build
cmake ..
make -j$(nproc)
make install
ldconfig

# Compila openvas-scanner
echo "🔧 Compilando openvas-scanner..."
cd /opt/openvas-src/openvas-scanner
mkdir build && cd build
cmake ..
make -j$(nproc)
make install
ldconfig

# Compila gvmd
echo "🔧 Compilando gvmd..."
cd /opt/openvas-src/gvmd
mkdir build && cd build
cmake ..
make -j$(nproc)
make install
ldconfig

# Compila GSAD (Greenbone Security Assistant - Web)
echo "🔧 Compilando GSAD..."
cd /opt/openvas-src/gsad
mkdir build && cd build
cmake ..
make -j$(nproc)
make install
ldconfig

# Cria usuário de banco
echo "🔐 Configurando PostgreSQL..."
sudo -u postgres createuser --createdb --no-createrole --no-superuser gvm || true
sudo -u postgres createdb -O gvm gvmd || true

# Ajusta permissões
gvmd --create-user=admin --password=admin123

# Sincroniza feeds
echo "🔄 Sincronizando feeds..."
greenbone-nvt-sync
greenbone-feed-sync --type GVMD_DATA
greenbone-feed-sync --type SCAP
greenbone-feed-sync --type CERT

# Inicializa serviços
echo "🚀 Iniciando serviços..."
redis-server &
gvmd &
openvas &
gsad --http-only --listen=0.0.0.0 --port=9392 &

echo "✅ OpenVAS instalado!"
echo "Acesse: http://<IP>:9392 com login: admin / senha: admin123"
