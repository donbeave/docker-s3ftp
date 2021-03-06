#!/bin/bash

PACKAGE="s3ftp"
VERSION="latest"

set -e

echo "> 1. Building Docker image"
echo ""
docker build -t donbeave/$PACKAGE:$VERSION .
