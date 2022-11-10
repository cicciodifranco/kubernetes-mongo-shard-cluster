#!/bin/bash
#Creating and exposing config deployments

#Including config file
source config
echo -e "Deleting config nodes"
kubectl delete -f mongo_config.yaml

echo -e "\nDeleting shard nodes"
for ((rs=1; rs<=$SHARD_REPLICA_SET; rs++)) do
    kubectl delete -f  mongo_sh_$rs.yaml
done

echo -e "\nDeleting router nodes"
kubectl delete -f mongos.yaml
