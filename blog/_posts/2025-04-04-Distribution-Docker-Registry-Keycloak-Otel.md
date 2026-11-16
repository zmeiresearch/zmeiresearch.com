---
layout: post
title:  "Docker distribution/registry, or: why version pinning matters"
author: Ivan
date:   2025-04-04 16:22:23 +0300
categories: Docker Registry Distribution OpenTelemetry Keycloak
---

## *Re: Urgent - I get this error*
Thursday afternoon, just before signing off for the day. The last thing I want to see is an email with a subject: 
``` shell
$ docker login -u $CONTAINER_REGISTRY_USERNAME -p $CONTAINER_REGISTRY_PASSWORD $CONTAINER_REGISTRY
Error response from daemon: login attempt to https://registry.XXXXXX/v2/ failed with status: 401 Unauthorized
```
For various reasons we run our own private container registry. Needless to say, without it all development is blocked. Worse still, if a pod needs to be started on another node, the new node MAY not contain the image in its local cache so a pod migration (a normal event in Kubernetes) can actually result in a service outage. I know this registry is a single point of failure, and there's a ticket in the backlog about it.

The setup is quite straightforward: Registry is deployed in k8s behind an LB, uses S3 for storage and Keycloak for AA. It's been worry-free for the past year or so, apart from some semi-periodic clean-up of old cruft (developers are quite prolific and storage fills up quickly). 

Looking at the logs I saw a lot of errors: 
```
time="2025-04-04T09:32:55.822077511Z" level=error msg="traces export: Post \"https://localhost:4318/v1/traces\": dial tcp [::1]:4318: connect: connection refused" environment=development go.version=go1.23.7 instance.id=1df5abf0-2cc7-4268-9d28-b3f4a046ce87 service=registry version=3.0.0
```

So why the hell is the registry all of a sudden trying to reach *localhost:4318*? I happen to know that such a request is actually the service trying to reach out to an [OpenTelemetry (OTel)](https://opentelemetry.io) collector but why would that cause an outage? 

Well, it didn't. Hidden among the thousands of similar **errors** there was also another line:
```
time="2025-04-04T09:30:53.436663295Z" level=info msg="failed to verify token: token signed by untrusted key with ID: \"FML4:7GSU:IBQ4:XXX\""
```

Let that sink in for a moment. I got thousands of **errors** that OTel is unable to post its traces, but I get a single **info** message explaining why my AA setup is not working!

Google led to this issue: [INFO[0101] failed to verify token: token signed by untrusted key with ID](https://github.com/distribution/distribution/issues/4299). It seems the logic inside Registry has changed. Now the Keycloak setup that's been working for some time, and that is done exactly as per Keycloak documentation, needs additional configuration.

But why did it break now? Well, in the deployment I had:
```yaml
kind: Deployment
metadata:
  name: registry
  ...
spec:
  template:
    spec:
      containers:
      - name: registry
        image: registry:latest
```

And guess what? *:latest* just got bumped to *3.0.0* yesterday. So disaster was bound to strike the next time the pod restarted.
For now, I've just changed to **image: registry:2** and that fixed the issue on prod.

However, I feel kind of alienated by the registry maintainers because:
- They knowingly broke token auth for *legacy* implementations. No migration path, not even a mention besides *"docker/libtrust has been replaced with go-jose/go-jose in #4096"*. I certainly don't know what *go-jose* is and don't really care as long as it does not make me do more work. When a [fix/pull request was proposed](https://github.com/distribution/distribution/pull/4417) it was dismissed with what amounts to *We used to do bad things, but now we do only good ones*.
- OTel traces being enabled by default is a PITA. If it were opt-in, fine, I'll just not use it. If there's a way to disable it via a config file option - also somewhat OK. But no, only an environment variable override exists - because configs are too old school I guess (and I know that the actual reason is that the OTel SDK/exporter is actually a third-party component bundled in the image - but it still sucks). So in Kustomize:

  ```yaml
  configMapGenerator:
  - name: registry-new-config
    literals:
    - REGISTRY_LOG_LEVEL="info"
    - OTEL_TRACES_EXPORTER="none"
  ```

We all know it, and we usually do it, but incidents like this remind us how important it is to know exactly what we're running in production, down to the last component.
  
