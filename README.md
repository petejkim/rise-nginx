Rise Nginx Module
=================

## Setup

```
# Install Latest OpenSSL
wget http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/libssl1.0.0_1.0.2g-1ubuntu2_amd64.deb
wget http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/libssl-dev_1.0.2g-1ubuntu2_amd64.deb
wget http://mirrors.kernel.org/ubuntu/pool/main/o/openssl/openssl_1.0.2g-1ubuntu2_amd64.deb
sudo dpkg -i libssl1.0.0_1.0.2g-1ubuntu2_amd64.deb libssl-dev_1.0.2g-1ubuntu2_amd64.deb openssl_1.0.2g-1ubuntu2_amd64.deb

# Install OpenResty
wget https://openresty.org/download/openresty-1.9.7.4.tar.gz
tar xvzf openresty-1.9.7.4.tar.gz
cd openresty-1.9.7.4
./configure --prefix=/opt/openresty  --with-pcre-jit --with-ipv6 -j4
make -j4
sudo make install
cd ..

# Install LuaRocks
wget http://luarocks.org/releases/luarocks-2.3.0.tar.gz
tar xvzf luarocks-2.3.0.tar.gz
cd luarocks-2.3.0
./configure --prefix=/opt/openresty/luajit --with-lua=/opt/openresty/luajit --lua-suffix=jit-2.1.0-beta1 --with-lua-include=/opt/openresty/luajit/include/luajit-2.1
make build
sudo make install
cd ..

# Add to PATH and create aliases
echo 'export PATH="lua_modules/bin:/opt/openresty/luajit/bin:/opt/openresty/nginx/sbin:$PATH"' >> ~/.zshrc
alias ngx="sudo /opt/openresty/nginx/sbin/nginx -p /opt/openresty -c /opt/openresty/nginx/conf/nginx.conf"

# Create a symlink to this repo
cd /opt/openresty/lualib
sudo ln -s ~/code/rise-nginx

# Add nginx config (for development only)
cd ~/code/rise-nginx
sudo cp /opt/openresty/nginx/conf/nginx{,-orig}.conf
sudo cp dev/nginx.conf /opt/openresty/nginx/conf/nginx.conf
sudo mkdir -p /opt/openresty/nginx/certs
sudo cp dev/star.risecloud.dev.* /opt/openresty/nginx/certs
sudo ln -s html /opt/openresty/nginx/custom_html
```

## Run tests

```
script/test spec
```

## Vendoring a new dependency

```
luarocks install --tree lua_modules PACKAGE_NAME
```

This will tell LuaRocks to unpack the Lua module into the `lua_modules` dir.

- - -
Copyright (c) 2016 Nitrous, Inc. All Rights Reserved.
