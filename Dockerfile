FROM openjdk:8-jdk-alpine
ARG JAR_FILE=hello-world-app/target/*.jar
COPY . .
COPY ${JAR_FILE} app.jar
ENTRYPOINT ["java","-jar","/app.jar","--greeter.greeting=Hola"]

# FROM openjdk:8-jdk-alpine
# ARG JAR_FILE
# COPY ./hello-world-app/target/*.jar app.jar
# ENTRYPOINT ["java", "-jar","/app.jar", "--greeter.greeting=Hola"]