#
# Mixcore(backend) Dockerfile
#
# https://git.purple.io/mixcore/mixcore-backend
#
# build command
# * default: docker build --force-rm=true -t mixcore/mixcore_backend .
#
# run command
# * app:  docker run -d -p 8080:80 mixcore/mixcore_backend
#

FROM subicura/ubuntu:14.04
MAINTAINER chungsub.kim@purpleworks.co.kr

RUN \
  echo 20160610 && \
  apt-get -qq update && \
  apt-get -qq -y dist-upgrade

# install essential packages
RUN \
  apt-get -qq -y install build-essential software-properties-common python-software-properties git curl wget

# install ruby2.2
RUN \
  add-apt-repository -y ppa:brightbox/ruby-ng && \
  apt-get -qq update && \
  apt-get -qq -y install ruby2.3 ruby2.3-dev && \
  gem sources -r https://rubygems.org/ && \
  gem install bundler --no-ri --no-rdoc --source http://rubygems.org

# install forego
RUN \
  curl -s -L -o /usr/local/bin/forego https://github.com/subicura/forego/releases/download/dev/forego && \
  chmod +x /usr/local/bin/forego

# nginx latest version install
RUN apt-get -qq -y install libssl-dev libpcre3-dev

RUN cd /tmp && \
    wget -q -O - http://nginx.org/download/nginx-1.9.12.tar.gz | tar xfz - && \
    cd nginx-1.9.12 && \
    ./configure --prefix=/usr/local/nginx --with-stream --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module && \
    make --silent && make install --silent

# install rails dependency packages
RUN \
  apt-get -qq -y install libsqlite3-dev libmysqlclient-dev imagemagick libmagickcore-dev libmagickwand-dev nodejs \
    autotools-dev automake

# nginx setting
RUN \
  rm /usr/local/nginx/conf/nginx.conf
ADD docker/assets/nginx.conf /usr/local/nginx/conf/nginx.conf

# cleanup
RUN apt-get -qq -y clean

# add application
WORKDIR /app


# add gem (for cache)
ADD ./docker/cache /app/cache
RUN \
  for i in $(seq 1 20); do \
    bundle install --gemfile=cache/Gemfile --without development test; \
    RET=$?; \
    if [ $RET -eq 0 ]; then exit 0; fi; \
    echo "retry - $i"; \
  done; \
  if [ $RET -ne 0 ]; then exit $RET; fi

# add gem (install change)
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN \
  for i in $(seq 1 10); do \
    bundle install --without development test; \
    RET=$?; \
    if [ $RET -eq 0 ]; then exit 0; fi; \
    echo "retry - $i"; \
  done; \
  if [ $RET -ne 0 ]; then exit $RET; fi

# add source
ADD app /app/app
ADD Rakefile /app/Rakefile
ADD bin /app/bin
ADD db/migrate /app/db/migrate
ADD config /app/config
ADD lib /app/lib
ADD public /app/public
ADD docker/assets/Procfile /app/Procfile

RUN rake assets:precompile

# mount port/volumn
EXPOSE 80
VOLUME ["/app/public/system"]

# run
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
ADD docker/assets/run.sh /app/run.sh
CMD ["/app/run.sh"]

