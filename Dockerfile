# Based on manual compile instructions at http://wiki.nginx.org/HttpLuaModule#Installation
FROM ubuntu:16.04

ENV VER_NGINX_DEVEL_KIT=0.3.0 \
    VER_LUA_NGINX_MODULE=0.10.13 \
    VER_NGINX=1.15.0 \
    VER_LUAJIT=2.0.5 \
    NGINX_DEVEL_KIT ngx_devel_kit-${VER_NGINX_DEVEL_KIT} \
    LUA_NGINX_MODULE lua-nginx-module-${VER_LUA_NGINX_MODULE} \
    NGINX_ROOT=/nginx \
    WEB_DIR ${NGINX_ROOT}/html \
    LUAJIT_LIB /usr/local/lib \
    LUAJIT_INC /usr/local/include/luajit-2.0

# ***** ALL DEPENDENCIES *****
# Common dependencies (Nginx and LUAJit)
# Nginx dependencies
# LUAJit dependencies
# Update all packages
RUN apt-get -qq update
RUN apt-get -qq -y install libpcre3 libpcre3-dev zlib1g-dev libssl-dev gcc make wget

# ***** DOWNLOAD AND UNTAR *****

# Download
RUN wget http://nginx.org/download/nginx-${VER_NGINX}.tar.gz http://luajit.org/download/LuaJIT-${VER_LUAJIT}.tar.gz
RUN wget https://github.com/simpl/ngx_devel_kit/archive/v${VER_NGINX_DEVEL_KIT}.tar.gz -O ${NGINX_DEVEL_KIT}.tar.gz
RUN wget https://github.com/openresty/lua-nginx-module/archive/v${VER_LUA_NGINX_MODULE}.tar.gz -O ${LUA_NGINX_MODULE}.tar.gz
# Untar
RUN tar -xzvf nginx-${VER_NGINX}.tar.gz && rm nginx-${VER_NGINX}.tar.gz && \
    tar -xzvf LuaJIT-${VER_LUAJIT}.tar.gz && rm LuaJIT-${VER_LUAJIT}.tar.gz && \
    tar -xzvf ${NGINX_DEVEL_KIT}.tar.gz && rm ${NGINX_DEVEL_KIT}.tar.gz && \
    tar -xzvf ${LUA_NGINX_MODULE}.tar.gz && rm ${LUA_NGINX_MODULE}.tar.gz

# ***** BUILD FROM SOURCE *****

# LuaJIT
WORKDIR /LuaJIT-${VER_LUAJIT}
RUN make && make install
# Nginx with LuaJIT
WORKDIR /nginx-${VER_NGINX}
RUN ./configure --prefix=${NGINX_ROOT} --with-ld-opt="-Wl,-rpath,${LUAJIT_LIB}" --add-module=/${NGINX_DEVEL_KIT} --add-module=/${LUA_NGINX_MODULE}
RUN make -j2 && make install
RUN ln -s ${NGINX_ROOT}/sbin/nginx /usr/local/sbin/nginx

# ***** MISC *****
WORKDIR ${WEB_DIR}
EXPOSE 80
EXPOSE 443

# ***** CLEANUP *****
RUN rm -rf /nginx-${VER_NGINX}
RUN rm -rf /LuaJIT-${VER_LUAJIT}
RUN rm -rf /${NGINX_DEVEL_KIT}
RUN rm -rf /${LUA_NGINX_MODULE}

# This is the default CMD used by nginx:1.9.2 image
CMD ["nginx", "-g", "daemon off;"]
