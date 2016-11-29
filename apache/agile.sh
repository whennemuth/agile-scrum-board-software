IMAGE_NAME=bu-ist/apache
CONTAINER_NAME=apache
if [ -z "$(docker images -q ${IMAGE_NAME})" ] ; then
   docker build -t $IMAGE_NAME .
fi

if [ ! -d $(pwd)/logs ] ; then
   echo "logs" >> .gitignore
   mkdir -p $(pwd)/logs
fi

if [ -z "$(docker ps -a --filter name=${CONTAINER_NAME} | grep ${CONTAINER_NAME})" ] ; then
   docker run \
      -d \
      -p 80:80 \
      -p 443:443 \
      --restart unless-stopped \
      --name ${CONTAINER_NAME} \
      -v $(pwd)/logs:/var/log/httpd \
      ${IMAGE_NAME}

elif [ -z "$(docker ps --filter name=${CONTAINER_NAME} | grep ${CONTAINER_NAME})" ] ; then
   docker start ${CONTAINER_NAME}
fi
