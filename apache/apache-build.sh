IMAGE_NAME=bu-ist/apache
CONTAINER_NAME=apache

if [ -z "$(docker ps -a --filter name=${CONTAINER_NAME} | grep ${CONTAINER_NAME})" ] ; then
   docker rm -f ${CONTAINER_NAME}
fi

if [ -n "$(docker images -q ${IMAGE_NAME})" ] ; then
   docker rmi ${IMAGE_NAME}
fi

docker build -t $IMAGE_NAME .

if [ ! -d $(pwd)/logs ] ; then
   echo "logs" >> .gitignore
   echo ".gitignore" >> .gitignore
   mkdir -p $(pwd)/logs
fi

docker run \
   -d \
   -p 80:80 \
   -p 443:443 \
   --restart unless-stopped \
   --name ${CONTAINER_NAME} \
   -v $(pwd)/logs:/var/log/httpd \
   ${IMAGE_NAME}



