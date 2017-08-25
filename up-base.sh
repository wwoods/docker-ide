docker-compose rm -f && docker-compose build ide-base && docker run -it $* ide-base /bin/bash

