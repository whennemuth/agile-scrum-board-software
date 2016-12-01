IMAGE_NAME=bu-ist/apache
CONTAINER_NAME=apache

if [ -n "$(docker ps -a --filter name=${CONTAINER_NAME} | grep ${CONTAINER_NAME})" ] ; then
   docker rm -f ${CONTAINER_NAME}
fi

docker build -t $IMAGE_NAME .

if [ ! -d $(pwd)/logs ] ; then
   mkdir -p $(pwd)/logs
fi

if [ ! -f $(pwd)/.gitignore ] ; then
   echo "taiga-back" >> .gitignore
   echo ".gitignore" >> .gitignore
fi

docker run \
   -d \
   -p 80:80 \
   -p 443:443 \
   --restart unless-stopped \
   --name ${CONTAINER_NAME} \
   -v $(pwd)/logs:/var/log/httpd \
   -v $(pwd)/html:/var/www/html/server \
   ${IMAGE_NAME}



