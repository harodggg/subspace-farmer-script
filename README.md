# subspace-farmer-script

A very simple script to automatically configure farmer using the docker-compose tool in a docker environment

# Only supports ubuntu 20.04 lts

# 1. Using generate-key and query-balance
## 1.1 Install Python3 Package
```bash
pip3 install -r requirements.txt
```
# 2. Using run-farmer
## 2.1 Init Env

```bash 
    ./run-farmer init
```
<img width="924" alt="image" src="https://user-images.githubusercontent.com/31732456/192086082-54279137-1f56-4be1-8892-8dcae6caf88d.png">


## 2.2 Create Farmer
```bash 
    ./run-farmer create [only-farmer / only-node]
```
<img width="1280" alt="image" src="https://user-images.githubusercontent.com/31732456/192086069-4b17902f-2597-4ac3-b58a-925cb0a2d4a9.png">

## 2.3 Upgrade Farmer
```bash 
    ./run-farmer upgrade [only-farmer / only-node]
```
## 2.4 Delete Farmer
```bash 
    ./run-farmer delete [only-farmer / only,-node]
```

## 2.5 Stop Farmer
```bash 
    ./run-farmer stop [only-farmer / only-node]
```








