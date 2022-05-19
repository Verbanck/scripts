{\rtf1\ansi\ansicpg1252\cocoartf2513
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fmodern\fcharset0 Courier;}
{\colortbl;\red255\green255\blue255;\red0\green0\blue0;}
{\*\expandedcolortbl;;\cssrgb\c0\c0\c0;}
\paperw11900\paperh16840\margl1440\margr1440\vieww13460\viewh20140\viewkind0
\deftab720
\pard\pardeftab720\partightenfactor0

\f0\fs26 \cf0 \expnd0\expndtw0\kerning0
#!/usr/bin/bash\
clear\
VERSIE="1.02"\
echo "---------------------------------------------------------"\
echo "Controle opgave 4 DHCP Systeembeheer 2 versie $VERSIE"\
if [ -f ~/.bashs4 ]; then\
	echo "Je hebt deze opgave al geupload."\
	#exit\
fi\
if [ "$USER" != "root" ]; then\
	echo "Voer dit script uit met sudo."\
	exit\
fi\
echo "---------------------------------------------------------"\
#--------------------------------------------------------------\
RED=`tput setaf 1`\
GREEN=`tput setaf 2`\
BLUE=`tput setaf 4`\
CYAN=`tput setaf 6`\
RC=`tput sgr0`\
echo "Je installeert twee nieuwe servers. De ene zal router zijn, de andere client."\
echo "De router moet 2 netwerk-interfaces hebben:"\
echo "   - \'e9\'e9n verbonden met de VMware-NAT-router en ingesteld op DHCP"\
echo "   - \'e9\'e9n verbonden met een host-only-adapter en ingesteld met een vast IP 192.168.x.254"\
echo "   Je zal hiervoor in /etc/netplan/xxx.yaml mogelijks een 2de adapter moeten toevoegen."\
echo "De client moet slechts 1 netwerk-interface hebben:"\
echo "   - verbonden met dezelfde host-only-adapter als de router, maar ingesteld op DHCP"\
echo "Configureer de router server als DHCP server."\
echo "Deel IP adressen uit vanaf 192.168.x.120 tot en met .130."\
echo "Reserveer de .129 voor jouw nieuwe Linux client en zorg dat dit werkt."\
echo "Resolven doe je via de twee DNS-servers uit vorige opdracht."\
echo "Zorg dus dat de DHCP-server deze DNS-servers doorgeeft aan de client(s)."\
echo "Om de router server als router te configureren, krijg je een script van de lector."\
echo "wget --no-cache https://raw.githubusercontent.com/FredericVW/scripts/main/maak_router.sh"\
echo "Editeer het script alvorens uit te voeren, de op \'e9\'e9n na laatste lijnen zijn de port-forwarding."\
echo "Je client moet kunnen surfen op internet (ping google)."\
echo "Voer dit script uit op de nieuwe Linux die als DHCP client dient."\
echo "Voer dat script uit als root (sudo)."\
echo "Zorg dat je van hieruit SSH kan doen naar de router server zonder paswoord."\
#echo "Verdere opdrachten lees je in de testen."\
echo "-------------------------------------------------------------------------------------------"\
#--------------------------------------------------------------\
#Detect username\
USERNAME=`who | grep -vw root | head -1 | cut -d " " -f1`\
OPL_FILE="/tmp/.O4-$USERNAME-`date +%H%M`.txt"\
DET_FILE="/tmp/.details3-$USERNAME.txt"\
if [ -f $DET_FILE ]; then\
	rm $DET_FILE\
fi\
exec 3>&1 1>$OPL_FILE\
VG=1\
PT=0\
echo "---------------------------------------------------------"\
read -p "Familienaam: " FAM\
read -p "Voornaam: " VNM\
#--------------------------------------------------------------\
#--------------------------------------------------------------\
echo "Hostname: `hostname`"\
echo "Script loopt met user: `whoami`"\
\
#Check IP DNS1\
AANT_AD="`ls /sys/class/net | grep -v lo | wc -l`"\
ADPT="`ls /sys/class/net | grep -v lo`"\
IP_A="`ip a show dev $ADPT | grep \\"inet \\"| awk ' \{ print $2\}'`"\
IP_A_SUB="`ip a show dev $ADPT | grep \\"inet \\"| awk ' \{ print $2\}' | awk -F '.' '\{print $3\}'`"\
\
DHCP="`ip a show dev $ADPT | grep \\"inet \\"| awk ' \{ print $7\}'`"\
if [ "$AANT_AD" != "1" ]; then\
	echo "$RED - Adapters gevonden: $AANT_AD, er mag er maar \'e9\'e9n zijn.$RC"\
	exit\
else\
	echo "Adapter: $ADPT, IP: $IP_A, SUB: $IP_A_SUB" >> $DET_FILE\
fi\
\
\
#Ping externe server\
ping -c 1 www.google.be >>$DET_FILE\
PGRES=$?\
if [ $PGRES == 0 ]; then\
	echo "$GREEN + Pingen naar www.google.be lukt.$RC"\
	((PT++))\
else\
	echo "$RED - Pingen naar www.google.be lukt niet.$RC"\
