#!/bin/bash -efu

cd "$(dirname $(readlink -e $0))"

[ ! -d ./svace ] || exit 0

[ -f ./svace-3.4.240312-x64-linux.tar.bz2 ] || \
    wget -q -O ./svace-3.4.240312-x64-linux.tar.bz2 'https://nextcloud.ispras.ru/index.php/s/K3zzEyASxRiQn65/download?path=%2FSvace&files=svace-3.4.240312-x64-linux.tar.bz2'

tar -xf ./svace-3.4.240312-x64-linux.tar.bz2
mv svace-3.4.240312-x64-linux svace
