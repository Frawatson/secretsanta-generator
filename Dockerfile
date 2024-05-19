# Stage 1: Build the application
FROM maven:3.8.1-jdk-8 AS build

WORKDIR /usr/src/app

COPY pom.xml .

RUN mvn dependency:go-offline

COPY src ./src

RUN mvn package

# Stage 2: Create the runtime image
FROM openjdk:8u151-jdk-alpine3.7

ENV APP_HOME /usr/src/app

COPY --from=build /usr/src/app/target/secretsanta-0.0.1-SNAPSHOT.jar $APP_HOME/app.jar

WORKDIR $APP_HOME

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]