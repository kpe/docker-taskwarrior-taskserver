

# about
A GCP docker image for [taskwarrior](https://github.com/GothenburgBitFactory/taskwarrior)'s [taskserver](https://github.com/GothenburgBitFactory/taskserver)

Forked from https://github.com/j6s/docker-taskwarrior-taskserver
and modified for GCP to build with cloudbuild and run in GCE).

# gcp
To run in GCP build with cloudbuild, and make sure to run the container as `--priviliged`, mounting `/dev/fuse` read-only.

# client config
Check the logs in the running container for instructions, i.e.:
```bash
You are all set to use taskd.
Execute the following steps to setup your client:
1. Get the keys data/pki/default-client.{key,cert}.pem and ca.cert.pem

  export DOCKER=docker
  export CID=62b7c25b44a1
  mkdir -p ~/.task/pki/
  $DOCKER exec $CID tar cz -C /data/pki/ default-client.{key,cert}.pem ca.cert.pem | tar xzv -C ~/.task/pki/

In GCP you might use:

  export DOCKER='gcloud compute ssh intance-name -- docker' 

2. Execute on your client:
  task config taskd.certificate -- ~/.task/pki/default-client.cert.pem
  task config taskd.key         -- ~/.task/pki/default-client.key.pem
  task config taskd.ca          -- ~/.task/pki/ca.cert.pem
  task config taskd.credentials -- Default/Default/ac69d392-0916-4d57-8b06-fcecd6255ebb
  task config taskd.server      -- host.domain:53589

```

# devenv

To run locally with podman:

```bash
podman build -t taskserver .
podman run -ti \
 -p 53589:53589 \
 -v $(pwd)/data:/data:Z --userns=keep-id --user=$(id -ur):$(id -gr) \
 --entrypoint=/bin/bash \
 taskserver
```
