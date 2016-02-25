#!/usr/bin/env bash

VAGRANTSHAREDFOLDER='/vagrant'
CF_DIR='/opt/coldfusion11'
CF_INSTALLER='ColdFusion_11_WWEJ_linux64u3.bin'
CFHOTFIXFILE='hotfix_007.jar'
FONT_FILEVERSION='font-ibm-type1-1.0.3'
JAVA_TAR_FILE='jdk-8u66-linux-x64.tar.gz'
JAVA_VERSION='1.8.0_66'
CERTPATH='/etc/nginx/ssl'
DEPENDENCY_FILE_URL='https://github.com/howellcc/vagrant-nginx-coldfusion11/releases/download/v1.0.0/dependencies.tar.gz'
DEPENDENCY_LOCATION='/opt'

#Just Timing because I'm curious
TIMING="$(date +%s)"

#function for asynchronous dependency download
downloadDependencies(){
	if ! [ -e $VAGRANTSHAREDFOLDER/dependencies.tar.gz ]; then
		printf "Retreiving Dependencies from GitHub..."
		wget -q $DEPENDENCY_FILE_URL -P $VAGRANTSHAREDFOLDER
	fi
	tar -xzf $VAGRANTSHAREDFOLDER/dependencies.tar.gz -C $DEPENDENCY_LOCATION
	chmod u+x $DEPENDENCY_LOCATION/$CF_INSTALLER
}

#kick off dependency downloading (allthethings) concurrency
downloadDependencies &
downloadDependencies_pid=$!


#Test if nginx has been installed, if so skip apt-get install of all packages.
if ! [ -d /etc/nginx ]; then
	#add the i386 architechture needed for the i386 packages needed for the pdfg service
	dpkg --add-architecture i386

	printf "apt-get updating..."
	apt-get -qq update

	printf "apt-get upgrading..."
	apt-get -qq upgrade

	#install all packages
	printf "installing packages. (Now is a good time for a bathroom break or a snack. )....."
	apt-get install -qq -y nginx dkms bzip2 build-essential locate vim glibc-2.* lib32z1 lib32ncurses5 lib32bz2-1.0 lib32z1-dev lib32bz2-dev zlib1g >/dev/null

	printf "installing more packages. (Need a cup of coffee?)....."
	apt-get install -qq -y libx11* libexpat1 x-window-* libxcb1-dev libxext6 libsm6 libxrandr2 libxrender1 libxinerama1 tofrodos lib32nss-mdns >/dev/null

	printf "installing more packages. (Have you called your mother recently?)....."
	apt-get install -qq -y libexpat1:i386 libfreetype6:i386 libxcb1-dev:i386 libxext6:i386 libsm6:i386 libxrandr2:i386 libxrender1:i386 libxinerama1:i386 >/dev/null

	#if I feel like experimenting with NFS again, I need the following
	#apt-get -qq install -y cachefilesd
	#printf "RUN=yes" > /etc/default/cachefilesd
fi

#set timezone
printf "setting timezone..."
mv /etc/localtime /etc/localtime-old
ln -s /usr/share/zoneinfo/US/Eastern /etc/localtime
printf "US/Eastern" > /etc/timezone
export TZ=US/Eastern

#add additional things to .bashrc - For the sake of replayability of this script.  Any future additions should go in a separate bashAdditions file and be tested for independantly.
if ! grep -Fxq "#bashrcAdditions 1" ~/.bashrc; then
	cat $VAGRANTSHAREDFOLDER/bashrcAdditions.sh >> ~/.bashrc
	#fix windows line endings
	fromdos ~/.bashrc
fi

#NGINX Config
nginxFiles[0]='conf.d/cfLoadBalance.conf'
nginxFiles[1]='sites-available/default'
nginxFiles[2]='cfProxy.conf'
nginxFiles[3]='nginx.conf'
nginxFiles[4]='updateNginxFromVagrant.sh'

for myFile in "${nginxFiles[@]}"; do
	cp -f $VAGRANTSHAREDFOLDER/nginx/$myFile /etc/nginx/$myFile
	fromdos /etc/nginx/$myFile
done

if ! [ -e $CERTPATH ]; then
	mkdir $CERTPATH
fi

#create a self-signed wildcard cert for localhost
if ! [ -e $CERTPATH/wildcard.key ]; then
	openssl req -x509 -newkey rsa:2048 -keyout $CERTPATH/wildcard.key -out $CERTPATH/wildcard.cert -days 1095 -nodes  -subj "/C=US/ST=Ohio/L=Cincinnati/O=Me/OU=Dev/CN=localhost" >/dev/null
fi

nginx -s reload


