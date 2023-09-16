FROM openjdk:11
ENV SPRING_PROFILES_ACTIVE prod
COPY ./deployables/access-service/target/access-module-2.0.0.jar /root/
WORKDIR /root/
EXPOSE 9090
CMD ["java", "-jar", "/root/access-module-2.0.0.jar"]
