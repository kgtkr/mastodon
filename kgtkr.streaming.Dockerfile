ARG BASE_TAG

FROM ubuntu:22.04 as patch

RUN apt-get update && \
    apt-get install git -y

COPY . /workdir
WORKDIR /workdir
ARG BASE_TAG
RUN git diff "$BASE_TAG" -- streaming ':(exclude,attr:kgtkr-meta)' > kgtkr.diff

FROM tootsuite/mastodon-streaming:$BASE_TAG

USER root

COPY --from=busybox:1.36-musl /bin/busybox .
COPY --from=patch /workdir/kgtkr.diff .

RUN if [ -s kgtkr.diff ]; then ./busybox patch -p1 < kgtkr.diff; fi
RUN rm ./kgtkr.diff ./busybox
RUN chown -R mastodon:mastodon /opt/mastodon

USER mastodon
