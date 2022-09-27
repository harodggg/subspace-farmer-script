# Subspace farmer script

A very simple script to automatically configure farmer using the docker-compose tool in a docker environment

# Only supports ubuntu 20.04 lts

# 1. Using generate-key and query-balance

## 1.1 Install Python3 Package

```bash
sudo apt-get install build-essential python3-dev libssl-dev libffi-dev libxml2 libxml2-dev libxslt1-dev zlib1g-dev
```

### Using Python Version >= 3.8

```bash
python3.8 -m pip install upgrade pip  or pip3 install upgrade pip
```

```bash
python3.8 -m pip install -r requirements.txt
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

### 2.2.1 create only farmer

```bash
    docker network create farmer-network
```

```bash
  ./run-farmer create only-farmer
```

<img width="982" alt="image" src="https://user-images.githubusercontent.com/31732456/192369967-166876e3-bf37-421e-849f-51a95da1cc0b.png">

## 2.3 Upgrade Farmer

```bash
    ./run-farmer upgrade [only-farmer / only-node]
```

## 2.4 Delete Farmer

```bash
    ./run-farmer delete [only-farmer / only-node]
```

### 2.4.1 Delete Only-Farmer

```bash
    ./run-farmer delete only-farmer
```

<img width="1310" alt="image" src="https://user-images.githubusercontent.com/31732456/192370351-862d91ce-5e10-4110-a507-b6bd1a4a2f71.png">

## 2.5 Stop Farmer

```bash
    ./run-farmer stop [only-farmer / only-node]
```
