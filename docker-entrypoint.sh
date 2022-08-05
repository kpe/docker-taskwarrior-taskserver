#!/bin/bash

function execute {
    echo "$ $@"
    eval $@
}

if [ ! -w $TASKDATA ]; then
    echo "$TASKDATA is not writable for user. Please ensure that it belongs to user id 1000"
    exit 255;
fi;

if [ ! -d $TASKDATA/pki/ ]; then
    execute cp -R /pki $TASKDATA/pki
    sed -i "s/^CN=.*/CN=$FQDN/g"                           $TASKDATA/pki/vars
    sed -i "s/^EXPIRATION_DAYS=.*/EXPIRATION_DAYS=$FQDN/g" $TASKDATA/pki/vars
fi;

if [ ! -f $TASKDATA/config ]; then
    echo "===> $TASKDATA/config not found. Initializing taskd."
    execute taskd init   --data $TASKDATA
    execute taskd config --data $TASKDATA --force log $TASKDATA/taskd.log
    execute taskd config --data $TASKDATA --force pid.file /taskd.pid
    execute taskd config --data $TASKDATA --force server 0.0.0.0:53589
fi;


if [ ! -f $TASKDATA/pki/ca.cert.pem ]; then
    echo '===> No certificates found. Initializing self-signed ones.'
    cd $TASKDATA/pki
    execute ./generate

    execute taskd config --data $TASKDATA --force client.cert $TASKDATA/pki/client.cert.pem
    execute taskd config --data $TASKDATA --force client.key  $TASKDATA/pki/client.key.pem
    execute taskd config --data $TASKDATA --force server.cert $TASKDATA/pki/server.cert.pem
    execute taskd config --data $TASKDATA --force server.key  $TASKDATA/pki/server.key.pem
    execute taskd config --data $TASKDATA --force server.crl  $TASKDATA/pki/server.crl.pem
    execute taskd config --data $TASKDATA --force ca.cert     $TASKDATA/pki/ca.cert.pem
else
    echo '===> Certificates already exist'
fi;

if [ ! -f $TASKDATA/pki/default-client.key.pem ]; then
    echo '===> No users setup yet. Setting up organization Default with user Default'
    execute taskd add --data $TASKDATA  org Default
    execute taskd add --data $TASKDATA user Default Default
    cd $TASKDATA/pki
    bash ./generate.client default-client
fi;

echo ""
echo ""
echo "You are all set to use taskd."
echo "Execute the following steps to setup your client:"
echo "1. Get the keys data/pki/default-client.{key,cert}.pem and ca.cert.pem"
echo ""
echo "  export DOCKER=docker"
echo "  export CID=$(hostname)"
echo "  mkdir -p ~/.task/pki/"
echo "  \$DOCKER exec \$CID tar cz -C /data/pki/ default-client.{key,cert}.pem ca.cert.pem | tar xzv -C ~/.task/pki/"
echo ""
echo "In GCP you might use:"
echo ""
echo "  export DOCKER='gcloud compute ssh intance-name -- docker' "
echo ""
echo "2. Execute on your client:"
echo "  task config taskd.certificate -- ~/.task/pki/default-client.cert.pem"
echo "  task config taskd.key         -- ~/.task/pki/default-client.key.pem"
echo "  task config taskd.ca          -- ~/.task/pki/ca.cert.pem"
echo "  task config taskd.credentials -- Default/Default/$(ls $TASKDATA/orgs/Default/users)"
echo "  task config taskd.server      -- host.domain:53589"
echo ""
echo ""


execute taskd server --data $TASKDATA
echo "exit: $?"
execute tail -f /dev/null