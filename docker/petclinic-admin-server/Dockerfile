# TODO : study https://spring.io/guides/gs/spring-boot-docker/
# ==> with this maven plugin, there is no more need of Dockerfile
# ./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=springio/gs-spring-boot-docker

# Multi-Stage pipeline: 

# /!\ ACR is set with Managed Identity: https://learn.microsoft.com/en-us/azure/container-registry/container-registry-authentication-managed-identity?tabs=azure-cli

# docker build --build-arg --no-cache -t "petclinic-admin-server" -f "./docker/petclinic-admin-server/Dockerfile" .
# docker tag petclinic-admin-server acrpetcliaks.azurecr.io/petclinic/petclinic-admin-server
# az acr login --name acrpetcliaks.azurecr.io -u $acr_usr -p $acr_pwd
  
# docker push acrpetcliaks.azurecr.io/petclinic/petclinic-admin-server
# docker pull acrpetcliaks.azurecr.io/petclinic/petclinic-admin-server
# docker image ls
# docker run -p 8080:8080 -p 8081:8081 -p 8888:8888 -p 9090:9090 petclinic-admin-server 
# docker container ls
# docker ps
# docker exec -it b177880414c5 /bin/sh
# docker inspect --format '{{ .NetworkSettings.Networks.bridge.IPAddress }}' <container>  
# docker images --filter reference=petclinic-admin-server --format "{{.Tag}}"

# https://docs.microsoft.com/en-us/java/openjdk/containers
FROM mcr.microsoft.com/openjdk/jdk:11-mariner as builder
ENV APPI_VERSION="3.4.4"
ENV APP_INSIGHTS_AGENT_JAR_FILE_PATH="/tmp/app/applicationinsights-agent-${APPI_VERSION}.jar"

LABEL Maintainer="pinpin <noname@microsoft.com>"
LABEL Description="PetClinic admin-server: Java Spring Boot microservice built from MS OpenJDK 11-Mariner"

# ARG MAVEN_VERSION=3.8.4  

RUN java -version
RUN ls -al /usr/lib/jvm/msopenjdk-11

RUN mkdir /tmp/app
WORKDIR /tmp/app

COPY "spring-petclinic-admin-server/target/*.jar" /tmp/app/app.jar

# RUN yum install maven -y

# RUN wget https://dlcdn.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz
# RUN unzip apache-maven-$MAVEN_VERSION-bin.zip
# "RUN tar xzvf apache-maven-$MAVEN_VERSION-bin.tar.gz
# RUN export PATH=apache-maven-$MAVEN_VERSION/bin:$PATH

# RUN mvn clean spring-javaformat:apply 
# RUN mvn package -DskipTests

# https://spring.io/blog/2020/01/27/creating-docker-images-with-spring-boot-2-3-0-m1
# https://www.baeldung.com/docker-layers-spring-boot

# https://docs.docker.com/engine/reference/builder/#environment-replacement

# Spring Cloud for Azure params required to get secrets from Key Vault.
# those secrets will be injected from Bicep while creating the ACA Apps
# ENV AZURE_CLIENT_ID=ThisIsASecretValue
# ENV AZURE_CLIENT_SECRET=ThisIsASecretValue
# ENV AZURE_KEY_VAULT_ENDPOINT=ThisIsASecretValue
# ENV AZURE_TENANT_ID=ThisIsASecretValue


RUN curl -SL --output ${APP_INSIGHTS_AGENT_JAR_FILE_PATH} https://github.com/microsoft/ApplicationInsights-Java/releases/download/${APPI_VERSION}/applicationinsights-agent-${APPI_VERSION}.jar
RUN java -Djarmode=layertools -jar "/tmp/app/app.jar" extract

# wget is not installed on adoptopenjdk:11-jre-hotspot
FROM mcr.microsoft.com/openjdk/jdk:11-mariner
WORKDIR /tmp/app
# VOLUME /tmp

ENV APPI_VERSION="3.4.4"
ENV APP_INSIGHTS_AGENT_JAR_FILE_PATH="/tmp/app/applicationinsights-agent-${APPI_VERSION}.jar"
ENV APPLICATIONINSIGHTS_CONFIGURATION_FILE="BOOT-INF/classes/applicationinsights.json"
ENV SPRING_PROFILES_ACTIVE="docker,mysql"
# ENV APPLICATIONINSIGHTS_CONNECTION_STRING=""

RUN ls -al /tmp/app

# https://github.com/Azure/azure-cli/issues/20413
# https://github.com/Azure/acr-build/issues/10
# https://stackoverflow.com/questions/51115856/docker-failed-to-export-image-failed-to-create-image-failed-to-get-layer
# https://github.com/moby/moby/issues/37965
COPY --from=builder ${APP_INSIGHTS_AGENT_JAR_FILE_PATH}/ ./
COPY --from=builder /tmp/app/dependencies/ ./
COPY --from=builder /tmp/app/snapshot-dependencies/ ./
COPY --from=builder /tmp/app/spring-boot-loader/ ./
COPY --from=builder /tmp/app/application/ ./
# COPY --from=builder /tmp/app/target/*.jar app.jar
# COPY target/*.jar app.jar
# RUN touch /app.jar
EXPOSE 80 8080 8081 8082 8083 8084 8888 9090

# https://learn.microsoft.com/en-us/azure/azure-monitor/app/java-spring-boot
ENTRYPOINT ["java", "-javaagent:/tmp/app/applicationinsights-agent-3.4.4.jar", "org.springframework.boot.loader.JarLauncher", "--server.port=9090"]
# ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/tmp/app/app.jar"]
#ENTRYPOINT ["java", "-javaagent:"{$APP_INSIGHTS_AGENT_JAR_FILE_PATH}, "-jar", "/tmp/app/app.jar" , "--server.port=9090", "--spring.profiles.active=docker,mysql"]