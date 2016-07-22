#!/bin/bash

#uncomment to enable debugging
#set -x

VAGRANTSHAREDFOLDER='/vagrant'
CF_DIR='/opt/coldfusion11'
CERTPATH='/etc/nginx/ssl'


#NGINX Config
nginxFiles[0]='conf.d/cfLoadBalance.conf'
nginxFiles[1]='sites-available/default'
nginxFiles[2]='cfProxy.conf'
nginxFiles[3]='nginx.conf'
nginxFiles[4]='updateNginxFromVagrant.sh'

for myFile in "${nginxFiles[@]}"
do
	cp -f $VAGRANTSHAREDFOLDER/nginx/$myFile /etc/nginx/$myFile
	dos2unix -s -q /etc/nginx/$myFile
done

if ! [ -e $CERTPATH ]; then
	mkdir $CERTPATH
fi

#create Localhost cert because it just needs to exist.
if ! [ -e $CERTPATH/wildcard.key ]; then
	openssl req -x509 -newkey rsa:2048 -keyout $CERTPATH/wildcard.key -out $CERTPATH/wildcard.cert -days 1095 -nodes  -subj "/C=US/ST=Ohio/L=Cincinnati/O=ME/OU=Dev/CN=localhost"
fi

nginx -s reload
