FROM openjdk:11
ENV SPRING_PROFILES_ACTIVE staging
ENV LOG_PATH /dev/stdout
WORKDIR /root/bizom/
COPY ./deployables/map-service/target/mapservice-1.0-SNAPSHOT.war /root/bizom
EXPOSE 8090
CMD ["java", "-jar", "/root/bizom/mapservice-1.0-SNAPSHOT.war"]
