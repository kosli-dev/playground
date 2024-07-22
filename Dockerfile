FROM cyberdojo/sinatra-base:d1abcaa
LABEL maintainer=tech-team@kosli.com

WORKDIR /app

COPY --chown=nobody:nogroup code code
COPY --chown=nobody:nogroup config config
RUN chmod +x /app/config/*.sh

USER nobody
HEALTHCHECK --interval=1s --timeout=1s --retries=5 --start-period=5s CMD ./config/healthcheck.sh
ENTRYPOINT [ "/sbin/tini", "-g", "--" ]
CMD [ "/app/config/up.sh" ]
