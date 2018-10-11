FROM haplo-app
MAINTAINER Peter Tribble <peter.tribble@haplo.com>
COPY app.values haplo-app.sh /home/hbuild/
USER hbuild
ENV USER hbuild
RUN cd /home/hbuild && ./haplo-app.sh
