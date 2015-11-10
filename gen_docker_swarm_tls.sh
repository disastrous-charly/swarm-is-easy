#!/bin/bash

###
# Securize your docker cluster with TLS
# Generate a CA.pem and use it to sign the cert of all the server (swarm master and node)
# Change your systemd docker.service
# /!\ This is not full automate now, you need to enter informations for the certificate,
# like the password, and at "common name" line, your server name (example.com)
#Execute the script on your swarm master
###

#Step 1 : Variables
user='vagrant'
swarm_master=( ["hn"]="splinter" ["ip"]="192.13.37.02")
swarm_node1=( ["hn"]="leonardo" ["ip"]="192.13.37.10")
#swarm_nodes=[swarm_node1,swarm_node2]
path="/home/vagrant/.docker"
mkdir -p $path/swarm-server/
#sudo echo '127.0.1.1 swarm-master' >> /etc/hosts"

#Step 2 : Certificate Authority (CA)

#generate the Certificate authority, which will allow us to sign our certificate
echo 'remember your password, fill the common_name field with your hostname'
openssl genrsa -aes256 -out $path/ca-key.pem 4096
openssl req -new -x509 -days 3650 -key $path/ca-key.pem -sha256 -out $path/ca.pem

#Step 3 : Certificate for the swarm master

#config file
echo "extendedKeyUsage = clientAuth,serverAuth" > $path/swarm-server/extfile.cnf
echo "subjectAltName = IP:${swarm_master["ip"]},IP:127.0.0.1" >> $path/swarm-server/extfile.cnf

#generate key pairs for the server
openssl genrsa -out $path/swarm-server/swarm-key.pem 4096
openssl req -subj "/CN=${swarm_master["hn"]}" -new -key $path/swarm-server/swarm-key.pem -out $path/swarm-server/swarm.csr

#now we have a .csr, certificate signing request
#we sign it with our CA
openssl x509 -req -days 3650 -in $path/swarm-server/swarm.csr -CA $path/ca.pem -CAkey $path/ca-key.pem -CAcreateserial -out $path/swarm-server/swarm-cert.pem -extfile $path/swarm-server/extfile.cnf

#Step 4 : generate client keys

#docker expect to find the client keys, for the server, in /home/user/.docker
#so we're gonna to put them there. But you can refer to the docs to specify a path
#it's the same procedure as before
echo 'extendedKeyUsage = clientAuth,serverAuth' > $path/extfile.cnf
openssl genrsa -out $path/key.pem 4096
openssl req -subj '/CN=client' -new -key $path/key.pem -out $path/client.csr
openssl x509 -req -days 3650 -sha256 -in $path/client.csr -CA $path/ca.pem -CAkey $path/ca-key.pem -CAcreateserial -out $path/cert.pem -extfile $path/extfile.cnf

#this is it!

#Step 5 : now, the node(s)

##docker swarm require the same CA for all the cluster
##o now, we're gonna send the CA to sign & securize the nodes
ssh ${node["ip"]} mkdir $path
#we send the CA files
scp $path/ca.pem ${node["ip"]}:$path
scp $path/ca-key.pem ${node["ip"]}:$path

#config file
ssh -t ${node["ip"]} "echo \"subjectAltName = IP:${node["ip"]},IP:127.0.0.1\" >> $path/extfile.cnf"
#generating, again
ssh -t ${node["ip"]} "openssl genrsa -out $path/server-key.pem 4096"
ssh -t ${node["ip"]} "openssl req -subj '/CN=${node["hn"]}' -new -key $path/server-key.pem -out $path/server.csr"
ssh -t ${node["ip"]} "openssl x509 -req -days 3650 -in $path/server.csr -CA $path/ca.pem -CAkey $path/ca-key.pem -CAcreateserial -out $path/server-cert.pem -extfile $path/extfile.cnf"
#restart
#we don't need client keys here
#now we have our certificates, we tell docker to use them.
#this only work on OS with systemd
ssh -t root@${node["ip"]} "sed -i '/ExecStart=\/usr\/bin\/docker/c\ExecStart=\/usr\/bin\/docker daemon --tlsverify --tlscacert=/home/#{user}/.docker/ca.pem --tlscert=/home/#{user}/.docker/server-cert.pem \
  --tlskey=/home/#{user}/.docker/server-key.pem -H tcp://0.0.0.0:2376 -H fd:\/\/' /lib/systemd/system/docker.service"
#we replace the startup line for docker. We tell docker where are the certificates, and to listen on the port 2376, so we can access it from outside (see docker remote api)
#the -H fd:// option tell docker to listen on local socket

#restart the services
ssh -t root@${node["ip"]} "systemctl daemon-reload && sudo systemctl restart docker.service"

#Now, we launch our swarm cluster
token=`docker run swarm:1.0.0 create`
ssh -t ${node["ip"]} "docker run --name swarm_node -d swarm:1.0.0 join --addr=${node["ip"]}:2376 token://$token"

#launch the swarm manager, we mount our certs folder on the container
docker run -d -p 2376:2375 -v ~/.docker/:/certs/ swarm:1.0.0 manage --tlsverify --tlscacert=/certs/ca.pem --tlscert=/certs/swarm-cert.pem --tlskey=/certs/swarm-key.pem token://$token

#is it working ?
docker --tlsverify -H tcp://${swarm_master["hn"]}:2376 info

#Run an ubuntu container with the docker remote API
curl -H "Content-Type: application/json" -X POST -d '{"image":"ubuntu"}' https://allgo.dev:2376/containers/create --cert ~/.docker/cert.pem --key ~/.docker/key.pem --cacert ~/.docker/ca.pem
