#!/bin/bash

function execute {
    echo "$ $@"
    eval $@
}

if [ ! -w $TASKDATA ]; then
    echo "$TASKDATA is not writable for user. Please ensure that it belongs to user id 1000"
    exit 255;
fi;

if [ ! -f $TASKDATA/config ]; then
    echo "===> $TASKDATA/config not found. Initializing taskd."

    execute taskd init   --data $TASKDATA

if [ ! -d $TASKDATA/pki/ ]; then
    execute cp -vr /pki /tmp/
    sed -i "s/^CN=.*/CN=$FQDN/g"                           /tmp/pki/vars
    sed -i "s/^EXPIRATION_DAYS=.*/EXPIRATION_DAYS=3650/g"  /tmp/pki/vars

    cd /tmp/pki
    execute ./generate
    execute ./generate.client default-client
    cp -rv /tmp/pki/ $TASKDATA/

    #execute taskd config --data $TASKDATA --force client.cert $TASKDATA/pki/client.cert.pem
    #execute taskd config --data $TASKDATA --force client.key  $TASKDATA/pki/client.key.pem
    execute taskd config --data $TASKDATA --force server.cert $TASKDATA/pki/server.cert.pem
    execute taskd config --data $TASKDATA --force server.key  $TASKDATA/pki/server.key.pem
    execute taskd config --data $TASKDATA --force server.crl  $TASKDATA/pki/server.crl.pem
    execute taskd config --data $TASKDATA --force ca.cert     $TASKDATA/pki/ca.cert.pem

    execute taskd add --data $TASKDATA  org Default
    execute taskd add --data $TASKDATA user Default Default

fi;

    execute taskd config --data $TASKDATA --force log $TASKDATA/taskd.log
    execute taskd config --data $TASKDATA --force pid.file /taskd.pid
    execute taskd config --data $TASKDATA --force server 0.0.0.0:53589

fi;



echo ""
echo ""
echo "You are all set to use taskd."
echo "Execute the following steps to setup your client:"
echo "1. Get the keys data/pki/default-client.{key,cert}.pem and ca.cert.pem"
echo ""
echo ""
echo "  mkdir -p ~/.task/pki/"
echo "  export CID=\$(gcloud compute ssh $(hostname) -- docker ps --filter name=taskwarrior --format '{{.ID}}' | tr -d '\n\r')"
echo "  gcloud compute ssh $(hostname) --command=\"docker exec \$CID tar cz -C /data/pki default-client.{key,cert}.pem ca.cert.pem\" | tar xzv -C ~/.task/pki/"
echo "  export TW_EXT_IP=\$(gcloud compute ssh $(hostname) --command=\"curl -H 'Metadata-Flavor: Google' http://metadata/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip\")"
echo ""
echo ""
echo "In GCP you might use:"
echo "2. Execute on your client:"
echo ""
echo "  task config taskd.certificate -- ~/.task/pki/default-client.cert.pem"
echo "  task config taskd.key         -- ~/.task/pki/default-client.key.pem"
echo "  task config taskd.ca          -- ~/.task/pki/ca.cert.pem"
echo "  task config taskd.credentials -- Default/Default/$(ls $TASKDATA/orgs/Default/users)"
echo "  task config taskd.server      -- \$TW_EXT_IP:53589"
echo ""
echo ""


execute taskd server --data $TASKDATA
echo "exit: $?"
execute tail -f /dev/null