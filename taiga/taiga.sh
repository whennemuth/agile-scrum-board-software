# 1) Create the directories for mounting to containers and keep them out of the git index
echo ".gitignore" > .gitignore
echo "taiga-back" >> .gitignore
if [ ! -d $(pwd)/taiga-back/pgdata ] ; then
   mkdir -p $(pwd)/taiga-back/pgdata
fi 
if [ ! -d $(pwd)/taiga-back/media ] ; then
   mkdir -p $(pwd)/taiga-back/media
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

# 3) Start the database container (NOTE: The default user is "postgres")
#    To get a connection in pgAdmin to this container, first tunnel to it:
#    ssh -i ~/.ssh/buaws-kuali-rsa -L 63333:172.17.0.3:5432 wrh@10.57.237.86
#    where...
#       63333 is a random port we will use on our side of the connection
#       172.17.0.3 is the ip that the docker0 network bridge is using to address the container locally (this value will vary - use "docker inspect [container name]" to find this ip address)
#       5432 is the port that the container is mapping to the port postgres is running on inside the container (which is also 5432)
#       wrh@10.57.237.86 is the user and ip of the EC2 instance serving as the docker host.
#    in pgAdmin, create a server and set its connection details as follows:
#       Host: localhost
#       Port: 63333
#       Maintenance database: postgres
#       User name: postgres
if [ -z "$(docker ps -a --filter name=taiga-postgres | grep taiga-postgres)" ] ; then
   docker run \
      --name taiga-postgres \
      -d \
      --restart unless-stopped \
      -p 5432:5432 \
      -e POSTGRES_PASSWORD=password \
      -e PGDATA=/var/lib/postgresql/data/pgdata \
      -v $(pwd)/taiga-back/pgdata:/var/lib/postgresql/data/pgdata \
      postgres
elif [ -z "$(docker ps --filter name=taiga-postgres | grep taiga-postgres)" ] ; then
   docker start taiga-postgres
fi

# 4) Optional: Start the events container and supporting containers.
#    NOTE: Use of taiga-events includes communication over the WebSocket protocol ("ws:// instead of http://"),
#    which it seems AWS EC2 does not support. It may be possible to get the support by fronting the EC2
#    instance with an ELB with some wrangling to configure the ELB correctly to support the ws protocol.
if ( [ -n "${TAIGA_USE_EVENTS}" ] && [ -n "$(echo ${TAIGA_USE_EVENTS} | grep -i -P '^((yes)|(true)|(on))$')" ] ); then
   USE_EVENTS="true"
fi
if [ -n "${USE_EVENTS}" ] ; then
   if [ -z "$(docker ps -a --filter name=taiga-redis | grep taiga-redis)" ] ; then
      docker run --name taiga-redis -d redis:3
   elif [ -z "$(docker ps --filter name=taiga-redis | grep taiga-redis)" ] ; then
      docker start taiga-redis
   fi
   
   if [ -z "$(docker ps -a --filter name=taiga-rabbit | grep taiga-rabbit)" ] ; then
      docker run --name taiga-rabbit -d --hostname taiga rabbitmq:3
   elif [ -z "$(docker ps --filter name=taiga-rabbit | grep taiga-rabbit)" ] ; then
      docker start taiga-rabbit
   fi
   
   if [ -z "$(docker ps -a --filter name=taiga-celery | grep taiga-celery)" ] ; then
      docker run --name taiga-celery -d --link taiga-rabbit:rabbit celery
   elif [ -z "$(docker ps --filter name=taiga-celery | grep taiga-celery)" ] ; then
      docker start taiga-celery
   fi
   
   if [ -z "$(docker ps -a --filter name=taiga-events | grep taiga-events)" ] ; then
      docker run --name taiga-events -d --link taiga-rabbit:rabbit benhutchins/taiga-events
   elif [ -z "$(docker ps --filter name=taiga-events | grep taiga-events)" ] ; then
      docker start taiga-events
   fi
fi

if [ -z "$(docker ps -a | grep -P 'taiga\s+.*?docker-entrypoint')" ] ; then
   if [ -n "${USE_EVENTS}" ] ; then
      docker run -d \
        --name taiga \
        --link taiga-postgres:postgres \
        --link taiga-redis:redis \
        --link taiga-rabbit:rabbit \
        --link taiga-events:events \
        --restart unless-stopped \
        -p 8282:80 \
        -e TAIGA_HOSTNAME=${HOST_IP}:8282 \
        -v $(pwd)/taiga-back/media:/usr/src/taiga-back/media \
        benhutchins/taiga
   else
      docker run -d \
        --name taiga \
        --link taiga-postgres:postgres \
        --restart unless-stopped \
        -p 8282:80 \
        -e TAIGA_HOSTNAME=${HOST_IP}:8282 \
        -v $(pwd)/taiga-back/media:/usr/src/taiga-back/media \
        benhutchins/taiga
   fi
elif [ -z "$(docker ps | grep -P 'taiga\s+.*?docker-entrypoint')" ] ; then
   docker start taiga
fi
