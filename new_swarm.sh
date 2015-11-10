#!/bin/bash
#launch it on your swarm master to (re)deploy your secure cluster
#in comment the command for unsecure cluster
version=1.0.0
node_list=("donatello","raphael","leonardo","michelangelo")
docker pull swarm:$version
docker rm -f swarm_manager

#create a unique token for the discovery service
token=`docker run --rm swarm create`

for node in ${node_list[@]}
do
  #we launch the swarm node with the token so they will be recognize by our swarm manager
  ssh -t node "docker pull swarm:$version && docker rm -f swarm_node && docker run --name swarm_node --restart=always -d swarm join --addr=$node:2376 token://$token"
done

#launch the swarm manager, we mount our certs folder on the container
docker run -d -p 2376:2375 -v ~/.docker/:/certs/ swarm:1.0.0 manage --tlsverify --tlscacert=/certs/ca.pem --tlscert=/certs/swarm-server/swarm-cert.pem \
--tlskey=/certs/swarm-server/swarm-key.pem token://$token

#when you don't have certificate
#docker run -d -p 2375:2375 --name swarm_manager --restart=always swarm:$version manage token://$token
