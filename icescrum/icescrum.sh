if [ -z "$(docker ps -a --filter name=icescrum-db | grep icescrum-db)" ] ; then
   if [ ! -d $(pwd)/mysqldata ] ; then
      mkdir -p $(pwd)/mysqldata
   fi
   docker run \
      -d \
      -p 3306:3306 \ 
      --name icescrum-db \
      -e MYSQL_ROOT_PASSWORD=root-secret \
      -v $(pwd)/mysqldata:/var/lib/mysql \
      icescrum/mysql
elif [ -z "$(docker ps --filter name=icescrum-db | grep icescrum-db)" ] ; then
   docker start icescrum-db
fi

if [ -z "$(docker ps -a --filter name=icescrum-app | grep icescrum-app)" ] ; then
   docker run \
      --name icescrum-app \
      --link icescrum-db \
      -p 8080:8080 \
      icescrum/icescrum
elif [ -z "$(docker ps --filter name=icescrum-app | grep icescrum-app)" ] ; then
   docker start icescrum-app
fi
