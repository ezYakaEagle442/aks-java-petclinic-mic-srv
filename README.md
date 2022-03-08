# Distributed version of the Spring PetClinic Sample Application deployed to AKS

[![Build Status](https://github.com/spring-petclinic/spring-petclinic-microservices/actions/workflows/maven-build.yml/badge.svg)](https://github.com/spring-petclinic/spring-petclinic-microservices/actions/workflows/maven-build.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

This microservices branch was initially derived from [AngularJS version](https://github.com/spring-petclinic/spring-petclinic-angular1) to demonstrate how to split sample Spring application into [microservices](http://www.martinfowler.com/articles/microservices.html).
To achieve that goal we use IaC with Azure Bicep, MS build of OpenJDK 11, GitHub Actions, Azure Container Registry, Azure AD Workload Identity, Azure Key Vault, Open Service Mesh (OSM), Azure Database for MySQL


## Starting services locally without Docker

Quick local test just to verify that the jar files can be run (the routing will not work out of a K8S cluster, and also the apps will fail to start as soon as management port 8081 will be already in use by config server ...) : 
```sh
mvn package -Dmaven.test.skip=true
java -jar spring-petclinic-config-server\target\spring-petclinic-config-server-2.6.3.jar --server.port=8888
java -jar spring-petclinic-admin-server\target\spring-petclinic-admin-server-2.6.3.jar --server.port=9090
java -jar spring-petclinic-visits-service\target\spring-petclinic-visits-service-2.6.3.jar --server.port=8082 # --spring.profiles.active=docker
java -jar spring-petclinic-vets-service\target\spring-petclinic-vets-service-2.6.3.jar --server.port=8083
java -jar spring-petclinic-customers-service\target\spring-petclinic-customers-service-2.6.3.jar --server.port=8084
java -jar spring-petclinic-api-gateway\target\spring-petclinic-api-gateway-2.6.3.jar --server.port=8085
```

Every microservice is a Spring Boot application and can be started locally. 
Please note that supporting services (Config Server) must be started before any other application (Customers, Vets, Visits and API).
Startup Admin server is optional.
If everything goes well, you can access the following services at given location:
* AngularJS frontend (API Gateway) - http://localhost:8080
* Admin Server (Spring Boot Admin) - http://localhost:9090


The `master` branch uses an MS openjdk/jdk:11-mariner Docker base.


## Understanding the Spring Petclinic application

[See the presentation of the Spring Petclinic Framework version](http://fr.slideshare.net/AntoineRey/spring-framework-petclinic-sample-application)

[A blog bost introducing the Spring Petclinic Microsevices](http://javaetmoi.com/2018/10/architecture-microservices-avec-spring-cloud/) (french language)

You can then access petclinic here: http://localhost:8080/

![Spring Petclinic Microservices screenshot](docs/application-screenshot.png)


**Architecture diagram of the Spring Petclinic Microservices**

![Spring Petclinic Microservices architecture](docs/microservices-architecture-diagram.jpg)

The UI code is located at spring-petclinic-api-gateway\src\main\resources\static\scripts.

The Spring Cloud Gateway routing is configuted at spring-petclinic-api-gateway\src\main\resources\application.yml

The OpenShift routing is configured in the Ingress resources at :
- spring-petclinic-api-gateway\k8s\petclinic-ui-ingress.yaml
- spring-petclinic-admin-server\k8s\petclinic-admin-server-ingress.yaml
- spring-petclinic-config-server\k8s\petclinic-config-server-ingress.yaml
- spring-petclinic-customers-service\k8s\petclinic-customer-ingress.yaml
- spring-petclinic-vets-service\k8s\petclinic-vet-ingress.yaml
- spring-petclinic-visits-service\k8s\petclinic-visits-ingress.yaml

The Git repo URL used by Spring config is set in spring-petclinic-config-server\src\main\resources\application.yml

If you want to know more about the Spring Boot Admin server, you might be interested in [https://github.com/codecentric/spring-boot-admin](https://github.com/codecentric/spring-boot-admin)

## Database configuration

In its default configuration, Petclinic uses an in-memory database (HSQLDB) which gets populated at startup with data.
A similar setup is provided for MySql in case a persistent database configuration is needed.
Dependency for Connector/J, the MySQL JDBC driver is already included in the `pom.xml` files.


### Set MySql connection String

You need to reconfigure the MySQL connection string with your own settings (you can get it from the Azure portal / petcliaro-mysql-server / Connection strings / JDBC):
In the spring-petclinic-microservices-config/blob/main/application.yml :
```
spring:
  config:
    activate:
      on-profile: mysql
  datasource:
    schema: classpath*:db/mysql/schema.sql
    data: classpath*:db/mysql/data.sql
    # url: jdbc:mysql://localhost:3306/petclinic?useSSL=false
    url: jdbc:mysql://petcliaro-mysql-server.mysql.database.azure.com:3306/petclinic?useSSL=true&requireSSL=true&enabledTLSProtocols=TLSv1.2&verifyServerCertificate=false
    username: mys_adm
    password: IsTrator42!
    initialization-mode: ALWAYS
```

You can check the DB connection with this [sample project](https://github.com/Azure-Samples/java-on-azure-examples/tree/main/databases/mysql/get-country).


### Use the Spring 'mysql' profile

To use a MySQL database, you have to start 3 microservices (`visits-service`, `customers-service` and `vets-services`)
with the `mysql` Spring profile. Add the `--spring.profiles.active=mysql` as programm argument.

By default, at startup, database schema will be created and data will be populated.
You may also manually create the PetClinic database and data by executing the `"db/mysql/{schema,data}.sql"` scripts of each 3 microservices. 
In the `application.yml` of the [Configuration repository], set the `initialization-mode` to `never`.

If you are running the microservices with Docker, you have to add the `mysql` profile into the (Dockerfile)[docker/Dockerfile]:
```
ENV SPRING_PROFILES_ACTIVE docker,mysql
```
In the `mysql section` of the `application.yml` from the [Configuration repository], you have to change 
the host and port of your MySQL JDBC connection string. 


## CI/CD

### Use GitHub Actions to deploy the Java microservices

See GitHub [Actions section](./.github/workflows/aks-deploy.yml)

## Observability

TODO !

## Scaling

TODO !

## Resiliency

Circuit breakers
TODO !

## Security
### secret Management
Azure AD Workload Identity and Azure Key Vault : TODO !

## DNS Management

### Custom metrics
Spring Boot registers a lot number of core metrics: JVM, CPU, Tomcat, Logback... 
The Spring Boot auto-configuration enables the instrumentation of requests handled by Spring MVC.
All those three REST controllers `OwnerResource`, `PetResource` and `VisitResource` have been instrumented by the `@Timed` Micrometer annotation at class level.

* `customers-service` application has the following custom metrics enabled:
  * @Timed: `petclinic.owner`
  * @Timed: `petclinic.pet`
* `visits-service` application has the following custom metrics enabled:
  * @Timed: `petclinic.visit`


## Interesting Spring Petclinic forks

The Spring Petclinic `main` branch in the main [spring-projects](https://github.com/spring-projects/spring-petclinic)
GitHub org is the "canonical" implementation, currently based on Spring Boot and Thymeleaf.

This [spring-petclinic-microservices](https://github.com/spring-petclinic/spring-petclinic-microservices/) project is one of the [several forks](https://spring-petclinic.github.io/docs/forks.html) 
hosted in a special GitHub org: [spring-petclinic](https://github.com/spring-petclinic).
If you have a special interest in a different technology stack
that could be used to implement the Pet Clinic then please join the community there.

See also :
- [MS official Azure Spring Cloud sample](https://github.com/Azure-Samples/spring-petclinic-microservices)
- [Spring Pet Clinic Microservices deployment on AKS](https://github.com/ezYakaEagle442/aks-java-petclinic-mic-srv) including IaC with Azure Bicep, MS build of OpenJDK 11, GitHub Actions, Azure Container Registry, Azure AD Workload Identity and Azure Key Vault.
- [Spring Pet Clinic Microservices deployment on ARO](https://github.com/ezYakaEagle442/aro-java-petclinic-mic-srv) including IaC with Azure Bicep, MS build of OpenJDK 11, Quarkus, OpenShift Pipelines based on Tekton, OpenShift built-in Registry, Azure AD Workload Identity and Azure Key Vault.
- [Spring Pet Clinic Microservices deployment on Azure Container Apps](https://github.com/ezYakaEagle442/aca-java-petclinic-mic-srv) including IaC with Azure Bicep, Dapr, MS build of OpenJDK 11, GitHub Actions, Azure Container Registry, Azure Key Vault.


# Contributing

The [issue tracker](https://github.com/ezYakaEagle442/aks-java-petclinic-mic-srv/issues) is the preferred channel for bug reports, features requests and submitting pull requests.

For pull requests, editor preferences are available in the [editor config](.editorconfig) for easy use in common text editors. Read more and download plugins at <http://editorconfig.org>.


# Credits
[https://github.com/ezYakaEagle442/azure-spring-cloud-petclinic-mic-srv](https://github.com/Azure-Samples/spring-petclinic-microservices) has been forked from [https://github.com/Azure-Samples/spring-petclinic-microservices](https://github.com/Azure-Samples/spring-petclinic-microservices), itself already forked from [https://github.com/spring-petclinic/spring-petclinic-microservices](https://github.com/spring-petclinic/spring-petclinic-microservices)

## Note regarding GitHub Forks
It is not possible to [fork twice a repository using the same user account.](https://github.community/t/alternatives-to-forking-into-the-same-account/10200)
However you can [duplicate a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/duplicating-a-repository)

This repo [https://github.com/ezYakaEagle442/aks-java-petclinic-mic-srv](https://github.com/ezYakaEagle442/aks-java-petclinic-mic-srv) has been duplicated from [https://github.com/spring-petclinic/spring-petclinic-microservices](https://github.com/spring-petclinic/spring-petclinic-microservices)