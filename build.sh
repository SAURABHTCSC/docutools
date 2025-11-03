#!/usr/bin/env bash
# exit on error
set -o errexit

# Install all system dependencies
apt-get update
apt-get install -y \
  ghostscript \
  default-jre \
  libreoffice

# Install Python dependencies
pip install -r requirements.txt