#!/bin/bash -e

country='US'
state='California'
locale='San Francisco'
organization='Brickly.io, Inc.'
unit='Operations'
domain='*.brickly.io'

openssl req -nodes -newkey rsa:2048 -keyout ${domain}.key -out ${domain}.csr -subj "/C=${country}/ST=${state}/L=${locale}/O=${organization}/OU=${unit}/CN=${domain}"
