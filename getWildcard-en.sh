#!/bin/bash

# Initial variables
DNS_PATH="/docker/dns"
CURRENT_DIR=$(pwd)
EMAIL="${EMAIL:-admin@example.com}"
DEPENDENCIES=(docker docker-compose dig certbot)
DNS_SERVERS=("1.1.1.1" "8.8.8.8" "9.9.9.9")

# Validate arguments
if [[ -z "$1" ]]; then
  echo "Error: You must pass the domain as an argument."
  echo "Use: $0 domain.com"
  exit 1
fi

DOMAIN="$1"
ZONE_FILE="${DNS_PATH}/zones/db.${DOMAIN}"
CERT_DIR="./certs_${DOMAIN}"

# Verify if the script is root or has a sudo
if ! command -v sudo >/dev/null && [[ $EUID -ne 0 ]]; then
  echo "Error: You need to be root or have a single installed to install dependencies."
  exit 1
fi

# Verify Dependencies
for dep in "${DEPENDENCIES[@]}"; do
  if ! command -v "$dep" >/dev/null; then
    echo "$dep It is not installed. Installing ..."
    if command -v apt-get >/dev/null; then
      sudo apt-get update && sudo apt-get install -y "$dep"
    elif command -v dnf >/dev/null; then
      sudo dnf install -y "$dep"
    elif command -v pacman >/dev/null; then
      sudo pacman -Sy --noconfirm "$dep"
    elif command -v zypper >/dev/null; then
      sudo zypper install -y "$dep"
    else
      echo "A compatible package manager was not detected."
      exit 1
    fi
  fi
done

# Validate that the DNS container is running
cd "$DNS_PATH"
if ! docker-compose ps | grep -q "Up"; then
  echo "Error: DNS container is not running."
  exit 1
fi
cd "$CURRENT_DIR"

# Ask if the folder already exists
if [[ -d "$CERT_DIR" ]]; then
  read -p "The $CERT_DIR folder already exists. Do you want to erase it? [y/n]: " CONFIRM
  if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "User aborted."
    exit 1
  fi
  rm -rf "$CERT_DIR"
fi

mkdir -p "$CERT_DIR"

# Authentication hook for certbot
auth_hook() {
  local DOMAIN="$CERTBOT_DOMAIN"
  local TOKEN_VALUE="$CERTBOT_VALIDATION"
  echo "_acme-challenge.${DOMAIN} IN TXT \"${TOKEN_VALUE}\"" >> "$ZONE_FILE"

  # Update serial
  SERIAL=$(date +%y%m%d%H%M)
  sed -i -E "s/([0-9]{10})/$(echo "$SERIAL")/" "$ZONE_FILE"

  # Restart CoreDNS
  cd "$DNS_PATH" && docker-compose restart && cd "$CURRENT_DIR"

  echo "Waiting for the propagation of the registration ..."
  sleep 15

  for DNS in "${DNS_SERVERS[@]}"; do
    echo "Verifying entry in $DNS..."
    FOUND=$(dig +short TXT _acme-challenge."$DOMAIN" @"$DNS" | grep "$TOKEN_VALUE")
    if [[ -z "$FOUND" ]]; then
      echo "Error: Token is not present in $DNS"
      exit 1
    fi
  done

  echo "Token successfully verified."
}

# Cleaning hook (optional, not used here)
cleanup_hook() {
  echo "Function not implemented"
}

# Export functions
export -f auth_hook
export -f cleanup_hook

# Execute certbot
certbot certonly --manual --preferred-challenges=dns --manual-auth-hook auth_hook \
--manual-cleanup-hook cleanup_hook --manual-public-ip-logging-ok \
--agree-tos --no-eff-email -d "*.${DOMAIN}" --email "$EMAIL" || exit 1

# Move certificates
CERT_SRC="/etc/letsencrypt/live/${DOMAIN}"
if [[ -d "$CERT_SRC" ]]; then
  cp "$CERT_SRC"/* "$CERT_DIR"/
  echo "Certificates saved in $CERT_DIR"
else
  echo "No generated certificates were found."
fi
