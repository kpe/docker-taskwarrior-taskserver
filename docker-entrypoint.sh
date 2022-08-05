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
fi;

if [ ! -f $TASKDATA/config ]; then
    echo "===> $TASKDATA/config not found. Initializing taskd."
    execute taskd init
    execute taskd config --force log $TASKDATA/taskd.log
    execute taskd config --force pid.file /taskd.pid
    execute taskd config --force server 0.0.0.0:53589
fi;


if [ ! -f $TASKDATA/pki/ca.cert.pem ]; then
    echo '===> No certificates found. Initializing self-signed ones.'
    cd $TASKDATA/pki
    execute ./generate

    execute taskd config --force client.cert $TASKDATA/pki/client.cert.pem
    execute taskd config --force client.key  $TASKDATA/pki/client.key.pem
    execute taskd config --force server.cert $TASKDATA/pki/server.cert.pem
    execute taskd config --force server.key  $TASKDATA/pki/server.key.pem
    execute taskd config --force server.crl  $TASKDATA/pki/server.crl.pem
    execute taskd config --force ca.cert     $TASKDATA/pki/ca.cert.pem
else
    echo '===> Certificates already exist'
fi;

if [ ! -f $TASKDATA/pki/default-client.key.pem ]; then
    echo '===> No users setup yet. Setting up organization Default with user Default'
    execute taskd add org Default
    execute taskd add user Default Default
    cd $TASKDATA/pki
    ./generate.client default-client
fi;

echo ""
echo ""
echo "You are all set to use taskd."
echo "Execute the following steps to setup your client:"
echo "1. Get the keys data/pki/default-client.{key,cert}.pem"
echo "   & ca.cert.pem and place them in ~/.task/"
echo "2. Execute on your client:"
echo "  $ task config taskd.certificate -- ~/.task/default-client.cert.pem"
echo "  $ task config taskd.key         -- ~/.task/default-client.key.pem"
echo "  $ task config taskd.cat         -- ~/.task/cat.cert.pem"
echo "  $ task config taskd.server      -- host.domain:53589"
echo "  $ task config taskd.credentials -- Default/Default/$(ls $TASKDATA/orgs/Default/users)"
echo ""
echo ""


execute taskd server --data $TASKDATA