FROM openjdk:11
ENV SPRING_PROFILES_ACTIVE dev
RUN mkdir -p /root/bizom/
WORKDIR /root/bizom/
COPY ./deployables/notification-consumer/target/notification-consumer-1.0-SNAPSHOT.jar /root/bizom
EXPOSE 8080
CMD ["java", "-jar", "/root/bizom/notification-consumer-1.0-SNAPSHOT.jar"]
