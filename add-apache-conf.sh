# The apache-shibboleth container does accomodate the rewriting of ports/urls.
# Specifically, there are 4 containers, all of which (except one) contain websites that expect incoming traffic over port 80.
# These containers cannot all listen on port 80, so therefore each has to have their internal 80 ports mapped to external
# ports that are unique to the container. This is where the rewriting comes in. It looks like this:
#
#    web browser:80 --> apache rewrite:[xxxx, ie 8080] --> container:[xxxx maps back to 80]
#
# It is premature to implement these rewrite rules as are other apache configurations through the apache pre-startup script.
# Therefore it suffices to add to apache rewrite rules directly on the running container.
# To do this, shell into the running container with:
#
#    docker exec -ti apache-shibboleth bash
#
# Then run the following command (follow up by restarting apache: sudo service httpd restart)

printf "\
<Location /taiga>
   Satisfy Any
   Allow from all
</Location>

<Location /agilefant>
   Satisfy Any
   Allow from all
</Location>

<Location /icescrum>
   Satisfy Any
   Allow from all
</Location>

<Location /kunagi>
   Satisfy Any
   Allow from all
</Location>

<IfModule mod_rewrite.c>
    RewriteEngine on
    RewriteRule ^/+(icescrum.*)$     http://172.17.0.1:8080/$1 [P]
    RewriteRule ^/+(agilefant.*)$    http://172.17.0.1:8181/$1 [P]
    RewriteRule ^/+(taiga.*)$        http://172.17.0.1:8282/$1 [P]
    RewriteRule ^/+(kunagi.*)$       http://172.17.0.1:8383/$1 [P]

    ProxyRequests Off

    ProxyPass /icescrum http://172.17.0.1:8080/icescrum
    ProxyPassReverse /icescrum http://172.17.0.1:8080/icescrum

    ProxyPass /agilefant http://172.17.0.1:8181/agilefant
    ProxyPassReverse /agilefant http://172.17.0.1:8181/agilefant

    ProxyPass /taiga http://172.17.0.1:8282/taiga
    ProxyPassReverse /taiga http://172.17.0.1:8282/taiga

    ProxyPass /kunagi http://172.17.0.1:8383/kunagi
    ProxyPassReverse /kunagi http://172.17.0.1:8383/kunagi

    Options None

</IfModule>
" > /etc/httpd/conf.d/scrum.conf