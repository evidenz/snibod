FROM    ubuntu:20.04
ARG DEBIAN_FRONTEND="noninteractive"
# for the VNC connection
EXPOSE 5900
# for the browser VNC client
EXPOSE 5901
# Use environment variable to allow custom VNC passwords
ENV VNC_PASSWD=123456
# Update packages
RUN apt update && \
    apt upgrade -y
# Make sure the dependencies are met
# removed module-init-tools from installation --> not available in newer Ubuntu versions
# changed python to python3 --> python2 was decommissioned
RUN apt install -y tigervnc-standalone-server fluxbox xterm git net-tools python3 python-numpy scrot wget software-properties-common vlc avahi-daemon \
	&& sed -i 's/geteuid/getppid/' /usr/bin/vlc \
	&& add-apt-repository ppa:obsproject/obs-studio \
	&& git clone --branch v1.3.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC \
	&& git clone --branch v0.10.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify \
	&& ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html \
# Because Python2 has been decommissioned and some unterlying scripts require /usr/bin/python we will link Python3 there
	&& ln -sf /usr/bin/python3 /usr/bin/python \
# Copy various files to their respective places
	&& wget -q -O /opt/container_startup.sh https://raw.githubusercontent.com/evidenz/snibod/master/container_startup.sh \
	&& wget -q -O /opt/x11vnc_entrypoint.sh https://raw.githubusercontent.com/evidenz/snibod/master/x11vnc_entrypoint.sh \
	&& mkdir -p /opt/startup_scripts \
	&& wget -q -O /opt/startup_scripts/startup.sh https://raw.githubusercontent.com/evidenz/snibod/master/startup.sh \
	&& wget -q -O /tmp/libndi4_4.5.1-1_amd64.deb https://github.com/Palakis/obs-ndi/releases/download/4.9.1/libndi4_4.5.1-1_amd64.deb \
	&& wget -q -O /tmp/obs-ndi_4.9.1-1_amd64.deb https://github.com/Palakis/obs-ndi/releases/download/4.9.1/obs-ndi_4.9.1-1_amd64.deb 
# Update apt for the new obs repository
RUN apt-get update \
	&& mkdir -p /config/obs-studio /root/.config/ \
	&& ln -s /config/obs-studio/ /root/.config/obs-studio \
	&& apt install -y obs-studio \
	&& apt clean -y \
# Download and install the plugins for NDI
	&& dpkg -i /tmp/*.deb \
	&& rm -rf /tmp/*.deb \
	&& rm -rf /var/lib/apt/lists/* \
	&& chmod +x /opt/*.sh \
	&& chmod +x /opt/startup_scripts/*.sh \
	&& apt clean -y
	 
# Add menu entries to the container
RUN echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"OBS Screencast\" command=\"obs\"" >> /usr/share/menu/custom-docker \
	&& echo "?package(bash):needs=\"X11\" section=\"DockerCustom\" title=\"Xterm\" command=\"xterm -ls -bg black -fg white\"" >> /usr/share/menu/custom-docker && update-menus
VOLUME ["/config"]
ENTRYPOINT ["/opt/container_startup.sh"]
