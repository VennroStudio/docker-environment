FROM python:3.12-slim

LABEL maintainer="VennroStudio"

RUN apt-get update && apt-get install -y \
    openssh-client \
    git \
    sshpass \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    ansible==10.7.0 \
    ansible-lint

RUN ansible-galaxy collection install community.docker

WORKDIR /ansible

ENTRYPOINT ["ansible-playbook"]
