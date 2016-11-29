#################################################################################################
#
# This dockerfile for the image for the apache server involved with the kuali-research application.
#
# NOTE: A startup script is used (start-apache.sh).
# The last command of this script starts httpd. Everything before that modifies directives and xml 
# in httpd configuration files. This is being done in start-apache.sh instead of here during image 
# creation because these configuration changes are specific to the landscape (sandbox, qa, ci, sta
# ging, etc.) and we don't want multiple images, one for each landscape. Instead, start-apache.sh
# will find the content it needs to make configuration changes in a mounted directory where landsc
# ape specific data belongs, and the changes are made when the container is started.

#################################################################################################

FROM centos:7
MAINTAINER Warren H (wrh@bu.edu)

LABEL \
    Vendor="Boston University" \
    Department=IST \
    Platform="Centos 7" \
    Apache\ Version="$APACHE_VERSION"

USER root

# Install Apache (and mod_ssl and net-tools for route command)
RUN \
    echo "Building httpd.x86_64"; \
    yum update -y && \
    yum install -y httpd.x86_64 && \
    yum install -y mod_ssl && \
    yum install -y net-tools

EXPOSE 80
EXPOSE 443

# Change the timezone from UTC to EDT
RUN mv /etc/localtime /etc/localtime.orig && \
    ln -s /usr/share/zoneinfo/America/New_York /etc/localtime

# Copy configurations for reverse proxy rewrite rules
COPY agile.conf /etc/httpd/conf.d/

# Copy the httpd startup script to the top directory
COPY start-apache.sh /start-apache.sh
RUN chmod -v +x /start-apache.sh

CMD ["/start-apache.sh"]