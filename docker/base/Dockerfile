# Set the base image to Ubuntu
FROM ubuntu:16.04

# File Author / Maintainer
MAINTAINER Alexander Goncearenco <alexander.goncearenco@gmail.com>

# Setup packages
USER root

RUN apt-get -y -m update && apt-get -y upgrade
RUN  apt-get install -y wget unzip zip libgsl-dev libgsl2 bzip2 build-essential git

RUN apt-get -y clean
RUN apt-get -y autoclean

# switch back to the ubuntu user so this tool (and the files written) are not owned by root
RUN groupadd -r -g 1000 ubuntu && useradd -r -g ubuntu -u 1000 ubuntu

USER ubuntu

git clone https://github.com/Epigenomics-Screw/Screw.git

CMD ["/bin/bash"]
