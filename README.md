# Generate auto-signed TLS certificates for your docker swarm cluster

An entrypoint for people seeking resources about how we can deploy a docker swarm cluster, securize docker connection, generate certificates.
It's really simple with docker machine, but I had difficulties finding online tutorial.

The script is not perfect, you have to enter informations about certificates.
Think to fill the "common name" field with the hostname of your machine.

To read : 
[Docker TLS documentation](http://docs.docker.com/engine/articles/https/)
[Docker Swarm documentation](https://docs.docker.com/swarm/)
The excellent Sheerun :
[His blog for explanation](http://sheerun.net/2014/05/17/remote-access-to-docker-with-tls/)
[His script to securize docker](https://gist.github.com/sheerun/ccdeff92ea1668f3c75f)
