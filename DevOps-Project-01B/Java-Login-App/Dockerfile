# syntax=docker/dockerfile:1

# ---- Build stage -----------------------------------------------------------
# Compiles the Spring Boot WAR with Maven. pom.xml targets Java 11
# (<java.version>11</java.version>) and depends on Tomcat 9's Jasper
# (tomcat-jasper 9.0.31), so the runtime stage below uses Tomcat 9 / JDK 11
# to match.
FROM maven:3.9-eclipse-temurin-11 AS build

WORKDIR /build

# Copy only the POM first so the dependency layer is cached and re-used
# across builds unless pom.xml itself changes.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q clean package -DskipTests

# ---- Runtime stage ----------------------------------------------------------
# pom.xml declares spring-boot-starter-tomcat with <scope>provided</scope>,
# meaning the WAR expects an external servlet container — it must be
# deployed into Tomcat, not run as an executable jar/war.
FROM tomcat:9.0-jdk11-temurin

# curl is required for the HEALTHCHECK below and is not present in the base image.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Remove Tomcat's bundled webapps (manager, docs, examples, default ROOT)
# so only this application is served, deployed at the context root ("/")
# so it matches app_health_check_path = "/" used by the ALB target group.
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=build /build/target/dptweb-1.0.war /usr/local/tomcat/webapps/ROOT.war

# Must match var.app_port in infrastructure/variables.tf (default 8080) —
# this is the port the launch template's docker run publishes and the
# ALB target group forwards to.
EXPOSE 8080
ENV CATALINA_OPTS="-Xms256m -Xmx512m"

# In-container liveness check. The ALB target group performs the real
# routing health check over HTTP against app_health_check_path.
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

CMD ["catalina.sh", "run"]
