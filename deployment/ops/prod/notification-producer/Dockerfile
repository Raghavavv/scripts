FROM openjdk:11
ENV SPRING_PROFILES_ACTIVE prod
RUN mkdir -p /root/bizom/
COPY ./deployables/notification-producer/target/notification-producer-1.0-SNAPSHOT.war /root/bizom
WORKDIR /root/bizom
EXPOSE 8080
CMD ["java", "-jar", "/root/bizom/notification-producer-1.0-SNAPSHOT.war"]
