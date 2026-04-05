---
layout: default
---

# MÃ¡quina ANTHEM

## 1. Fase de Reconocimiento

El primer paso es identificar los servicios activos en la direcciÃ³n IP de la vÃ­ctima mediante un escaneo de puertos con `nmap`.

### Escaneo de Puertos

**Comando ejecutado:**

```bash
nmap -sV -sC -Pn 10.81.159.173
```

![image.png](image.png)

## 2. EnumeraciÃ³n Web

Al acceder a la IP a travÃ©s del navegador (`http://10.81.159.173`), observamos un blog basado en el CMS **Umbraco**. El sitio se presenta como "Anthem.com".

![image.png](image%201.png)

## 3. EnumeraciÃ³n de Directorios (Fuerza Bruta)

Para descubrir rutas ocultas en el servidor web, se utilizÃ³ **Gobuster** con un diccionario de tÃ©rminos comunes.

### EjecuciÃ³n de Gobuster

**Comando:**

```bash
gobuster dir -u http://10.81.159.173 -w /usr/share/wordlists/dirb/common.txt
```

![image.png](image%202.png)

## 4. AnÃ¡lisis de `robots.txt`

Al acceder al archivo `http://10.81.159.173/robots.txt`, se descubriÃ³ informaciÃ³n crÃ­tica que el administrador dejÃ³ expuesta.

### Contenido del archivo

![image.png](image%203.png)

## 5. OSINT e IdentificaciÃ³n de Usuario

Tras analizar los posts del blog, se encontrÃ³ un artÃ­culo titulado *"A cheers to our IT department"* que contiene un poema.

### Hallazgo de OSINT

Al investigar el contenido del poema en Google, se identificÃ³ que pertenece a la rima infantil **Solomon Grundy**.

![image.png](image%204.png)

![image.png](image%205.png)

### ConstrucciÃ³n de Credenciales

Utilizando el nombre del personaje y el dominio identificado anteriormente (`anthem.com`), podemos deducir el posible nombre de usuario basÃ¡ndonos en el formato estÃ¡ndar de la empresa (iniciales):

![image.png](image%206.png)

- **Nombre:** Solomon Grundy
- **Usuario (Probable):** `SG`
- **ContraseÃ±a (de robots.txt):** `UmbracoIsTheBest!`

## 6. IntrusiÃ³n Inicial (Acceso RDP)

Con las credenciales obtenidas, procedemos a intentar un acceso remoto mediante el protocolo **RDP** (puerto 3389).

**Comando de conexiÃ³n:**

```bash
xfreerdp /v:10.81.159.173 /u:SG /p:UmbracoIsTheBest! /dynamic-resolution +clipboard
```

## 7. Escalada de Privilegios: EnumeraciÃ³n Local

Una vez dentro del sistema como el usuario **SG**, el siguiente objetivo es encontrar credenciales o configuraciones mal protegidas para convertirnos en **Administrador**.

### ExploraciÃ³n de Archivos Ocultos

Dado que el entorno es Windows, se utilizÃ³ el Explorador de Archivos para inspeccionar la raÃ­z del sistema.

1. Se navegÃ³ hasta: **This PC** > **Local Disk (C:)**.
2. Se habilitÃ³ la opciÃ³n **"Hidden items"** en la pestaÃ±a **View** para revelar archivos y carpetas ocultos por el sistema.

![image.png](image%207.png)

![image.png](image%208.png)

## 8. IdentificaciÃ³n del Vector de Escalada

Tras habilitar la visualizaciÃ³n de elementos ocultos en `C:\`, se ha identificado una carpeta crÃ­tica que no estaba a la vista inicialmente.

### ExtracciÃ³n de Credenciales

Ahora debemos investigar el contenido de esa carpeta.

1. **Entra en `C:\backup`**: Si te deja entrar directamente, busca un archivo (posiblemente un archivo comprimido o un `.txt` con nombres como "restore").
2. **Si el acceso estÃ¡ denegado:** - Haz clic derecho sobre la carpeta `backup` -> **Properties**.
    - Ve a la pestaÃ±a **Security**.
    - Haz clic en **Edit** y luego en **Add**.
    - Escribe tu nombre de usuario (`SG`) y dale a **Check Names**.
    - Marca la casilla de **Full Control** o **Read**, acepta todo y vuelve a intentar entrar.

![image.png](image%209.png)

## 9. Escalada a Super Usuario (Administrator)

Tras obtener la contraseÃ±a `ChangeMeBaby1MoreTime` del archivo de restauraciÃ³n, se procediÃ³ a elevar privilegios directamente desde la sesiÃ³n del usuario **SG**.

### MÃ©todo: ElevaciÃ³n con "Run as Administrator"

Para evitar el cierre de la sesiÃ³n actual, se utilizÃ³ la funcionalidad de elevaciÃ³n de Windows:

- Accedmos desde la cmd a administrador

![image.png](image%2010.png)

- Una vez realizado introducimos la contraseÃ±a que hemos encontrado (ChangeMeBaby1MoreTime)

![image.png](image%2011.png)

- Como podemos comprobar estamos dentro y ya somos admin

![VirtualBox_2KaliLinuxMaquinaasVirtuales_05_04_2026_19_41_43.png](VirtualBox_2KaliLinuxMaquinaasVirtuales_05_04_2026_19_41_43.png)
