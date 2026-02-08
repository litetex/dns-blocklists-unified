FROM alpine:3

RUN apk add --no-cache bash curl dos2unix

# Copy scripts
RUN mkdir /scripts
WORKDIR /scripts

ADD scripts/ /scripts/
# Make all sh files executable
RUN find . -type f -name '*.sh' | xargs chmod +x

WORKDIR "/workdir"

ENTRYPOINT [ "/scripts/init.sh" ]