fi\
\
\
function check_netplan \{\
	#Check order DHCP settings\
	#NPLAN = filename of network netplan config yaml file\
	#ADAP = adaptor to look for\
	echo "************ Netplan DHCP ***************" >>$DET_FILE\
	#cat $NPLAN >>$DET_FILE\
	FOUND_ADP=0\
	FOUND_DHCP=0\
  echo "Running function NETPLAN $NPLAN, $ADAP" >>$DET_FILE\
	while read NP_LINE\
	do\
	  if [ "$NP_LINE" == "$ADAP:" ]; then\
      FOUND_ADP=1\
    fi\
	  if [ "$FOUND_ADP" == "1" ] && [[ "$NP_LINE" == *"dhcp4"* ]]; then\
      FOUND_DHCP=1\
    fi\
	  if [ "$FOUND_ADP" == "1" ] && [ "$FOUND_DHCP" == "1" ]; then\
		    ITEM="`echo $NP_LINE | awk -F ':' '\{ print $1 \}'`"\
    fi\
    #Debug echo "ITEM:$ITEM, $FOUND_ADP, $FOUND_DHCP"\
		if [ "$ITEM" == "dhcp4" ]; then\
			VALUE_LONG="`echo $NP_LINE | awk -F ':' '\{ print $2 \}'`"\
			VALUE="`echo $VALUE_LONG | sed 's/ //g'| sed 's/\\[//g' | sed 's/\\]//g'`"\
			#Debug echo "DHCP in Netplan: Value = $VALUE"\
			if [ "$VALUE" == "true" ]; then\
				echo "$GREEN + DCHP is correct ingesteld.$RC"\
				((PT++))\
			else\
				echo "$RED - DHCP client is niet correct. ($NP_LINE, Waarde:$VALUE).$RC"\
			fi\
		fi\
\
	done <$NPLAN\
\}\
\
#DHCP functie\
ADAP=$ADPT\
NPLAN="/etc/netplan/`ls /etc/netplan  | grep 00 | head -1`"\
check_netplan\
\
\
#check ip address\
GOOD_IP1="192.168.$IP_A_SUB.129/24"\
if [ "$GOOD_IP1" == "$IP_A" ]; then\
		echo "$GREEN + IP adres van client is goed. ($IP_A) $RC"\
		((PT++))\
else\
		echo "$RED - Het IP adres van de client is nog niet correct. ($IP_A)$RC"\
fi\
#-----------------------------------------------------\
\
DNS1="`systemd-resolve --status | tail -3 | grep -v Domain | head -1 | awk -F ':' '\{print $2\}'  | sed 's/ //g'`"\
DNS2="`systemd-resolve --status | tail -3 | grep -v Domain | tail -1 | sed 's/ //g'`"\
\
if [ "$DNS1" == "192.168.$IP_A_SUB.20" ] &&  [ "$DNS2" == "192.168.$IP_A_SUB.21" ]; then\
	echo "$GREEN + De DNS servers staan correct.$RC"\
	((PT++))\
else\
	echo "$RED - De DNS servers zijn niet correct. ($DNS1, $DNS2)$RC"\
  echo "$RED versus (192.168.$IP_A_SUB.20,192.168.$IP_A_SUB.21)$RC" >>$DET_FILE\
fi\
\
echo "*************** DHCPD.CONF ****************" >>$DET_FILE\
ssh 192.168.$IP_A_SUB.254 cat /etc/dhcp/dhcpd.conf >>$DET_FILE\
echo "*******************************************" >>$DET_FILE\
\
ROUTER=`ip r | grep default | awk '\{ print $3 \}'`\
if [ "$ROUTER" == "192.168.$IP_A_SUB.254" ]; then\
  echo "$GREEN + De default gateway staat correct ($ROUTER).$RC"\
  ((PT++))\
else\
  echo "$RED - De default gateway staat niet correct ($ROUTER)$RC"\
fi\
\
#Slotverwerking\
#---------------------------------------------------------\
echo ------\
#Bereken de score van op 18 naar op 10\
OPTIEN="`echo \\"scale=2; $PT/0.5 \\"| bc -l`"\
echo "Totaal: $PT / 5, ofwel $OPTIEN / 10"\
echo "NAAM: $FAM, $VNM"\
exec 1>&3 3>&-\
cat $OPL_FILE\
read -p "Geef de nummers van de vragen in die volgens jou niet correct zijn, gescheiden door een komma (Enter=alles OK): " FOUTEVRAGEN\
echo "Deze vragen zijn niet goed beoordeeld: $FOUTEVRAGEN" >> $OPL_FILE\
cat $DET_FILE >> $OPL_FILE # stuurt de details mee met de ftp straks\
echo "Om in te dienen (doorsturen) typ je \\"Ja\\" met hoofdletter."\
read -p "Wil je indienen? " DOORSTUREN\
if [ "$DOORSTUREN" == "Ja" ] ; then\
	#Doorsturen file\
	ftp -in <<EOF\
	open files.000webhost.com\
	user sysb2 sjC4yrsf2DYxePE\
	bin\
  passive\
	put $OPL_FILE\
	close\
	bye\
EOF\
	if [ $? == 0 ] ; then\
		echo "De opdracht werd ingediend."\
		touch ~/.bashs4\
	else\
		echo "Er was een probleem met het indienen."\
	fi\
else\
	echo "De opdracht werd nog niet ingediend."\
fi\
rm $OPL_FILE\
rm $DET_FILE\
#\
#}