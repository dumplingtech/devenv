#!/bin/bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker build -t dumplingtech/hyperkube:1.3.5 ${ROOT_DIR}
