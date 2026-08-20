### 2. Dar permisos

```bash
chmod +x limpiar-docker.sh
```

### 3. Ejecutarlo

```bash
./limpiar-docker.sh
```

Cuando aparezca:

```text
¿Continuar con la eliminación TOTAL? (escribe SI):
```

escribe exactamente:

```text
SI
```

### 4. ¿Qué va a eliminar?

El script limpia:

* 🛑 Contenedores detenidos y activos
* 🗑️ Imágenes Docker
* 💾 Volúmenes Docker
* 🌐 Redes no utilizadas
* 🏗️ Caché de Docker Build
* 🧹 Recursos restantes de Docker

Y al final vuelve a ejecutar:

```bash
docker ps -a
docker images -a
docker volume ls
docker system df
```

para comprobar que quedó limpio.

**Importante:** si tienes Docker Compose con PostgreSQL, MySQL, Redis, etc., **los datos guardados en volúmenes también se borrarán**. Si tu objetivo es recuperar espacio de la VM y no necesitas conservar absolutamente nada de Docker, este script es adecuado.
