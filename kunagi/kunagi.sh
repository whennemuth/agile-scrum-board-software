# Default user = 'admin', password = 'geheim'

if [ -z "$(docker ps -a --filter name=kunagi | grep kunagi)" ] ; then
   docker run \
      -d \
      --privileged \
      -p 8484:8080 \
      --name kunagi \
      -v /tmp/kunagi-data:/usr/local/tomcat/webapps/kunagi-data \
      speedlog/kunagi-docker

elif [ -z "$(docker ps --filter name=kunagi | grep kunagi)" ] ; then
   docker start kunagi
fi
