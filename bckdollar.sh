#!/bin/bash

# Global variables
. /ing_scripts/scripts/planificador/conf/nodes.conf >/dev/null

FECHA=$(date +%d%m%y)
LOCALDESTINY="/localbck"
MES=$(date +"%B")

case "$ENVIRONMENT" in
DEV)
  NFSPATHWPR="/bckactivedev"
  NFSPATHDCR="/bckpassivedev"
  MOUNTDCR="isi-dcr10-nfs-ipc.iaas.ing.net:/ifs/ing/ipc/dcr10/p17057-dev/fast/nodr/nolock/20240320-121452/bckpassivedev"
;;
TST)
  NFSPATHWPR="/bckactivetst"
  NFSPATHDCR="/bckpassivetst"
  MOUNTDCR="isi-dcr10-nfs-ipc.iaas.ing.net:/ifs/ing/ipc/dcr10/p17057/fast/dr/nolock/20230113-100059/bckpassivetst"
;;
ACC)
  NFSPATHWPR="/bckactiveacc"
  NFSPATHDCR="/bckpassiveacc"
  MOUNTDCR="isi-dcr10-nfs-ipc.iaas.ing.net:/ifs/ing/ipc/dcr10/p17057-acc/fast/nodr/nolock/20230825-153618/bckpassiveacc"
;;
PRD)
  NFSPATHWPR="/bckactivepro"
  NFSPATHDCR="/bckpassivepro"
  MOUNTDCR="isi-dcr10-nfs-ipc.iaas.ing.net:/ifs/ing/ipc/dcr10/p17057/fast/dr/nolock/20230113-115029/bckpassivepro"
;;
*)
esac

# Definir variables según el nodo
if [[ "$TYPE" == "DUAS" ]];
then
    SOURCE_PATH="/univ_$NODE_NAME/DUAS"
    INGPATH="/ing_scripts/scripts/planificador"
    BCKNAME="bckduas_$FECHA"
    REMOTEDESTINY="$NFSPATHWPR/agentserverbck"
    REPLICADESTINY="$NFSPATHDCR/agentserverbck"

else
    SOURCE_PATH="/univiewer/server/prounivw"
    BCKNAME="bckuvms_$FECHA"
    REMOTEDESTINY="$NFSPATHWPR/uvmsserverbck"
    REPLICADESTINY="$NFSPATHDCR/uvmsserverbck"
fi

MONTHLYDESTINY="$REMOTEDESTINY/monthly/"
REPLICAMONTHLY="$REPLICADESTINY/monthly/"
LOGFILE="/localbck/rsync-backup_$FECHA.log"



touch "$LOGFILE"
STARTTIME="$(date '+%d.%m.%y %H:%M')"
START=$(date +%s)
THISLOGHEAD="______________________________________\n\
|\n\
|  Script:   $0\n\
|  Hostname: $(hostname)\n\
|  Started:  $STARTTIME\n"
LOGCONTENT="$(head -n 2000 $LOGFILE)"
THISLOG=""
SUMMARY=""

echo "Listado de variables antes del backup"



if [ "$(date +%d)" = "01" ]; then
  # Es el primer día del mes,generamos backup mensual
monthlybackup () {
  echo "Nombre del backup: $BCKNAME-$NODE_NAME_$NODE-01$MES.tar.gz de la ruta $SOURCE_PATH hacia $REMOTEDESTINY del NFS $NFSPATHWPR para $NODE_NAME en $DATACENTER del entorno $ENVIRONMENT"
  local FSTARTTIME="$(date '+%H:%M')"
  local FSTART=$(date +%s)
  printf "$THISLOGHEAD|\n\n\
---------------------------------------\n\
| Summary:\n\
---------------------------------------\n\
$SUMMARY\n\
$(date '+%H:%M')-now: $1 -> $2\n\n\
---------------------------------------\n\
| Details:\
\n---------------------------------------\n\
$THISLOG\n$LOGCONTENT" > $LOGFILE
        THISLOG="$THISLOG\n$(date '+%d.%m.%y %H:%M') | $1 \n->$2\n---------------------------------------\n$(\
        cd $LOCALDESTINY
        tar -czpf "$BCKNAME-$NODE_NAME_$NODE-01$MES.tar.gz" $SOURCE_PATH 2>/dev/null
        ls -lathr "$BCKNAME-$NODE_NAME_$NODE-01$MES.tar.gz"
        rsync -avhz $1 $2 --stats | \
        sed '0,/^$/d')\nfinished: $(date '+%d.%m.%y %H:%M') \n---------------------------------------\n\n"
        printf "$THISLOGHEAD\n$THISLOG\n$LOGCONTENT" > $LOGFILE
        local FSECONDS="$(($(date +%s)-$FSTART))"
        SUMMARY="$SUMMARY \n$FSTARTTIME-$(date '+%H:%M') ($(date -d@$FSECONDS -u +%H:%M:%S)): $1 -> $2"
}
    monthlybackup "$LOCALDESTINY/$BCKNAME-$NODE_NAME_$NODE-01$MES.tar.gz" $MONTHLYDESTINY
    mount $MOUNTDCR $NFSPATHDCR
    rsync -avhz "$LOCALDESTINY/$BCKNAME-$NODE_NAME_$NODE-01$MES.tar.gz" --stats $REPLICAMONTHLY
    umount -f $NFSPATHDCR
    echo "Nombre del fichero mensual de backup en /localbck: $LOCALDESTINY/$BCKNAME-$NODE_NAME_$NODE-01$MES.tar.gz"
    echo "Nombre del fichero mensual de backup copiado al NFS: $REMOTEDESTINY/$BCKNAME-$NODE_NAME_$NODE-01$MES.tar.gz"
