#!/bin/bash
set -e

#source "./prod.cfg"

CREATE_WORDPRESS_INSTANCE=
DELETE_WORDPRESS_INSTANCE=

usage() {
    echo " "
    echo "   options:"
    echo "     -c,    Create new Wordpress instance with \$name and PWD (second argument)"
    echo "     -d,    Delete Wordpress instance with \$name"
    echo "  "
    echo "     -h,    show brief help"
    echo "  "
    exit 0
}

if [[ $1 == "" ]]; then
    usage
    exit;
fi

while getopts c:d: name
do
    case $name in
    c)      CREATE_WORDPRESS_INSTANCE=1
            export NAME=$OPTARG
            PWD=$2;;
    d)      DELETE_WORDPRESS_INSTANCE=1
            export NAME=$OPTARG;;
    h)      usage
    esac
done

if [ ! -z $CREATE_WORDPRESS_INSTANCE ]; then
  echo Booting Wordpress Stack on Kubernetes with name: $NAME
  echo PWD $3

  echo $3 > password-$NAME.txt
  #tr --delete '\n' <password-stillforward.txt >.strippedpassword.txt && mv .strippedpassword.txt password-stillforward.txt
  envsubst < local-volumes.yaml | kubectl create -f -
  # exit
  kubectl create secret generic mysql-$NAME-pass --from-file=password-$NAME.txt
  envsubst < mysql-deployment.yaml     | kubectl create -f -
  envsubst < wordpress-deployment.yaml | kubectl create -f -
fi

if [ ! -z $DELETE_WORDPRESS_INSTANCE ]; then
  gcloud compute disks list
  kubectl delete deployment,service -l app=$NAME
  kubectl delete pvc -l app=$NAME
  #kubectl delete pv local-$NAME-pv-1 local-$NAME-pv-2
  kubectl delete secret mysql-$NAME-pass
  gcloud compute disks list
fi
