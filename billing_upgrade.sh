#! /bin/bash
#shawn create by 2015-07-22
#export LANG=en_US.UTF-8
while [ $# -gt 0 ]
do
  case $1 in
    "-d"|"--dir")    patchDirPath=$2
                      shift
                      ;;
    "-m"|"--module")  moduleName=$2
                      shift
                      ;;
    "-u"|"--upgradehistory") upHistory=$2
                             shift
                             ;;
    "-h"|"--help")    echo 'Usage: upgrade.sh [OPTION...] '
                      echo 'Examples:'
                      echo 'billing_upgrade.sh -d /veris/billing/aibilling/patch/xxxpatchxxx/ -u /veris/billing/aibilling/patch/billingUpgradeHis  -m all'  
                      echo '  Main operation mode:'
                      echo '    -d,--dir  patch directory path'
                      echo '    -m,--module  module name'
                      echo '    -h,--help  display help.'
                      echo '    -u,--upgradehistory  upgrade history.'
                      exit 0
                      ;;
  esac
  shift
done

if [ "$SHELL" == "/bin/bash" -o "$SHELL" == "/bin/sh" ];then
#   source /etc/profile
   source ~/.bash_profile
elif [ "$SHELL" == "/bin/csh" ];then
   /bin/csh -c "source ~/.cshrc"
fi
errorFile="/tmp/upgradeError$$.log"

if tar -tf "${patchDirPath}"01-SoftwarePkg/* | grep -Pqi "(${moduleName})$";then
#deploy wbass.war
	tar -zxf "${patchDirPath}"01-SoftwarePkg/*
	find "${patchDirPath}"01-SoftwarePkg/ -type f -name "wbass.war" -exec mv {} $HOME/war \;
	rm -rf "${patchDirPath}"01-SoftwarePkg/center_*
	$HOME/jboss-as-7.1.1.Final/bin/jboss-cli.sh --controller="127.0.0.1:9999" --connect /server-group=wbass:stop-servers > /dev/null && echo ":::MESSAGE:::stop wbass.war successfully:::"
	sleep 3
	$HOME/jboss-as-7.1.1.Final/bin/jboss-cli.sh --connect --controller="127.0.0.1:9999" --commands="undeploy wbass.war --server-groups=wbass"> /dev/null && echo ":::MESSAGE:::undeploy wbass.war successfully:::"
	sleep 3
	$HOME/jboss-as-7.1.1.Final/bin/jboss-cli.sh --connect --controller="127.0.0.1:9999" --commands="deploy ~/war/wbass.war --server-groups=wbass"> $errorFile
                        if [ $? -ne 0 ];then
                                errorinfo=$(cat $errorFile)
                                echo ":::ERROR:::Deploy wbass.war has happened some faults, as follow: {$errorinfo} :::"
                        else
                                echo ":::MESSAGE:::Deploy wbass.war successfully:::"
                        fi
	sleep 3
	$HOME/jboss-as-7.1.1.Final/bin/jboss-cli.sh --controller="127.0.0.1:9999" --connect /server-group=wbass:start-servers > /dev/null && echo ":::MESSAGE:::start wbass.war successfully:::"
	sleep 3
else
#deploy center_*
tar -zxf "${patchDirPath}"01-SoftwarePkg/* -C "${patchDirPath}"01-SoftwarePkg/
if [ -d "${patchDirPath}"01-SoftwarePkg/center_* ]; then
m_time="`date +'%Y%m%d'`"
rm -rf $HOME/center_*
cp -r /veris/billing/aisett/center /veris/billing/aisett/center_${m_time}
echo ":::MESSAGE:::BACKUP:::"
/veris/billing/aisett/center/scripts/stop_site.sh
sleep 3
for i in `ipcs |grep aisett|awk '{print $2}'`
do
ipcrm -m $i
ipcrm -s $i
done
echo ":::MESSAGE:::STOP:::"
mv "${patchDirPath}"01-SoftwarePkg/center_* "${patchDirPath}"01-SoftwarePkg/center
cp -r "${patchDirPath}"01-SoftwarePkg/center $HOME
rm -rf "${patchDirPath}"01-SoftwarePkg/center

/veris/billing/aisett/center/bin/sysinfo >> /dev/null <<EOF
1
billing_db_WD
2
WD
3
billing
4
Ch1qQMXH
7
EOF
echo ":::MESSAGE:::DEPLOY:::"
/veris/billing/aisett/center/scripts/start_site.sh
sleep 3
echo ":::MESSAGE:::START:::"
fi
fi
