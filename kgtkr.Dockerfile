ARG BASE_TAG

FROM ubuntu:22.04 as patch

RUN apt-get update && \
    apt-get install git -y

COPY . /workdir
WORKDIR /workdir
ARG BASE_TAG
RUN git diff "$BASE_TAG" -- ':!kgtkr.Dockerfile' > kgtkr.diff

FROM tootsuite/mastodon:$BASE_TAG

USER root

COPY --from=busybox:1.36-musl /bin/busybox .
COPY --from=patch /workdir/kgtkr.diff .

RUN ./busybox patch -p1 < kgtkr.diff
RUN rm ./kgtkr.diff ./busybox
RUN chown -R mastodon:mastodon /opt/mastodon

USER mastodon
