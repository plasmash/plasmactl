FROM alpine:3.22

WORKDIR /host
ARG USER_ID
ARG USER_NAME
ARG GROUP_ID

RUN adduser -D -u ${USER_ID} -g ${GROUP_ID} -h /home/${USER_NAME} ${USER_NAME} \
    && chown -R ${USER_NAME}:${USER_NAME} /host \
    && apk upgrade --update-cache -a && apk add \
      curl \
      jq \
      bash \
    && rm -fr /var/cache/apk/*

USER ${USER_NAME}
