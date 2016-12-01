# Environment variables:
#    ICESCRUM_HTTPS   : If set to true, the protocol will be https instead of http in the URL. Be careful: this is all that this variables does, 
#                       it does not configure the SSL connection at all.
#    ICESCRUM_HOST    : Required if you use Docker Machine, in such case set the IP of your Docker host, provided by docker-machine ip yourmachine.
#    ICESCRUM_PORT    : The iceScrum Docker image will always have iceScrum running on its internal port 8080, but nothing prevents you from 
#                       defining a different external port (e.g. by exposing a different port in docker run via the -p argument). 
#                       If you set the port 443 (if ICESCRUM_HTTPS is set) or the port 80 then the port will be omitted in the URL.
#    ICESCRUM_CONTEXT : It's the name that comes after "/" in the URL. You can either define another one or provide / to have an empty context.

# 1) Start the database container
if [ -z "$(docker ps -a --filter name=icescrum-db | grep icescrum-db)" ] ; then
   if [ ! -d $(pwd)/mysqldata ] ; then
      mkdir -p $(pwd)/mysqldata
   fi
   if [ ! -f $(pwd)/.gitignore ] ; then
      echo "mysqldata" >> .gitignore
      echo ".gitignore" >> .gitignore
   fi
   docker run \
      -d \
      -p 3306:3306 \
      --name icescrum-db \
      --restart unless-stopped \
      -e MYSQL_ROOT_PASSWORD=root-secret \
      -v $(pwd)/mysqldata:/var/lib/mysql \
      icescrum/mysql
elif [ -z "$(docker ps --filter name=icescrum-db | grep icescrum-db)" ] ; then
   docker start icescrum-db
fi

# 2) Figure out what the internet ip of the docker host is
if [ -n "${TAIGA_DOCKERHOST}" ] ; then
   HOST_IP=$TAIGA_DOCKERHOST
else
   # b) On an AWS instance, this expression will get the ip of the eth0 network bridge
   HOST_IP=$(echo $(\
      ip -h -f inet -o address \
         | grep -i eth0 \
         | grep -i -P -o '([\d]+\.?){4}') \
         | grep -i -P -o '^([\d]+\.?){4}')
   if [ -z "$HOST_IP" ] ; then
      # b) This expression returns the gateway ip, but this may not be the same as the network bridge ip
      HOST_IP=$(\
         route -n \
            | grep -Po "(?<=^0\.0\.0\.0)\x20+[\d\.]+" \
            | tr -d "[:blank:]")
      if [ -z "$HOST_IP" ] ; then
         # c) Hardcoded value for the EC2 instance I am currently working with.
         HOST_IP=10.57.237.86
      fi
   fi
fi

if [ -z "$(docker ps -a --filter name=icescrum-app | grep icescrum-app)" ] ; then
   docker run \
      -d \
      --name icescrum-app \
      --link icescrum-db \
      --restart unless-stopped \
      -p 8080:8080 \
      -e ICESCRUM_HOST=${HOST_IP} \
      icescrum/icescrum
elif [ -z "$(docker ps --filter name=icescrum-app | grep icescrum-app)" ] ; then
   docker start icescrum-app
fi
