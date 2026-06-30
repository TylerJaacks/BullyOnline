FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y --no-install-recommends libc6-i386 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /server

COPY derpy_script_server ./
RUN chmod +x derpy_script_server

COPY dslconfig.ini ./
COPY eula.txt ./
COPY credits.html ./
COPY scripts/ ./scripts/

EXPOSE 17017/tcp

CMD ["./derpy_script_server"]
