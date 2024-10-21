FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive
ENV APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1


####################
# Upgrade
####################
RUN apt-get update -q \
    && apt-get upgrade -y \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*
    
####################
# Install Openbox
####################
RUN apt-get update -q \
    && apt-get install -y \
        openbox tint2 \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

####################
# Install filemanager
####################
RUN apt-get update \
    && apt-get install -y pcmanfm \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*    

####################
# Add Package
####################
RUN apt-get update \
    && apt-get install -y \
        supervisor wget gosu git sudo python3-pip \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*
####################
# Install TurboVNC and Dependencies
####################
RUN apt-get update \
    && apt-get install -y \
        libxt6 \
        x11-xkb-utils \
    && wget -O turbovnc.deb https://jaist.dl.sourceforge.net/project/turbovnc/3.0/turbovnc_3.0_amd64.deb \
    && dpkg -i turbovnc.deb \
    && apt-get install -f -y \
    && rm -rf turbovnc.deb


####################
# Install Chrome
####################
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list' \
    && apt-get update -q \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

####################
# Add User
####################
ENV USER ubuntu
ENV PASSWD ubuntu
RUN useradd --home-dir /home/$USER --shell /bin/bash --create-home --user-group --groups adm,sudo $USER
RUN echo $USER:$USER | /usr/sbin/chpasswd
RUN mkdir -p /home/$USER/.vnc \
    && echo $PASSWD | /opt/TurboVNC/bin/vncpasswd -f > /home/$USER/.vnc/passwd \
    && chmod 600 /home/$USER/.vnc/passwd \
    && chown -R $USER:$USER /home/$USER

####################
# noVNC and Websockify
####################
RUN git clone https://github.com/AtsushiSaito/noVNC.git -b add_clipboard_support /usr/lib/novnc
RUN pip install git+https://github.com/novnc/websockify.git@v0.10.0
RUN sed -i "s/password = WebUtil.getConfigVar('password');/password = '$PASSWD'/" /usr/lib/novnc/app/ui.js
RUN mv /usr/lib/novnc/vnc.html /usr/lib/novnc/index.html

####################
# Disable Update and Crash Report
####################
RUN if [ -f /etc/update-manager/release-upgrades ]; then \
        sed -i 's/Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades; \
    fi

RUN if [ -f /etc/default/apport ]; then \
        sed -i 's/enabled=1/enabled=0/g' /etc/default/apport; \
    fi


####################
# Supervisor Configuration
####################
ENV CONF_PATH /etc/supervisor/conf.d/supervisord.conf
RUN echo '[supervisord]' >> $CONF_PATH \
    && echo 'nodaemon=true' >> $CONF_PATH \
    && echo 'user=root'  >> $CONF_PATH \
    && echo '[program:vnc]' >> $CONF_PATH \
    && echo 'command=gosu '$USER' /opt/TurboVNC/bin/vncserver :0 -fg -wm openbox -geometry 1366x667 -depth 24' >> $CONF_PATH \
    && echo '[program:novnc]' >> $CONF_PATH \
    && echo 'command=gosu '$USER' bash -c "websockify --web=/usr/lib/novnc 3000 localhost:5900"' >> $CONF_PATH \
    && echo '[program:chrome]' >> $CONF_PATH \
    && echo 'command=gosu '$USER' google-chrome --start-maximized' >> $CONF_PATH \
    && echo 'autostart=true' >> $CONF_PATH \
    && echo 'autorestart=true' >> $CONF_PATH \
    && echo 'stderr_logfile=/var/log/chrome.err.log' >> $CONF_PATH \
    && echo 'stdout_logfile=/var/log/chrome.out.log' >> $CONF_PATH

CMD ["bash", "-c", "supervisord -c $CONF_PATH"]