else
remotebackup () {
  echo "Nombre del backup: $BCKNAME-$NODE_NAME_$NODE.tar.gz de la ruta $SOURCE_PATH hacia $REMOTEDESTINY del NFS $NFSPATHWPR para $NODE_NAME en $DATACENTER del entorno $ENVIRONMENT"
  local FSTARTTIME="$(date '+%H:%M')"
  local FSTART=$(date +%s)
  printf "$THISLOGHEAD|\n\n\
  ---------------------------------------\n\
  | Summary:\n\
  ---------------------------------------\n\
  $SUMMARY\n\
  $(date '+%H:%M')-now: $1 -> $2\n\n\
  ---------------------------------------\n\
  | Details:\
  \n---------------------------------------\n\
  $THISLOG\n$LOGCONTENT" > $LOGFILE
          THISLOG="$THISLOG\n$(date '+%d.%m.%y %H:%M') | $1 \n->$2\n---------------------------------------\n$(\
          cd $LOCALDESTINY
          tar -czpf "$BCKNAME-$NODE_NAME_$NODE.tar.gz" "$SOURCE_PATH" 2>/dev/null
          ls -lathr "$BCKNAME-$NODE_NAME_$NODE.tar.gz"
          rsync -avhz $1 $2 --stats | \
          sed '0,/^$/d')\nfinished: $(date '+%d.%m.%y %H:%M') \n---------------------------------------\n\n"
          find $REMOTEDESTINY -type f -name "*.gz" -mtime +30 -exec rm {} \;
          find $LOCALDESTINY -type f -name "*.gz" -mtime +7 -exec rm {} \;
          find $LOCALDESTINY -type f -name "*.log" -mtime +7 -exec rm {} \;
          printf "$THISLOGHEAD\n$THISLOG\n$LOGCONTENT" > $LOGFILE
          local FSECONDS="$(($(date +%s)-$FSTART))"
          SUMMARY="$SUMMARY \n$FSTARTTIME-$(date '+%H:%M') ($(date -d@$FSECONDS -u +%H:%M:%S)): $1 -> $2"
  }
    remotebackup $LOCALDESTINY/$BCKNAME-$NODE_NAME_$NODE.tar.gz $REMOTEDESTINY
    mount $MOUNTDCR $NFSPATHDCR
    rsync -avhz $LOCALDESTINY/$BCKNAME-$NODE_NAME_$NODE.tar.gz --stats $REPLICADESTINY
    umount -f $NFSPATHDCR
    echo "Nombre del fichero de backup en /localbck:  $LOCALDESTINY/$BCKNAME-$NODE_NAME_$NODE.tar.gz"
    echo "Nombre del fichero de backup copiado al NFS: $REMOTEDESTINY/$BCKNAME-$NODE_NAME_$NODE.tar.gz"
fi


# Backup especifico de /ing_scripts/scripts/planificador
if [[ "$TYPE" == "DUAS" ]];
then
ingscriptsbackup () {
        local FSTARTTIME="$(date '+%H:%M')"
        local FSTART=$(date +%s)
        printf "$THISLOGHEAD|\n\n\
---------------------------------------\n\
| Summary:\n\
---------------------------------------\n\
$SUMMARY\n\
$(date '+%H:%M')-now: $1 -> $2\n\n\
---------------------------------------\n\
| Details:\
\n---------------------------------------\n\
$THISLOG\n$LOGCONTENT" > $LOGFILE
        THISLOG="$THISLOG\n$(date '+%d.%m.%y %H:%M') | $1 \n->$2\n---------------------------------------\n$(\
        cd $LOCALDESTINY
        tar -czpf "ingscripts_$NODE-$FECHA.tar.gz" "$INGPATH" 2>/dev/null
        ls -lathr "ingscripts_$NODE-$FECHA.tar.gz"
        rsync -avhz $1 $2 --stats | \
        sed '0,/^$/d')\nfinished: $(date '+%d.%m.%y %H:%M') \n---------------------------------------\n\n"
        printf "$THISLOGHEAD\n$THISLOG\n$LOGCONTENT" > $LOGFILE
        local FSECONDS="$(($(date +%s)-$FSTART))"
        SUMMARY="$SUMMARY \n$FSTARTTIME-$(date '+%H:%M') ($(date -d@$FSECONDS -u +%H:%M:%S)): $1 -> $2"
}
    ingscriptsbackup $LOCALDESTINY/ingscripts_$NODE-$FECHA.tar.gz $REMOTEDESTINY
    mount $MOUNTDCR $NFSPATHDCR
    rsync -avhz $LOCALDESTINY/ingscripts_$NODE-$FECHA.tar.gz --stats $REPLICADESTINY
    umount -f $NFSPATHDCR
    echo "Nombre del fichero de backup de ing_scripts en /localbck:  $LOCALDESTINY/ingscripts_$NODE-$FECHA.tar.gz"
    echo "Nombre del fichero de backup de ing_scripts copiado al NFS: $REMOTEDESTINY/ingscripts_$NODE-$FECHA.tar.gz"
fi

chown -R univ50a:univ50a /localbck

#Finish Script: Runtime-Information and Final-Summary:
SECONDS="$(($(date +%s)-$START))"
printf "$THISLOGHEAD\
|  Finished: $(date '+%d.%m.%y %H:%M')\n\
|  Runtime:  $(date -d@$SECONDS -u +%H:%M:%S)\n|\n\n\
---------------------------------------\n\
| Summary:\n\
---------------------------------------\n\
$SUMMARY\n\n\
---------------------------------------\n\
| Details:\n\
---------------------------------------\n\
$THISLOG\n\
|______________________________________\n\
$LOGCONTENT" > $LOGFILE


