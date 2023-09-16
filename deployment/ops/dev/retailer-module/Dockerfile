FROM openjdk:11
ENV SPRING_PROFILES_ACTIVE dev
RUN mkdir -p /root/bizom/
COPY ./deployables/retailer-module/target/retailer-module-1.0-SNAPSHOT.war /root/bizom
EXPOSE 9092
CMD ["java", "-jar", "/root/bizom/retailer-module-1.0-SNAPSHOT.war"]
