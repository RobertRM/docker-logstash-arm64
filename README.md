# Docker Logstash for ARM64 
Dockerfile for Logstash that runs on ARM64

## How To Check It Works 
```
git clone https://github.com/RobertRM/docker-logstash-arm64 && cd docker-logstash-arm64
docker-compose up
```

## Build Image For Use
Use the bash script:
```
sh ./build_image.sh
```
or build directly
```
docker build -t robertrm/docker-logstash-arm64:7.10.1 .
```
