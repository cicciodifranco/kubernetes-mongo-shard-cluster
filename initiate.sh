#!/bin/bash

source config

kubectl apply -f mongodb_pv.yaml

#Creating config nodes
kubectl apply -f  mongo_config.yaml

#Waiting for containers
echo "Waiting config containers"
kubectl get pods | grep "mongocfg" | grep "ContainerCreating"
while [ $? -eq 0 ]
do
  sleep 1
  echo -e "\n\nWaiting the following containers:"
  kubectl get pods | grep "mongocfg" | grep "ContainerCreating"
done

sleep 10

#Initializating configuration nodes
POD_NAME=$(kubectl get pods | grep "mongocfg1" | awk '{print $1;}')
echo "Initializating config replica set... connecting to: $POD_NAME"
CMD='rs.initiate({ _id : "cfgrs", configsvr: true, members: [{ _id : 0, host : "mongocfg1:27017" },{ _id : 1, host : "mongocfg2:27017" },{ _id : 2, host : "mongocfg3:27017" }]})'
kubectl exec -it $POD_NAME -- bash -c "mongosh --port 27017 --eval '$CMD'"

sleep 10

#Creating shard nodes
for ((rs=1; rs<=$SHARD_REPLICA_SET; rs++)) do
  kubectl apply -f  mongo_sh_$rs.yaml

  sleep 10
done

#Waiting for containers
POD_STATUS= kubectl get pods | grep "mongosh" | grep "ContainerCreating"
echo "Waiting shard containers"
kubectl get pods | grep "mongosh" | grep "ContainerCreating"
while [ $? -eq 0 ]
do
  sleep 1
  echo -e "\n\nWaiting the following containers:"
  kubectl get pods | grep "mongosh" | grep "ContainerCreating"
done

sleep 10

#Initializating shard nodes
for ((rs=1; rs<=$SHARD_REPLICA_SET; rs++)) do
  echo -e "\n\n---------------------------------------------------"
  echo "Initializing mongosh$rs"

  #Retriving pod name
  POD_NAME=$(kubectl get pods | grep "mongosh$rs-1" | awk '{print $1;}')
  echo "Pod Name: $POD_NAME"
  CMD="rs.initiate({ _id : \"rs$rs\", members: [{ _id : 0, host : \"mongosh$rs-1:27017\" },{ _id : 1, host : \"mongosh$rs-2:27017\" },{ _id : 2, host : \"mongosh$rs-3:27017\" }]})"
  #Executing cmd inside pod
  echo $CMD
  kubectl exec -it $POD_NAME -- bash -c "mongosh --eval '$CMD'"

  sleep 10
done


#Initializing routers
kubectl apply -f mongos.yaml
echo "Waiting router containers"
kubectl get pods | grep "mongos[0-9]" | grep "ContainerCreating"
while [ $? -eq 0 ]
do
  sleep 1
  echo -e "\n\nWaiting the following containers:"
  kubectl get pods | grep "mongos[0-9]" | grep "ContainerCreating"
done

sleep 10

#Adding shard to cluster
#Retriving pod name
POD_NAME=$(kubectl get pods | grep "mongos1" | awk '{print $1;}')
for ((rs=1; rs<=$SHARD_REPLICA_SET; rs++)) do
  echo -e "\n\n---------------------------------------------------"
  echo "Adding rs$rs to cluster"
  echo "Pod Name: $POD_NAME"

  CMD="sh.addShard(\"rs$rs/mongosh$rs-1:27017\")"
  #Executing cmd inside pod
  echo $CMD
  kubectl exec -it $POD_NAME -- bash -c "mongosh --eval '$CMD'"

  sleep 10
done

#Adding shard to cluster
#Retriving pod name
POD_NAME=$(kubectl get pods | grep "mongos2" | awk '{print $1;}')
for ((rs=1; rs<=$SHARD_REPLICA_SET; rs++)) do
  echo -e "\n\n---------------------------------------------------"
  echo "Adding rs$rs to cluster"
  echo "Pod Name: $POD_NAME"

  CMD="sh.addShard(\"rs$rs/mongosh$rs-1:27017\")"
  #Executing cmd inside pod
  echo $CMD
  kubectl exec -it $POD_NAME -- bash -c "mongosh --eval '$CMD'"

  sleep 10
done

#Adding shard to cluster
#Retriving pod name
POD_NAME=$(kubectl get pods | grep "mongos3" | awk '{print $1;}')
for ((rs=1; rs<=$SHARD_REPLICA_SET; rs++)) do
  echo -e "\n\n---------------------------------------------------"
  echo "Adding rs$rs to cluster"
  echo "Pod Name: $POD_NAME"

  CMD="sh.addShard(\"rs$rs/mongosh$rs-1:27017\")"
  #Executing cmd inside pod
  echo $CMD
  kubectl exec -it $POD_NAME -- bash -c "mongosh --eval '$CMD'"

  sleep 10
done

kubectl exec -it $(kubectl get pods | grep "mongos1" | awk '{print $1;}') -- bash -c "mongosh --eval 'db.createUser({ user: \"aketoan\", pwd: \"@k3t0@ndotVN\", roles: [ \"root\" ]});'"

echo "All done!!!"