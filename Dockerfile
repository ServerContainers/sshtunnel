FROM debian:stretch

ENV DEBIAN_FRONTEND noninteractive                     
                                                                       
RUN apt-get -q -y update \                           
 && apt-get -q -y install --no-install-recommends openssh-server \                                  
 && apt-get -q -y clean \
 && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
 \
 && mkdir /run/sshd

EXPOSE 22

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
