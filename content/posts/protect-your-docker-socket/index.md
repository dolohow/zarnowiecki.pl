---
title: "Protect your Docker socket"
date: 2022-05-18T17:21:54+02:00
summary: Exposing Docker socket is a security issue.  Let us explore
         some solutions.
---

## Abstract
There are some containers that require you to give them access to Docker
socket, so they can work as intended.  An example could be a
[watchtower](https://github.com/containrrr/watchtower/) where the user
exposes docker socket as volume in order to periodically apply updates
to other containers running on your host.

This of course introduces a security problem.  Especially if you expose
such container to the Internet.  An attacker might breach into your
container and then try **jail breaking** from Docker to takeover your
whole system.  One security problem leads to another.

Remember!  Docker is running as `root` on your machine.

## Solution
There are many, and in the future I may or may not extend this article
to accommodate.  Right now, I want to focus on [docker
proxy](https://github.com/Tecnativa/docker-socket-proxy).  What is it?

### Docker proxy
It is a container which has access to your Docker socket and is proxying
request from other containers that utilize Docker API, however it is not
exposed to the Internet by default, and you should not do so just
because you can.  Under the hood it runs
[HAProxy](https://www.haproxy.org) with some rules.

Then, instead of giving full or read only access to your docker socket,
you can just give to the proxy and the proxy should allow only the
minimum amount of privileges to run your desired container.

The following example shows how you should **not do it**:
```yml
services:

  traefik:
    image: traefik
    ports:
      - 443
      - 80
    volumes:
      # Not the most secure way to give container access to your
      # Docker socket.
      - /var/run/docker.sock:/var/run/docker.sock
```

Now, how we can leverage Docker proxy to fix above problem.

How?  Very easily, let's take a look at this `docker-compose.yml`
example:

```yml
services:

  traefik:
    image: traefik
    ports:
      - 443
      - 80
    command:
      - "--providers.docker=true"
      # Dockerproxy listens on 2375, so we need to tell traefik about
      # this
      - "--providers.docker.endpoint=tcp://dockerproxy:2375"

  dockerproxy:
    image: tecnativa/docker-socket-proxy
    restart: always
    environment:
      # Here you specify list of exposed Docker APIs
      CONTAINERS: 1
    volumes:
      # Docker socket is exposed as a read-only to docker proxy but it
      # is not exposed to the Internet
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

In the above example, `traefik` no longer has access to Docker socket,
which is great.  Now `dockerproxy` has, which is not good either, right?
Well, it is not ideal, but `dockerproxy` container is not exposed to the
Internet, therefore attack surface is much, much lower.

We also gave read-only access to `dockerproxy`, because it is
sufficient.  However, there are some containers, which require more
permissions.  In that case, you can create multiple `dockerproxy`
containers for each one of them.

[Click here for full list of permissions](https://github.com/Tecnativa/docker-socket-proxy#grant-or-revoke-access-to-certain-api-sections)
