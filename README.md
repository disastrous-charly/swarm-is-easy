# Generate auto-signed TLS certificates for your docker swarm cluster

An entrypoint for people seeking resources about how we can deploy a docker swarm cluster, securize docker connection, generate certificates.
It's really simple with docker machine, but I had difficulties finding online tutorial.

The script is not perfect, you have to enter informations about certificates.
Think to fill the "common name" field with the hostname of your machine.

##How it works
Docker swarm require the same Certificate Authority to sign the swarm master, which control the cluster, and the nodes.
1) The script generate the CA, the certificate to make the swarm master running under TLS.
2) Generating the client keys, so you'll have access to your master (could be useful).
3) Send via ssh the CA to the nodes, and generates certificate.
4) Change the systemd startup script of docker to use the certificate and listen port 2376. (not working if you're not using systemd)
5) Use the new_swarm.sh script to launch swarm container on node & swarm controller on master with the certificate.
6) Tada ! (Or maybe it's not working, i'm sorry)
##To read :

[Docker TLS documentation](http://docs.docker.com/engine/articles/https/)

[Docker Swarm documentation](https://docs.docker.com/swarm/)

####The excellent Sheerun :

[His blog for explanation on how docker with TLS works](http://sheerun.net/2014/05/17/remote-access-to-docker-with-tls/)

[His script to securize docker](https://gist.github.com/sheerun/ccdeff92ea1668f3c75f)


Special thanks to [Armand Grillet](https://github.com/ArmandGrillet) for loosing his hair trying to solve this problem on the first versions of docker swarm.
