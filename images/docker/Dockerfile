FROM telephoneorg/debian:stretch

LABEL maintainer="Alexander Mustafin <mustafin.aleksandr@gmail.com>"

ENV APP yeti-web
ENV USER $APP
ENV HOME /home/$APP

ENV ROLE yeti

ENV YETIWEB_ADDRESS 0.0.0.0
ENV YETIWEB_LISTEN 3000
ENV YETIWEB_WORKERS 4
ENV YETIWEB_LOG_LEVEL info

ENV ROUTING_DB_NAME yeti
ENV ROUTING_POSTGRES_HOST 127.0.0.1
ENV ROUTING_POSTGRES_PORT 5432
ENV ROUTING_POSTGRES_USER yeti
ENV ROUTING_POSTGRES_PASSWORD yeti123

ENV CDR_DB_NAME cdr
ENV CDR_POSTGRES_HOST 127.0.0.1
ENV CDR_POSTGRES_PORT 5432
ENV CDR_POSTGRES_USER yeti
ENV CDR_POSTGRES_PASSWORD yeti123

ARG BUILD=master

COPY build.sh /tmp/build.sh
RUN /tmp/build.sh

#Set working directory
WORKDIR $HOME

# Expose a volume so that nginx will be able to read in assets in production.
VOLUME ["$HOME"]

HEALTHCHECK --interval=5m --timeout=3s \
  CMD curl -f http://$YETIWEB_ADDRESS:$YETIWEB_LISTEN/ || exit 1

SHELL ["/bin/bash", "-lc"]

COPY entrypoint /

# The default command that gets ran will be to start the Unicorn server.
ENTRYPOINT ["/dumb-init", "--"]
CMD ["/entrypoint"]
