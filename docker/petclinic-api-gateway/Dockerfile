# docker build --build-arg --no-cache -t "petclinic-ui" -f "./docker/petclinic-api-gateway/Dockerfile" .
# docker image ls
# docker run -p 8080:8080 -p 8081:8081 -p 8888:8888 -p 9090:9090 petclinic-ui 
# docker container ls
# docker ps
# docker exec -it <container-id> /bin/sh

# https://docs.microsoft.com/en-us/java/openjdk/containers
FROM mcr.microsoft.com/openjdk/jdk:11-mariner as builder
LABEL Maintainer="pinpin <noname@microsoft.com>"
LABEL Description="PetClinic UI client: Java Spring Boot microservice built from MS OpenJDK 11-Mariner"
RUN mkdir /tmp/app
WORKDIR /tmp/app
COPY "./spring-petclinic-api-gateway/target/*.jar" /tmp/app/app.jar
RUN java -Djarmode=layertools -jar "/tmp/app/app.jar" extract

FROM mcr.microsoft.com/openjdk/jdk:11-mariner
WORKDIR /tmp/app
COPY --from=builder /tmp/app/dependencies/ ./
COPY --from=builder /tmp/app/snapshot-dependencies/ ./
COPY --from=builder /tmp/app/spring-boot-loader/ ./
COPY --from=builder /tmp/app/application/ ./
EXPOSE 80 8080 8081 8082 8083 8084 8888 9090

ENV SPRING_PROFILES_ACTIVE docker,mysql

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher", "--server.port=8080", "--spring.profiles.active=docker,mysql"]
# ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/tmp/app/app.jar"]