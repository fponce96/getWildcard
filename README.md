
# getWildcard

> 🌐 Automated wildcard SSL certificate generator using Certbot and CoreDNS  
> 🌐 Generador automatizado de certificados SSL wildcard usando Certbot y CoreDNS

---

## 📖 Description / Descripción

**English:**  
`getWildcard` is a Bash script designed to automate the process of obtaining Let's Encrypt wildcard SSL certificates using the DNS-01 challenge. It updates the CoreDNS zone file, increments the serial number in the SOA record, reloads the DNS server, and verifies TXT record propagation across multiple DNS resolvers before finalizing the certificate generation.

**Español:**  
`getWildcard` es un script en Bash que automatiza la obtención de certificados SSL wildcard de Let's Encrypt usando el desafío DNS-01. Actualiza el archivo de zona de CoreDNS, incrementa el número de serie en el registro SOA, recarga el servidor DNS y verifica la propagación del registro TXT en múltiples resolvers DNS antes de finalizar la generación del certificado.

---

## 🚀 Features / Características

- Manual DNS-01 ACME challenge automation.
- Edits CoreDNS zone files.
- Serial number formatted as `YYMMDDHHMM`.
- Verifies TXT record with `dig` against multiple public DNS servers.
- Handles wildcard certificates (`*.yourdomain.com`).
- Saves certificates to a custom directory per domain.
- Safe: asks confirmation before overwriting existing certs.

---

## 🛠 Requirements / Requisitos

- `bash`
- `docker` and `docker-compose`
- `certbot`
- `dig` (from `dnsutils` or `bind-tools`)
- `sudo` (optional, needed for installing missing tools)

---

## 📦 Installation / Instalación

```bash
git clone https://github.com/fponce96/getWildcard.git
cd getWildcard
chmod +x generate.sh
```

---

## ✅ Usage / Uso

```bash
./generate.sh yourdomain.com
```

> Certificates will be saved to: `./certs/yourdomain.com/`

> Los certificados se guardarán en: `./certs/yourdomain.com/`

---

## 🧪 Validation / Validación

The script:
1. Extracts the ACME token from Certbot.
2. Inserts the token into the CoreDNS zone as a TXT record.
3. Increments the serial in the SOA.
4. Restarts CoreDNS (via Docker Compose).
5. Uses `dig` with multiple public resolvers (e.g., Google, Cloudflare) to confirm propagation.
6. If all pass, Certbot completes and certificates are saved.

---

## 🔐 Example output / Ejemplo de salida

```bash
Certificate for *.example.com successfully generated!
Saved to: ./certs/example.com/
```

---

## 🧾 License / Licencia

MIT License

---

## ✒️ Author / Autor

**Francisco Ponce** – [@fponce96](https://github.com/fponce96)
