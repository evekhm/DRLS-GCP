FROM jboss/keycloak:7.0.1
# FROM jboss/keycloak:8.0.2
# FROM jboss/keycloak:9.0.3
COPY ./config/ClientFhirServerRealm.json ./
RUN sed -i 's|__TEST_EHR__|'"$TEST_EHR"'|g; ' ./ClientFhirServerRealm.json
USER 1000
EXPOSE 8080
ENTRYPOINT [ "/opt/jboss/tools/docker-entrypoint.sh", \
        "-Dkeycloak.migration.action=import", \
        "-Dkeycloak.migration.provider=singleFile", \
        "-Dkeycloak.migration.file=./ClientFhirServerRealm.json", \
        "-Dkeycloak.migration.strategy=OVERWRITE_EXISTING" ]
CMD ["-b", "0.0.0.0"]