#!/bin/bash

set -e

echo "=========================================="
echo "       LIMPIEZA COMPLETA DE DOCKER"
echo "=========================================="
echo

echo "[1/6] Estado actual de Docker"
echo "------------------------------------------"

echo "Contenedores:"
docker ps -a

echo
echo "Imágenes:"
docker images -a

echo
echo "Volúmenes:"
docker volume ls

echo
echo "Redes:"
docker network ls

echo
echo "Uso de espacio:"
docker system df

echo
read -p "¿Continuar con la eliminación TOTAL? (escribe SI): " CONFIRMACION

if [[ "$CONFIRMACION" != "SI" ]]; then
    echo
    echo "Operación cancelada."
    exit 0
fi

echo
echo "[2/6] Deteniendo contenedores..."
docker stop $(docker ps -q) 2>/dev/null || true

echo
echo "[3/6] Eliminando contenedores..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

echo
echo "[4/6] Eliminando imágenes..."
docker rmi -f $(docker images -aq) 2>/dev/null || true

echo
echo "[5/6] Eliminando volúmenes..."
docker volume rm $(docker volume ls -q) 2>/dev/null || true

echo
echo "Eliminando redes Docker no utilizadas..."
docker network prune -f

echo
echo "Eliminando caché de construcción..."
docker builder prune -af

echo
echo "[6/6] Limpieza general adicional..."
docker system prune -af --volumes

echo
echo "=========================================="
echo "       VERIFICACIÓN FINAL"
echo "=========================================="

echo
echo "Contenedores:"
docker ps -a

echo
echo "Imágenes:"
docker images -a

echo
echo "Volúmenes:"
docker volume ls

echo
echo "Redes:"
docker network ls

echo
echo "Uso de espacio:"
docker system df

echo
echo "=========================================="
echo "       LIMPIEZA TERMINADA"
echo "=========================================="
