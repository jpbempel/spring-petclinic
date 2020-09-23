#!/bin/bash
INJECT_COUNT=3
OUTPUT_FILE=out_petclinic.txt
THREADS=1


function bench () {
  if [ "$1" == "" ];
  then
    echo "Missing tag"
    exit 1
  fi
  if [ "$2" == "" ];
  then
    echo "Missing jdk"
    exit 1
  fi
  TAG=$1
  JDK=$2
  MLT_RATE=$3
  # checking prequisites
  checks $TAG
  for I in $(seq $INJECT_COUNT);
  do
    if [ -f $OUTPUT_FILE ];
    then
      rm $OUTPUT_FILE
    fi
    echo "$(date +%H:%M:%S) Starting application ${TAG}-${JDK} run $I/$INJECT_COUNT..."
    ./start.sh $TAG $JDK $MLT_RATE &
    PID=$!
    DEAD=0
    sleep 0.2
    while [ "$(grep -o "Started PetClinicApplication" $OUTPUT_FILE)" != "Started PetClinicApplication" -a "$DEAD" != "1" ];
    do
      kill -0 $PID
      DEAD=$?
      sleep 1
    done
    if [ "$DEAD" == "1" ];
    then
      echo "Application not started correctly!"
      exit 1
    fi
    SUFFIX=${TAG}${MLT_RATE}-${JDK}-${I}
    RESULTS_FILENAME=results_${SUFFIX}
    CPU_TICKS_FILENAME=cpu_ticks_${SUFFIX}
    MEM_FILENAME=mem-${SUFFIX}
    pidstat -r -C java 1 > ${MEM_FILENAME}.txt &
    echo "$(date +%H:%M:%S) Sending requests..."
    pids=()
    for FORK in $(seq $THREADS);
    do
      ./inject.sh ${RESULTS_FILENAME}_${FORK}.csv &
      pids[$FORK]=$!
    done
    for FORK in $(seq $THREADS);
    do
      pid=${pids[$FORK]}
      wait $pid
    done
    java_pid=$(pgrep java)
    echo "java pid: $java_pid"
    cat /proc/$java_pid/stat | cut -d " " -f 14 > ${CPU_TICKS_FILENAME}.txt
    # truncate previous file because we are doing >>
    true > ${RESULTS_FILENAME}.csv
    for FORK in $(seq $THREADS);
    do
      cat ${RESULTS_FILENAME}_${FORK}.csv >> ${RESULTS_FILENAME}.csv
    done
    echo "Killing $PID"
    pkill -P $PID
    pkill pidstat
    sleep 1
  done
  SUFFIX_FINAL=${TAG}${MLT_RATE}-${JDK}
  python percentiles.py ${SUFFIX_FINAL}.csv results_${SUFFIX_FINAL}-?.csv
}

function checks () {
  TAG=$1
  if [ "$TAG" == "ap" ];
  then
    if [ ! -f ../../ap/build/libasyncProfiler.so ];
    then
      echo "Async profiler library is missing."
      exit 1
    fi
    echo 1 | sudo tee /proc/sys/kernel/perf_event_paranoid
    echo 0 | sudo tee /proc/sys/kernel/kptr_restrict
  fi
  if [ "$TAG" == "dd" ];
  then
    if [ ! -f ../../dd-java-agent.jar ];
    then
      echo "DD java agent is missing"
      exit 1
    fi
    if [ ! -f ../../profiling-api-key ];
    then
      echo "DD api-key file is missing"
      exit 1
    fi
  fi
}

#bench none jdk11
#bench ap jdk11
#bench jfr jdk11
#bench dd 8nightly
#bench dd-profileonly jdk11
bench dd-mlt-rate jdk11 0
bench dd-mlt-rate jdk11 0.01
bench dd-mlt-heuristic jdk11 

