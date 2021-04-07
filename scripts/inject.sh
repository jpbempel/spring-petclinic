#!/bin/bash
URL=localhost:8080/vets.html
if [ "$1" == "" ];
then
  echo "Missing result filename"
  exit 1
fi
RESULTS=$1
echo "store results in $RESULTS"
echo "starttransfer,total" > ${RESULTS}
echo "Measure..."
date +%H:%M:%S
for i in {1..500}
do
    curl -w "%{time_starttransfer},%{time_total}\n" -s -o /dev/null $URL >> ${RESULTS}
done
date +%H:%M:%S
