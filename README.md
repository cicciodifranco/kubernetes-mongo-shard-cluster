# Kubernetes mongodb shard cluster

Mongo db  shard cluster built on kubernetes. This configuration include:
 - 3 node as config replica set
 - 4 shard  with 3 node as replica set for each shard
 - 2 node as mongos router

## Deploy cluster
In your master node do

```sh
chmod +x initiate.sh
./initiate.sh
```
`initate.sh` will deploy for you all pods and will create all needed services.
## Connecting to mongo
For example to connect to your cluster do from a pod
```sh
mongo mongodb://mongos1:27017
```
to view the cluster status from a mongo shell do

```sh
sh.status()
```
and the output should be

```
mongos> sh.status()
--- Sharding Status ---   
...
...
shards:
        {  "_id" : "rs1",  "host" : "rs1/mongosh1-1:27017,mongosh1-2:27017,mongosh1-3:27017",  "state" : 1 }
        {  "_id" : "rs2",  "host" : "rs2/mongosh2-1:27017,mongosh2-2:27017,mongosh2-3:27017",  "state" : 1 }
        {  "_id" : "rs3",  "host" : "rs3/mongosh3-1:27017,mongosh3-2:27017,mongosh3-3:27017",  "state" : 1 }
        {  "_id" : "rs4",  "host" : "rs4/mongosh4-1:27017,mongosh4-2:27017,mongosh4-3:27017",  "state" : 1 }
...

```
## Clean

To remove all pods
```sh
./clean.sh
```

## Deploy different number of shard replica set

- Edit in `config` file `SHARD_REPLICA_SET` and set the desired number
- Create for each additional replica set a file named `mongo_sh_N.yaml`
- Copy content from `mongo_sh_1.yaml`
- Replace all occurrences of `mongosh1` with `mongoshN`  
- Replace all occurrences of `rs1` with `rsN`
