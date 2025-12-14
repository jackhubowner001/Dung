# Ubuntu base
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=administrator
ENV PASSWORD=changeme
ENV NGROK_AUTHTOKEN=REPLACE_WITH_YOUR_TOKEN

# Install XFCE desktop + XRDP
RUN apt-get update && \
    apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xrdp \
    firefox \
    sudo \
    wget \
    curl \
    net-tools \
    dbus-x11 \
    x11-xserver-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install ngrok
RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz && \
    tar -xzf ngrok-v3-stable-linux-amd64.tgz -C /usr/local/bin && \
    chmod +x /usr/local/bin/ngrok && \
    rm ngrok-v3-stable-linux-amd64.tgz

# Create user
RUN useradd -m -s /bin/bash $USER && \
    echo "$USER:$PASSWORD" | chpasswd && \
    usermod -aG sudo $USER

# Configure XRDP to use XFCE
RUN echo "xfce4-session" > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh && \
    echo "xfce4-session" > /etc/skel/.xsession

# Expose RDP port
EXPOSE 3389

# Startup script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Starting dbus..."\n\
service dbus start\n\
echo "Starting XRDP..."\n\
service xrdp start\n\
echo "Configuring ngrok..."\n\
/usr/local/bin/ngrok config add-authtoken $NGROK_AUTHTOKEN\n\
echo "Starting ngrok tunnel..."\n\
/usr/local/bin/ngrok tcp 3389 --log=stdout &\n\
echo "Waiting for ngrok..."\n\
sleep 10\n\
echo "==============================="\n\
echo " XFCE RDP SERVER READY "\n\
echo " XRDP Port: 3389 "\n\
echo " Check Railway logs for ngrok TCP URL "\n\
echo "==============================="\n\
tail -f /dev/null' > /start.sh && chmod +x /start.sh

CMD ["/start.sh"]
