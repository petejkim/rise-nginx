FROM ubuntu:14.04
MAINTAINER Nitrous.IO <eng@nitrous.io>

RUN apt-get update && apt-get install -y wget ca-certificates build-essential zlib1g-dev libpcre3-dev libpcre3

RUN cd tmp && \
  wget http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/libssl1.0.0_1.0.2g-1ubuntu4.1_amd64.deb && \
  wget http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/libssl-dev_1.0.2g-1ubuntu4.1_amd64.deb && \
  wget http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/openssl_1.0.2g-1ubuntu4.1_amd64.deb && \
  dpkg -i libssl1.0.0_1.0.2g-1ubuntu4.1_amd64.deb libssl-dev_1.0.2g-1ubuntu4.1_amd64.deb openssl_1.0.2g-1ubuntu4.1_amd64.deb

RUN cd /tmp && \
  wget https://openresty.org/download/openresty-1.9.15.1.tar.gz && \
  tar xvzf openresty-1.9.15.1.tar.gz && \
  cd openresty-1.9.15.1 && \
  ./configure --prefix=/opt/openresty --with-pcre-jit --with-ipv6 -j4 && \
  make -j4 && \
  sudo make install

RUN cd /tmp && \
  wget http://luarocks.org/releases/luarocks-2.3.0.tar.gz && \
  tar xvzf luarocks-2.3.0.tar.gz && \
  cd luarocks-2.3.0 && \
  ./configure --prefix=/opt/openresty/luajit --with-lua=/opt/openresty/luajit --lua-suffix=jit-2.1.0-beta2 --with-lua-include=/opt/openresty/luajit/include/luajit-2.1 && \
  make build && \
  sudo make install