#Wait for Dependencies download to finish before proceeding.
printf "Waiting for dependency download to finish..."
wait $downloadDependencies_pid
printf "Dependency download complete."

#install fonts needed for PDF Service
if ! [ -e /usr/share/fonts/courbi.afm ]; then
	cp -f $DEPENDENCY_LOCATION/$FONT_FILEVERSION/* /usr/share/fonts/
	rm -rf $DEPENDENCY_LOCATION/$FONT_FILEVERSION
fi
printf "Font Install Complete"

#install JAVA
if ! [ -a /opt/jdk ]; then
	ln -s /opt/jdk$JAVA_VERSION /opt/jdk
	update-alternatives --install /usr/bin/java java /opt/jdk/bin/java 100
	update-alternatives --install /usr/bin/javac javac /opt/jdk/bin/javac 100
fi
printf "JAVA Install Complete"


#CF INSTALL
if [ ! -d "/opt/coldfusion11" ]; then
	printf "Installing ColdFusion..."
	#Needed for the pdfg installer to complete successfully as well as the installers for CF updates
	export DISPLAY=

	$DEPENDENCY_LOCATION/$CF_INSTALLER -f $VAGRANTSHAREDFOLDER/CFSilentInstall.properties > /opt/CFInstall.log

	#tomcat args
	cp -f $VAGRANTSHAREDFOLDER/cfusion/runtime/conf/server.xml $CF_DIR/cfusion/runtime/conf/

	#Jetty startup script
	cp -f $VAGRANTSHAREDFOLDER/cfusion/jetty/cfjetty $CF_DIR/cfusion/jetty/

	#CF config files and MS JDBC driver
	cp -f $VAGRANTSHAREDFOLDER/cfusion/lib/* /opt/coldfusion11/cfusion/lib/

	#JVM Args and CF startup script
	cp -f $VAGRANTSHAREDFOLDER/cfusion/bin/* $CF_DIR/cfusion/bin/

	#Copy in custom tags
	cp -f $VAGRANTSHAREDFOLDER/cfusion/CustomTags/* $CF_DIR/cfusion/CustomTags/

	#copy customized version of classic.cfm debug script
	cp -f $VAGRANTSHAREDFOLDER/cfusion/wwwroot/WEB-INF/debug/classic.cfm $CF_DIR/cfusion/wwwroot/WEB-INF/debug/classic.cfm

	#Was missing a cach path directory needed for CFChart and who knows what else
	if [ ! -d "/opt/coldfusion11/cfusion/tmpCache" ]; then
		mkdir /opt/coldfusion11/cfusion/tmpCache
		if [ ! -d "/opt/coldfusion11/cfusion/tmpCache/CFFileServlet" ]; then
			mkdir /opt/coldfusion11/cfusion/tmpCache/CFFileServlet
			if [ ! -d "/opt/coldfusion11/cfusion/tmpCache/CFFileServlet/_cf_chart" ]; then
				mkdir /opt/coldfusion11/cfusion/tmpCache/CFFileServlet/_cf_chart
			fi
		fi
	fi

	#CF Hotfix 7
	if [ ! -d "/opt/coldfusion11/cfusion/hf-updates" ]; then
		mkdir /opt/coldfusion11/cfusion/hf-updates
	fi
	mv $DEPENDENCY_LOCATION/hotfix_007.jar $CF_DIR/cfusion/hf-updates/
	# we'll run this later after chowing it all

	#Who's your daddy?
	chown -R www-data.bin $CF_DIR/cfusion
	chown -R www-data.bin $CF_DIR/config
	chown -R www-data.bin $CF_DIR/jre

	#run hotfix as www-data user
	printf "installing CF hotfix7..."
	sudo -u www-data java -jar $CF_DIR/cfusion/hf-updates/hotfix_007.jar -i silent
fi

#Set up CF autostart init script
if ! [ -e /etc/init.d/coldfusion ]; then
	ln -s $CF_DIR/cfusion/bin/coldfusion /etc/init.d/coldfusion
	update-rc.d coldfusion defaults

	ln -s $CF_DIR/cfusion/jetty/cfjetty /etc/init.d/coldfusion-jetty
	update-rc.d coldfusion-jetty defaults
fi

#install our init script that re-establishes VBox shared folders without using vagrant up
if ! [ -e /etc/init.d/ReMountVagrantFolders ]; then
	cp $VAGRANTSHAREDFOLDER/ReMountVagrantFolders /etc/init.d/
	update-rc.d ReMountVagrantFolders defaults 80 20
fi


#end Timing
TIMING="$(($(date +%s)-TIMING))"
printf "Bootstrap Script Completed In: %02d:%02d:%02d\n" "$((TIMING/3600%24))" "$((TIMING/60%60))" "$((TIMING%60))"
