
# getWildcard

Generate a wildcard SSL certificate using Certbot with manual DNS-01 challenge, integrated with a local CoreDNS server.

Genera un certificado SSL wildcard usando Certbot con el desafío DNS-01 manual, integrado con un servidor CoreDNS local.

---

## 📋 Description / Descripción

This script automates the process of requesting a wildcard certificate from Let's Encrypt using the DNS-01 challenge.  
It updates the zone file, increases the serial number, verifies TXT propagation across multiple public DNS resolvers, and reloads the CoreDNS server.

Este script automatiza el proceso de solicitud de un certificado wildcard desde Let's Encrypt usando el desafío DNS-01.  
Actualiza el archivo de zona, incrementa el número de serie, verifica la propagación del TXT en múltiples DNS públicos y recarga el servidor CoreDNS.

---

## 📦 Requirements / Requisitos

- Bash
- Docker
- Docker Compose
- `dig` utility (dnsutils or bind-tools)
- `certbot` installed locally (not via Docker)
- A running CoreDNS server configured as in [`@fponce96/coredns`](https://github.com/fponce96/coredns)

Este script asume que el servidor DNS está corriendo [CoreDNS](https://coredns.io/) y configurado con el proyecto [`@fponce96/coredns`](https://github.com/fponce96/coredns).  
Asegúrate de que el contenedor DNS esté en ejecución y que los archivos de zona estén montados correctamente y sean editables.

---

## 🚀 Usage / Uso

```bash
./getWildcard.sh example.com
```

If the wildcard directory for the domain already exists, the script will ask for confirmation before deleting it.

Si el directorio wildcard para el dominio ya existe, el script pedirá confirmación antes de eliminarlo.

---

## 📁 Output / Salida

Certificates are stored under:

```
~/certs/example.com/
```

---

## 🔐 Notes / Notas

The script validates DNS propagation before Certbot continues, avoiding failed verifications.  
It also verifies that the TXT record matches the required ACME challenge token.

El script valida la propagación DNS antes de que Certbot continúe, evitando fallas en la verificación.  
También valida que el registro TXT coincida con el token entregado por ACME.

---

## 🛠️ Author / Autor

Maintained by [fponce96](https://github.com/fponce96)

---
