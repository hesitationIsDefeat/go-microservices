#!/bin/bash
set -e

MONGO_USER="admin"
MONGO_PASS="password"

MOUNT_DIR="/mnt/mongo"
DEVICE="/dev/disk/by-id/google-mongo-disk"

mkdir -p $MOUNT_DIR

if ! blkid $DEVICE; then
  mkfs.ext4 -F $DEVICE
fi

mount $DEVICE $MOUNT_DIR

echo "$DEVICE $MOUNT_DIR ext4 defaults 0 2" >> /etc/fstab

apt-get update
apt-get install -y docker.io

docker run -d \
  --name mongodb \
  -p 27017:27017 \
  -v $MOUNT_DIR:/data/db \
  -e MONGO_INITDB_ROOT_USERNAME=$MONGO_USER \
  -e MONGO_INITDB_ROOT_PASSWORD=$MONGO_PASS \
  --restart=always \
  mongo:4.2.17-bionic
