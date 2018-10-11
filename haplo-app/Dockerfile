FROM haplo-base
MAINTAINER Peter Tribble <peter.tribble@haplo.com>
RUN useradd -m -U -G sudo hbuild && echo "hbuild ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER hbuild
ENV USER hbuild
RUN cd /home/hbuild && curl -o haplo-install.sh https://raw.githubusercontent.com/haplo-org/haplo/master/haplo-install.sh && chmod a+x haplo-install.sh && mkdir -p haplo-dev-support/certificates && ./haplo-install.sh && rm -fr haplo-dev-support .m2 && rm -f /tmp/haplo-build.tar && sudo rm -rf /var/lib/apt/lists/*
COPY haplo-run.sh /home/hbuild
EXPOSE 8080 8443
ENTRYPOINT /home/hbuild/haplo-run.sh
