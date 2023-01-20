# docker build --build-arg --no-cache -t "petclinic-config-server" -f "./docker/petclinic-config-server/Dockerfile" .
# docker tag petclinic-config-server acrpetcliaks.azurecr.io/petclinic/petclinic-config-server
# docker push acrpetcliaks.azurecr.io/petclinic/petclinic-config-server
# docker pull acrpetcliaks.azurecr.io/petclinic/petclinic-config-server
# docker image ls
# docker run -p 8080:8080 -p 8081:8081 -p 8888:8888 -p 9090:9090 petclinic-config-server
# docker container ls
# docker ps
# docker exec -it <container-id> /bin/sh

# https://docs.microsoft.com/en-us/java/openjdk/containers
FROM mcr.microsoft.com/openjdk/jdk:11-mariner as builder
ENV APPI_VERSION="3.4.7"
ENV APP_INSIGHTS_AGENT_JAR_FILE_PATH="/tmp/app/applicationinsights-agent-${APPI_VERSION}.jar"
LABEL Maintainer="pinpin <noname@microsoft.com>"
LABEL Description="PetClinic Config Server: Java Spring Boot microservice built from MS OpenJDK 11-Mariner"
RUN mkdir /tmp/app
WORKDIR /tmp/app
COPY "./spring-petclinic-config-server/target/*.jar" /tmp/app/app.jar
RUN java -Djarmode=layertools -jar "/tmp/app/app.jar" extract
RUN curl -SL --output ${APP_INSIGHTS_AGENT_JAR_FILE_PATH} https://github.com/microsoft/ApplicationInsights-Java/releases/download/${APPI_VERSION}/applicationinsights-agent-${APPI_VERSION}.jar

FROM mcr.microsoft.com/openjdk/jdk:11-mariner
WORKDIR /tmp/app
ENV APPI_VERSION="3.4.7"
ENV APP_INSIGHTS_AGENT_JAR_FILE_PATH="/tmp/app/applicationinsights-agent-${APPI_VERSION}.jar"
ENV APPLICATIONINSIGHTS_CONFIGURATION_FILE="BOOT-INF/classes/applicationinsights.json"
ENV SPRING_PROFILES_ACTIVE = "docker,mysql"
# https://github.com/Azure/azure-cli/issues/20413
# https://github.com/Azure/acr-build/issues/10
# https://stackoverflow.com/questions/51115856/docker-failed-to-export-image-failed-to-create-image-failed-to-get-layer
# https://github.com/moby/moby/issues/37965
COPY --from=builder ${APP_INSIGHTS_AGENT_JAR_FILE_PATH}/ ./
COPY --from=builder /tmp/app/dependencies/ ./
COPY --from=builder /tmp/app/snapshot-dependencies/ ./
RUN true
COPY --from=builder /tmp/app/spring-boot-loader/ ./
RUN true
COPY --from=builder /tmp/app/application/ ./
EXPOSE 80 8080 8081 8082 8083 8084 8888 9090

ENTRYPOINT ["java", "-javaagent:/tmp/app/applicationinsights-agent-${APPI_VERSION}.jar", "org.springframework.boot.loader.JarLauncher", "--server.port=8888"]