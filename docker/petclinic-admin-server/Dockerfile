# TODO : study https://spring.io/guides/gs/spring-boot-docker/
# ==> with this maven plugin, there is no more need of Dockerfile
# ./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=springio/gs-spring-boot-docker

# Multi-Stage pipeline: 

# docker build --build-arg --no-cache -t "petclinic-admin-server" -f "./docker/petclinic-admin-server/Dockerfile" .
# docker image ls
# docker run petclinic-admin-server -p 8080:8080
# docker container ls
# docker ps
# docker exec -it b177880414c5 /bin/sh
# docker inspect --format '{{ .NetworkSettings.Networks.bridge.IPAddress }}' <container>  

# https://docs.microsoft.com/en-us/java/openjdk/containers
FROM mcr.microsoft.com/openjdk/jdk:11-mariner as builder
LABEL Maintainer="pinpin <noname@microsoft.com>"
LABEL Description="PetClinic admin-server: Java Spring Boot microservice built from MS OpenJDK 11-Mariner"

# ARG MAVEN_VERSION=3.8.4  

RUN java -version
RUN ls -al /usr/lib/jvm/msopenjdk-11

RUN mkdir /tmp/app
WORKDIR /tmp/app
COPY "./spring-petclinic-admin-server/target/*.jar" /tmp/app/app.jar

# RUN yum install maven -y

# RUN wget https://dlcdn.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
# RUN unzip apache-maven-$MAVEN_VERSION-bin.zip
# "RUN tar xzvf apache-maven-$MAVEN_VERSION-bin.tar.gz
# RUN export PATH=apache-maven-$MAVEN_VERSION/bin:$PATH

# RUN mvn clean spring-javaformat:apply 
# RUN mvn package -DskipTests

# https://spring.io/blog/2020/01/27/creating-docker-images-with-spring-boot-2-3-0-m1
# https://www.baeldung.com/docker-layers-spring-boot
RUN java -Djarmode=layertools -jar "/tmp/app/app.jar" extract


# wget is not installed on adoptopenjdk:11-jre-hotspot
FROM mcr.microsoft.com/openjdk/jdk:11-mariner
WORKDIR /tmp/app
# VOLUME /tmp
COPY --from=builder /tmp/app/dependencies/ ./
COPY --from=builder /tmp/app/snapshot-dependencies/ ./
COPY --from=builder /tmp/app/spring-boot-loader/ ./
COPY --from=builder /tmp/app/application/ ./
# COPY --from=builder /tmp/app/target/*.jar app.jar
# COPY target/*.jar app.jar
# RUN touch /app.jar
EXPOSE 8080 8081 8888 9090

ENV SPRING_PROFILES_ACTIVE docker

ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]
# ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/tmp/app/app.jar"]