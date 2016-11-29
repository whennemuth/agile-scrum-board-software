if [ ! -d $(pwd)/taiga-back/pgdata ] ; then
   mkdir -p $(pwd)/taiga-back/pgdata
fi 
if [ ! -d $(pwd)/taiga-back/media ] ; then
   mkdir -p $(pwd)/taiga-back/media
fi
echo "taiga-back" >> .gitignore
echo ".gitignore" >> .gitignore

if [ -z "$(docker ps -a --filter name=taiga-postgres | grep taiga-postgres)" ] ; then
   docker run \
      --name taiga-postgres \
      -d \
      -e POSTGRES_PASSWORD=password \
      -e PGDATA=/var/lib/postgresql/data/pgdata \
      -v $(pwd)/taiga-back/pgdata:/var/lib/postgresql/data/pgdata \
      postgres
elif [ -z "$(docker ps --filter name=taiga-postgres | grep taiga-postgres)" ] ; then
   docker start taiga-postgres
fi

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

if [ -z "$(docker ps -a | grep -P 'taiga\s+.*?docker-entrypoint')" ] ; then
   docker run -d \
     --name taiga \
     --link taiga-postgres:postgres \
     --link taiga-redis:redis \
     --link taiga-rabbit:rabbit \
     --link taiga-events:events \
     -p 8282:80 \
     -e TAIGA_HOSTNAME=kuali-research-qa.bu.edu/taiga \
     -v $(pwd)/taiga-back/media:/usr/src/taiga-back/media \
     benhutchins/taiga
elif [ -z "$(docker ps | grep -P 'taiga\s+.*?docker-entrypoint')" ] ; then
   docker start taiga
fi
