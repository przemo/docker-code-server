FROM lsiobase/ubuntu:bionic

# set version label
ARG BUILD_DATE
ARG VERSION
ARG CODE_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# environment settings
ENV HOME="/config"

RUN \
 echo "**** install node repo ****" && \
 apt-get update && \
 apt-get install -y \
	gnupg && \
 curl -s https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
 echo 'deb https://deb.nodesource.com/node_12.x bionic main' \
	> /etc/apt/sources.list.d/nodesource.list && \
 curl -s https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
 echo 'deb https://dl.yarnpkg.com/debian/ stable main' \
	> /etc/apt/sources.list.d/yarn.list && \
 echo "**** install build dependencies ****" && \
 apt-get update && \
 apt-get install -y \
	build-essential \
	libx11-dev \
	libxkbfile-dev \
	libsecret-1-dev \
	pkg-config && \
 echo "**** install runtime dependencies ****" && \
 apt-get install -y \
	git \
	jq \
	nano \
	net-tools \
	nodejs \
	sudo \
	yarn && \
 echo "**** install code-server ****" && \
 if [ -z ${CODE_RELEASE+x} ]; then \
	CODE_RELEASE=$(curl -sX GET "https://api.github.com/repos/cdr/code-server/releases/latest" \
	| awk '/tag_name/{print $4;exit}' FS='[""]'); \
 fi && \
 CODE_VERSION=$(echo "$CODE_RELEASE" | awk '{print substr($1,2); }') && \
 yarn --production global add code-server@"$CODE_VERSION" && \
 yarn cache clean && \
 ln -s /node_modules/.bin/code-server /usr/bin/code-server && \
 echo "**** clean up ****" && \
 apt-get purge --auto-remove -y \
	build-essential \
	libx11-dev \
	libxkbfile-dev \
	libsecret-1-dev \
	pkg-config && \
    apt-get clean && \
    rm -rf \
	/tmp/* \
	/var/lib/apt/lists/* \
	/var/tmp/*

# add local files
COPY /root /

# ports and volumes
EXPOSE 8443

## INSTALLING R BASE

LABEL org.label-schema.license="GPL-2.0" \
      org.label-schema.vcs-url="https://github.com/rocker-org/r-base" \
      org.label-schema.vendor="Rocker Project" \
      maintainer="Dirk Eddelbuettel <edd@debian.org>"

## Set a default user. Available via runtime flag `--user docker`
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory (for rstudio or linked volumes to work properly).
RUN useradd docker \
	&& mkdir /home/docker \
	&& chown docker:docker /home/docker \
	&& addgroup docker staff

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		ed \
		fonts-texgyre \
		less \
		locales \
                sudo \
		vim-tiny \
		wget \
	&& rm -rf /var/lib/apt/lists/* \
        && echo "docker ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/docker

## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

## Use Debian unstable via pinning -- new style via APT::Default-Release
## RUN echo "deb http://http.debian.net/debian sid main" > /etc/apt/sources.list.d/debian-unstable.list \        ## && echo 'APT::Default-Release "testing";' > /etc/apt/apt.conf.d/default

RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/" > /etc/apt/sources.list
ENV R_BASE_VERSION 4.0.2

## Now install R and littler, and create a link for littler in /usr/local/bin


RUN apt-get update \
        && apt-get install -y \
                gcc-9 \
                libopenblas0-pthread \
		littler \
                r-cran-littler \
		r-base=${R_BASE_VERSION}-* \
		r-base-dev=${R_BASE_VERSION}-* \
		r-recommended=${R_BASE_VERSION}-* \
	&& ln -s /usr/lib/R/site-library/littler/examples/build.r /usr/local/bin/build.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/check.r /usr/local/bin/check.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/installBioc.r /usr/local/bin/installBioc.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
	&& ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
	&& install.r docopt \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
	&& rm -rf /var/lib/apt/lists/*

	CMD ["R"]
	
## RUN r-devel

RUN apt-get update -qq \
	&& apt-get install -y --no-install-recommends \
		bash-completion \
		bison \
		debhelper \
		default-jdk \
		g++ \
		gcc \
		gdb \
		gfortran \
		groff-base \
		libblas-dev \
		libbz2-dev \
		libcairo2-dev/unstable \
		libcurl4-openssl-dev \
		libjpeg-dev \
		liblapack-dev \
		liblzma-dev \
		libncurses5-dev \
		libpango1.0-dev \
		libpcre3-dev \
		libpng-dev \
		libreadline-dev \
		libtiff5-dev \
		libx11-dev \
		libxt-dev \
		mpack \
		subversion \
		tcl8.6-dev \
		texinfo \
		texlive-base \
		texlive-extra-utils \
		texlive-fonts-extra \
		texlive-fonts-recommended \
		texlive-generic-recommended \
		texlive-latex-base \
		texlive-latex-extra \
		texlive-latex-recommended \
		tk8.6-dev \
		x11proto-core-dev \
		xauth \
		xdg-utils \
		xfonts-base \
		xvfb \
		zlib1g-dev

## Check out R-devel
RUN cd /tmp \
&& svn co https://svn.r-project.org/R/trunk R-devel

## Build and install according the standard 'recipe' I emailed/posted years ago
RUN cd /tmp/R-devel \
	&& R_PAPERSIZE=letter \
		R_BATCHSAVE="--no-save --no-restore" \
		R_BROWSER=xdg-open \
		PAGER=/usr/bin/pager \
		PERL=/usr/bin/perl \
		R_UNZIPCMD=/usr/bin/unzip \
		R_ZIPCMD=/usr/bin/zip \
		R_PRINTCMD=/usr/bin/lpr \
		LIBnn=lib \
		AWK=/usr/bin/awk \
		CFLAGS=$(R CMD config CFLAGS) \
		CXXFLAGS=$(R CMD config CXXFLAGS) \
	./configure --enable-R-shlib \
               --without-blas \
               --without-lapack \
               --with-readline \
               --without-recommended-packages \
               --program-suffix=dev \
	&& make \
	&& make install \
	&& rm -rf /tmp/R-devel

## Set Renviron to get libs from base R install
RUN echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron

## Set default CRAN repo
RUN echo 'options(repos = c(CRAN = "https://cran.rstudio.com/"), download.file.method = "libcurl")' >> /usr/local/lib/R/etc/Rprofile.site

## Copy 'checkbashisms' (as a local copy from devscripts package)
COPY checkbashisms /usr/local/bin

RUN cd /usr/local/bin \
&& mv R Rdevel \
&& mv Rscript Rscriptdevel \
&& ln -s Rdevel RD \
&& ln -s Rscriptdevel RDscript


RUN apt-get update -qq && apt-get -y --no-install-recommends install \
  libxml2-dev \
  libcairo2-dev \
  libsqlite-dev \
  libmariadbd-dev \
  libmariadbclient-dev \
  libpq-dev \
  libssh2-1-dev \
  unixodbc-dev \
  libsasl2-dev \
  curl \
  && install2.r --error \
    --deps TRUE \
    tidyverse \
    dplyr \
    devtools \
    formatR \
    remotes \
    selectr \
    BiocManager \  
    expss \
    openxlsx 
