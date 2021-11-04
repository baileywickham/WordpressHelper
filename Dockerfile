FROM ubuntu:20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Create user to simulate non root
RUN useradd -ms /bin/bash user
RUN mkdir /etc/sudoers.d/

RUN echo "user ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

# Install packages req
RUN apt-get update -qqq > /dev/null && apt-get install -y -qqq \
    build-essential \
    gcc \
    curl \
    git \
    sudo

#cache packages out of laziness
RUN apt-get install -y -qqq apt-utils \
        apache2 \
        ghostscript \
        libapache2-mod-php \
        mysql-server \
        php \
        php-bcmath \
        php-curl \
        php-imagick \
        php-intl \
        php-json \
        php-mbstring \
        php-mysql \
        php-xml \
        php-zip


FROM builder AS final
COPY . /home/user
WORKDIR /home/user
RUN chown -R user /home/user
RUN adduser www-data sudo
RUN adduser user sudo


RUN echo "%sudo ALL=NOPASSWD: ALL" >> /etc/sudoers

USER user


