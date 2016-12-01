# https://www.agilefant.com/support/user-guide/
# The default login is:
# User: admin
# Pwd : secret

if [ -z "$(docker ps -a --filter name=agilefant-db | grep agilefant-db)" ] ; then
   if [ ! -d $(pwd)/mysqldata ] ; then
      mkdir -p $(pwd)/mysqldata
   fi
   if [ ! -f $(pwd)/.gitignore ] ; then
      echo "mysqldata" >> .gitignore
      echo ".gitignore" >> .gitignore
   fi
   docker run \
      -d \
      --name agilefant-db \
      -e MYSQL_ROOT_PASSWORD=root-secret \
      -e MYSQL_DATABASE=agilefant \
      -e MYSQL_USER=agilefant \
      -e MYSQL_PASSWORD=my-secret \
      -v $(pwd)/mysqldata:/var/lib/mysql \
      mysql:latest
elif [ -z "$(docker ps --filter name=agilefant-db | grep agilefant-db)" ] ; then
   docker start agilefant-db
fi

if [ -z "$(docker ps -a --filter name=agilefant-app | grep agilefant-app)" ] ; then
   docker run \
      -d \
      -p 8181:8080 \
      --name agilefant-app \
      --link agilefant-db:db \
      kcyeu/agilefant
elif [ -z "$(docker ps --filter name=agilefant-app | grep agilefant-app)" ] ; then
   docker start agilefant-app
fi
