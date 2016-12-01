# Default user = 'admin', password = 'geheim'

echo ".gitignore" > .gitignore
echo "kunagi-data" >> .gitignore
if [ ! -d $(pwd)/kunagi-data ] ; then
   mkdir -p $(pwd)/kunagi-data
fi

if [ -z "$(docker ps -a --filter name=kunagi | grep kunagi)" ] ; then

   docker run \
      -d \
      -p 8383:8080 \
      --name kunagi \
      --restart unless-stopped \
      -v $(pwd)/kunagi-data:/usr/local/tomcat/webapps/kunagi-data \
      speedlog/kunagi-docker
elif [ -z "$(docker ps --filter name=kunagi | grep kunagi)" ] ; then
   docker start kunagi
fi
