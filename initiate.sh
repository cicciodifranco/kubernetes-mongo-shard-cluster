#!/bin/bash

source config

#set -e


#Creating config nodes
kubectl create -f  mongo_config.yaml

#Waiting for containers
echo "Waiting config containers"
kubectl get pods | grep "mongocfg" | grep "ContainerCreating"
while [ $? -eq 0 ]
do
  sleep 1
  echo -e "\n\nWaiting the following containers:"
  kubectl get pods | grep "mongocfg" | grep "ContainerCreating"
done


#Initializating configuration nodes
POD_NAME=$(kubectl get pods | grep "mongocfg1" | awk '{print $1;}')
echo "Initializating config replica set... connecting to: $POD_NAME"
CMD='rs.initiate({ _id : "cfgrs", configsvr: true, members: [{ _id : 0, host : "mongocfg1:27019" },{ _id : 1, host : "mongocfg2:27019" },{ _id : 2, host : "mongocfg3:27019" }]})'
kubectl exec -it $POD_NAME -- bash -c "mongo --port 27019 --eval '$CMD'"



#Creating shard nodes
for ((rs=1; rs<=$SHARD_REPLICA_SET; rs++)) do
    kubectl create -f  mongo_sh_$rs.yaml
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
    kubectl exec -it $POD_NAME -- bash -c "mongo --eval '$CMD'"

done


#Initializing routers
kubectl create -f mongos.yaml
echo "Waiting router containers"
kubectl get pods | grep "mongos[0-9]" | grep "ContainerCreating"
while [ $? -eq 0 ]
do
  sleep 1
  echo -e "\n\nWaiting the following containers:"
  kubectl get pods | grep "mongos[0-9]" | grep "ContainerCreating"
done


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
    kubectl exec -it $POD_NAME -- bash -c "mongo --eval '$CMD'"

done

echo "All done!!!"