# Step 1 - generate mongodb key file
```
openssl rand -base64 741 > mongodb.key
kubectl create secret generic mongodb.key --from-file=mongodb.key=./mongodb.key
```

# Step 2 - update mongo_config.yaml