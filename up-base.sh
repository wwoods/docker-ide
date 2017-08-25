docker-compose rm -f && docker-compose build ide-base && docker run -it --rm $* ide-base /bin/bash

