FROM azuresdk/azure-cli-python:latest

MAINTAINER dimkk@outlook.com

RUN apk --update add mysql-client && \
    mkdir /backup

ENV CRON_TIME="0 0 * * *" \
    MYSQL_DB="--all-databases"

ADD run.sh /run.sh
VOLUME ["/backup"]
CMD ["/run.sh"]