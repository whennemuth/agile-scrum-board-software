# Environment variables:
#    ICESCRUM_HTTPS   : If set to true, the protocol will be https instead of http in the URL. Be careful: this is all that this variables does, 
#                       it does not configure the SSL connection at all.
#    ICESCRUM_HOST    : Required if you use Docker Machine, in such case set the IP of your Docker host, provided by docker-machine ip yourmachine.
#    ICESCRUM_PORT    : The iceScrum Docker image will always have iceScrum running on its internal port 8080, but nothing prevents you from 
#                       defining a different external port (e.g. by exposing a different port in docker run via the -p argument). 
#                       If you set the port 443 (if ICESCRUM_HTTPS is set) or the port 80 then the port will be omitted in the URL.
#    ICESCRUM_CONTEXT : It's the name that comes after "/" in the URL. You can either define another one or provide / to have an empty context.
#
# IMPORTANT!
# The first time navigating to icescrum will invoke the configuration workflow.
# Among the data being requested are the database connection details.
# Accept all the defaults except:
#
# 1) Change type from hsqldb to mysql
#
# 2) Replace the datasource url:
#       from: jdbc:mysql://localhost:3306/icescrum?useUnicode=true&characterEncoding=utf8
#       to: jdbc:mysql://icescrum-db:3306/icescrum?useUnicode=true&characterEncoding=utf8
#    NOTE the localhost is replace by the name of the container.
#
# 3) Change the username from "sa" to "root"
# 
# 4) Enter the value for the MYSQL_ROOT_PASSWORD environment variable as the password.
#
# The url for the app should be [ICESCRUM_HOST]:8080/icescrum



# 1) Make sure the directories to mount to are created and ignored by git
echo ".gitignore" > .gitignore
echo "mysqldata" >> .gitignore
echo "logs" >> .gitignore
echo "tomcat" >> .gitignore
if [ ! -d $(pwd)/mysqldata ] ; then
   mkdir -p $(pwd)/mysqldata
   chmod 777 mysqldata
fi
if [ ! -d $(pwd)/logs ] ; then
   mkdir -p $(pwd)/logs
   chmod 777 logs
fi
if [ ! -d $(pwd)/tomcat ] ; then
   mkdir -p $(pwd)/tomcat
fi

# 2) Start the database container
if [ -z "$(docker ps -a --filter name=icescrum-db | grep icescrum-db)" ] ; then
   #
   # Omitting the custom icescrum image: https://github.com/icescrum/iceScrum-docker/blob/master/mysql/Dockerfile
   # This image seems to mainly interested in a Workaround to mount volume on OS X 
   # (see https://github.com/docker-library/mysql/issues/99)
   # However, using mysql:latest seems to work fine and /var/lib/mysql is successfully mounted.
   #
   # docker run \
   #    -d \
   #    -p 3306:3306 \
   #    --name icescrum-db \
   #    --restart unless-stopped \
   #    -e MYSQL_ROOT_PASSWORD=root-secret \
   #    -v $(pwd)/mysqldata:/var/lib/mysql \
   #    icescrum/mysql

   docker run \
      -d \
      --name icescrum-db \
      -e MYSQL_ROOT_PASSWORD=root-secret \
      -e MYSQL_DATABASE=icescrum \
      -v $(pwd)/mysqldata:/var/lib/mysql \
      mysql:latest
elif [ -z "$(docker ps --filter name=icescrum-db | grep icescrum-db)" ] ; then
   docker start icescrum-db
fi

# 3) Figure out what the internet ip of the docker host is
if [ -n "${ICESCRUM_DOCKERHOST}" ] ; then
   HOST_IP=$ICESCRUM_DOCKERHOST
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

# 4) Start the application container
if [ -z "$(docker ps -a --filter name=icescrum-app | grep icescrum-app)" ] ; then
   docker run \
      -d \
      --name icescrum-app \
      --link icescrum-db \
      --restart unless-stopped \
      -p 8080:8080 \
      -p 465:465 \
      -p 587:587 \
      -e ICESCRUM_HOST=${HOST_IP} \
      -v $(pwd)/logs:/root/logs \
      -v $(pwd)/tomcat:/usr/local/tomcat/logs \
      icescrum/icescrum
elif [ -z "$(docker ps --filter name=icescrum-app | grep icescrum-app)" ] ; then
   docker start icescrum-app
fi
