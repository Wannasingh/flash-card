# ---- Build Stage ----
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app

# Copy Maven wrapper and pom.xml first for layer caching
COPY pom.xml .
COPY .mvn/ .mvn/
COPY mvnw .
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B

# Copy source code and build
COPY src/ src/
RUN ./mvnw package -DskipTests -B

# ---- Runtime Stage ----
FROM eclipse-temurin:21-jre
WORKDIR /app

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser appuser

COPY --from=build /app/target/*.jar app.jar

# Use non-root user
USER appuser

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"]
