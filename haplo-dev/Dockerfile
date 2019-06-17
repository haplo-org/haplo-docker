FROM haplo-app
MAINTAINER Peter Tribble <peter.tribble@haplo.com>
USER hbuild
ENV USER hbuild
RUN cd /opt/haplo/etc/properties && sudo sed -i s:no:yes: plugin_debugging_support
