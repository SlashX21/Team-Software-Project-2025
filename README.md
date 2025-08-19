# README

# Backend
## 1. First Time Use
cd Team-Project-FinalBackend

### activate Docker & check on Docker version
docker --version
docker-compose --version

### ensure there are return as so
Docker version 27.2.0, build 3ab4256
Docker Compose version 2.26.1

### clean and activate all services
mvn clean package -DskipTests && docker compose up -d

you may now start your frontend

## 2. Future Use
docker-compose up -d             # direct activation


## 3. Database Connection
### connection to mysql container
docker-compose exec mysql mysql -uroot -p123456+a

### check database
SHOW DATABASES;
USE springboot_demo;
SHOW TABLES;

# Frontend
Please use the apk provided on android devices, this will connect to our Azure platform. To launch our frontend locally, follow the instruction below

## 1. First Time Use
cd 8.5-finalFrontend
flutter create .
flutter pub get

### activation
flutter run

### select your desire platform

## 2. Future Use
flutter run
