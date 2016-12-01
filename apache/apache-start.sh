IMAGE_NAME=bu-ist/apache
CONTAINER_NAME=apache
if [ -z "$(docker images -q ${IMAGE_NAME})" ] ; then
   docker build -t $IMAGE_NAME .
fi

if [ ! -d $(pwd)/logs ] ; then
   mkdir -p $(pwd)/logs
   mkdir -p $(pwd)/www
fi

if [ ! -f $(pwd)/.gitignore ] ; then
   echo "logs" >> .gitignore
   echo "www" >> .gitignore
   echo ".gitignore" >> .gitignore
fi


if [ -z "$(docker ps -a --filter name=${CONTAINER_NAME} | grep ${CONTAINER_NAME})" ] ; then
   docker run \
      -d \
      -p 80:80 \
      -p 443:443 \
      --restart unless-stopped \
      --name ${CONTAINER_NAME} \
      -v $(pwd)/logs:/var/log/httpd \
      -v $(pwd)/www:/var/www \
      ${IMAGE_NAME}

   for file in html/*.sh;  do cp "$file" www; done
   for file in html/*.css; do cp "$file" www; done
   for file in html/*.gif; do cp "$file" www; done
   for file in html/*.jpg; do cp "$file" www; done
   for file in html/*.PNG; do cp "$file" www; done
   for file in html/*.js;  do cp "$file" www; done

elif [ -z "$(docker ps --filter name=${CONTAINER_NAME} | grep ${CONTAINER_NAME})" ] ; then
   docker start ${CONTAINER_NAME}
fi
