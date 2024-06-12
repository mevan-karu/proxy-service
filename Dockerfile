FROM ballerina/ballerina:2201.9.0

ADD . /proxy_service

WORKDIR /proxy_service

USER root

RUN bal build

FROM eclipse-temurin:17.0.11_9-jre-focal

ARG USER=app-user
ARG USER_ID=10001
ARG USER_GROUP=wso2
ARG USER_GROUP_ID=10001
ARG USER_HOME=/home/${USER}

RUN apt-get update && apt-get install -y gnupg2

RUN wget -qO - https://pkgs-ce.cossacklabs.com/gpg | apt-key add - && apt install -y apt-transport-https && echo "deb https://pkgs-ce.cossacklabs.com/stable/ubuntu focal main" >> /etc/apt/sources.list.d/cossacklabs.list && apt update && apt install -y libthemis libthemis-jni && cp /usr/lib/$(uname -m)-linux-gnu/jni/libthemis_jni.so /usr/lib

RUN addgroup --system --gid ${USER_GROUP_ID} ${USER_GROUP} \
    && adduser --system -D -H -h ${USER_HOME} --disabled-login -G ${USER_GROUP} -u ${USER_ID} ${USER}

COPY --chown=${USER}:${USER_GROUP} --from=0 /proxy_service/target/bin/proxy_service.jar ${USER_HOME}/

USER 10001
WORKDIR ${USER_HOME}

CMD ["java", "-jar", "proxy_service.jar"]
