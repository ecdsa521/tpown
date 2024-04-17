FROM debian:latest AS build
WORKDIR /tmp

RUN apt update
RUN apt -y install gcc-arm-linux-gnueabi make wget bzip2
RUN wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2024.84.tar.bz2
RUN wget http://zlib.net/zlib-1.3.1.tar.gz
RUN tar xf dropbear-2024.84.tar.bz2
RUN tar xf zlib-1.3.1.tar.gz

ENV CC=arm-linux-gnueabi-gcc
ENV AR=arm-linux-gnueabi-ar

WORKDIR /tmp/zlib-1.3.1
RUN ./configure --prefix=/tmp/zlib
RUN make && make install

WORKDIR /tmp/dropbear-2024.84
RUN ./configure --host=arm-linux-gnueabi --prefix=/tmp/dropbear --enable-static --with-zlib=/tmp/zlib
RUN echo "#define DROPBEAR_SVR_PASSWORD_AUTH 0" | tee localoptions.h
RUN make -j8 && make install

FROM debian:latest
WORKDIR /root/

COPY --from=build /tmp/dropbear /tmp/dropbear/
CMD ["cp", "-av", "/tmp/dropbear","/out/"]
