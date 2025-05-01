#!/bin/bash

# Variables iniciales
DNS_PATH="/docker/dns"
CURRENT_DIR=$(pwd)
EMAIL="${EMAIL:-admin@example.com}"
DEPENDENCIES=(docker docker-compose dig certbot)
DNS_SERVERS=("1.1.1.1" "8.8.8.8" "9.9.9.9")

# Validar argumentos
if [[ -z "$1" ]]; then
  echo "Error: Debes pasar el dominio como argumento."
  echo "Uso: $0 dominio.com"
  exit 1
fi

DOMAIN="$1"
ZONE_FILE="${DNS_PATH}/zones/db.${DOMAIN}"
CERT_DIR="./certs_${DOMAIN}"

# Verificar si el script es root o tiene sudo
if ! command -v sudo >/dev/null && [[ $EUID -ne 0 ]]; then
  echo "Error: Necesitás ser root o tener sudo instalado para instalar dependencias."
  exit 1
fi

# Verificar dependencias
for dep in "${DEPENDENCIES[@]}"; do
  if ! command -v "$dep" >/dev/null; then
    echo "$dep no está instalado. Instalando..."
    if command -v apt-get >/dev/null; then
      sudo apt-get update && sudo apt-get install -y "$dep"
    elif command -v dnf >/dev/null; then
      sudo dnf install -y "$dep"
    elif command -v pacman >/dev/null; then
      sudo pacman -Sy --noconfirm "$dep"
    elif command -v zypper >/dev/null; then
      sudo zypper install -y "$dep"
    else
      echo "No se detectó un gestor de paquetes compatible."
      exit 1
    fi
  fi
done

# Validar que el contenedor DNS esté corriendo
cd "$DNS_PATH"
if ! docker-compose ps | grep -q "Up"; then
  echo "Error: El contenedor de DNS no está corriendo."
  exit 1
fi
cd "$CURRENT_DIR"

# Preguntar si ya existe la carpeta
if [[ -d "$CERT_DIR" ]]; then
  read -p "La carpeta $CERT_DIR ya existe. ¿Querés borrarla? [s/N]: " CONFIRM
  if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" ]]; then
    echo "Abortado por el usuario."
    exit 1
  fi
  rm -rf "$CERT_DIR"
fi

mkdir -p "$CERT_DIR"

# Hook de autenticación para certbot
auth_hook() {
  local DOMAIN="$CERTBOT_DOMAIN"
  local TOKEN_VALUE="$CERTBOT_VALIDATION"
  echo "_acme-challenge.${DOMAIN} IN TXT \"${TOKEN_VALUE}\"" >> "$ZONE_FILE"

  # Actualizar serial
  SERIAL=$(date +%y%m%d%H%M)
  sed -i -E "s/([0-9]{10})/$(echo "$SERIAL")/" "$ZONE_FILE"

  # Reiniciar CoreDNS
  cd "$DNS_PATH" && docker-compose restart && cd "$CURRENT_DIR"

  echo "Esperando propagación del registro..."
  sleep 15

  for DNS in "${DNS_SERVERS[@]}"; do
    echo "Verificando en $DNS..."
    FOUND=$(dig +short TXT _acme-challenge."$DOMAIN" @"$DNS" | grep "$TOKEN_VALUE")
    if [[ -z "$FOUND" ]]; then
      echo "Error: el token no está presente en $DNS"
      exit 1
    fi
  done

  echo "Token verificado exitosamente."
}

# Hook de limpieza (opcional, no usado acá)
cleanup_hook() {
  echo "Limpieza no implementada"
}

# Exportar funciones
export -f auth_hook
export -f cleanup_hook

# Ejecutar certbot
certbot certonly --manual --preferred-challenges=dns --manual-auth-hook auth_hook \
--manual-cleanup-hook cleanup_hook --manual-public-ip-logging-ok \
--agree-tos --no-eff-email -d "*.${DOMAIN}" --email "$EMAIL" || exit 1

# Mover certificados
CERT_SRC="/etc/letsencrypt/live/${DOMAIN}"
if [[ -d "$CERT_SRC" ]]; then
  cp "$CERT_SRC"/* "$CERT_DIR"/
  echo "Certificados guardados en $CERT_DIR"
else
  echo "No se encontraron certificados generados."
fi
