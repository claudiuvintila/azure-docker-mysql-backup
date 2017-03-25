FROM azuresdk/azure-cli-python:latest

MAINTAINER dimkk@outlook.com
ADD run.sh /run.sh
RUN apk --update add mysql-client && \
    mkdir /backup && \
    chmod +x /run.sh
    

ENV CRON_TIME="0 0 * * *" \
    MYSQL_DB="--all-databases"


VOLUME ["/backup"]
CMD ["/run.sh"]