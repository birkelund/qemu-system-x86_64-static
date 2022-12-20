FROM debian:bullseye as builder

LABEL maintainer="Klaus Jensen <its@irrelevant.dk>"

ARG repo="https://gitlab.com/qemu-project/qemu.git"
ARG ref="master"
ARG configure_extra=""

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update && \
	apt-get install -y build-essential python3 git meson pkg-config \
	libglib2.0-dev libpixman-1-dev libattr1-dev libcap-ng-dev libmount-dev

RUN mkdir /src; cd /src; \
	git clone --depth 1 --branch $ref $repo

RUN cd /src/qemu; \
	./configure --static --target-list=x86_64-softmmu --enable-virtfs $configure_extra; \
	make -j$(nproc); \
	make install

FROM scratch
COPY --from=builder /usr/local/bin/qemu-system-x86_64 /usr/local/bin/
COPY --from=builder /usr/local/share/qemu/ /usr/local/share/qemu/
COPY --from=builder /lib/x86_64-linux-gnu/libnss_dns-2.31.so /lib/x86_64-linux-gnu/
COPY --from=builder /lib/x86_64-linux-gnu/libnss_dns.so.2 /lib/x86_64-linux-gnu/
COPY --from=builder /etc/nsswitch.conf /etc/

ENTRYPOINT ["/usr/local/bin/qemu-system-x86_64"]
