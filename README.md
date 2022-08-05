

# about
A GCP docker image for [taskwarrior](https://github.com/GothenburgBitFactory/taskserver/releases/tag/s1.2.0)'s [taskserver](https://github.com/GothenburgBitFactory/taskserver)

Forked from https://github.com/j6s/docker-taskwarrior-taskserver
and modified for GCP - build with cloudbuild run in GCE).

# devenv

To run locally with podman:

```bash
podman build -t taskserver .
podman run -ti \
 -p 53589:53589 \
 -v $(pwd)/data:/data:Z --userns=keep-id --user=$(id -ur):$(id -gr) \
 taskserver
```
