FROM openjdk:11
ENV SPRING_PROFILES_ACTIVE dev
ENV LOG_PATH /tmp/ell-platform.log
RUN mkdir -p /root/bizom/tokens /root/tomcat/logs
RUN ln -sf /dev/stdout /root/tomcat/logs/ell-platform.log
WORKDIR /root/bizom/
COPY ./deployables/ell/target/ell-1.0-SNAPSHOT.war /root/bizom
COPY ./ops/dev/ell/tokens/* /root/bizom/tokens
EXPOSE 8080
CMD ["java", "-jar", "/root/bizom/ell-1.0-SNAPSHOT.war"]
