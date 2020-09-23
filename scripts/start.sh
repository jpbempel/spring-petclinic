#!/bin/bash
OPTIONS=""
if [ "$1" == "ap" ];
then
  OPTIONS="-agentpath:../../ap/build/libasyncProfiler.so=start,event=wall,collapsed,file=petclinic_collapsed.txt"
fi
if [ "$1" == "jfr" ];
then
  OPTIONS="-XX:StartFlightRecording=filename=petclinic-benchmark-profile.jfr,dumponexit=true,settings=profile"
fi
if [ "$1" == "dd" ];
then
    # -Ddatadog.slf4j.simpleLogger.defaultLogLevel=debug
  OPTIONS="-javaagent:../../dd-java-agent-0.55.1.jar -Ddd.profiling.enabled=true -Ddd.profiling.api-key-file=../../profiling-api-key -Ddd.trace.enabled=true -Ddatadog.slf4j.simpleLogger.defaultLogLevel=info"
fi
if [ "$1" == "dd-profileonly" ];
then
    OPTIONS="-javaagent:../../dd-java-agent-0.55.1.jar -Ddd.profiling.enabled=true -Ddd.profiling.api-key-file=../../profiling-api-key -Ddd.trace.enabled=false -Ddatadog.slf4j.simpleLogger.defaultLogLevel=info"
fi
if [ "$1" == "dd-mlt-rate" ];
then
    echo "sample.rate=$3"
    OPTIONS="-javaagent:../../dd-java-agent-0.57.0-MLT-SNAPSHOT.jar -Ddd.profiling.enabled=true -Ddd.profiling.api-key-file=../../profiling-api-key -Ddd.trace.enabled=true -Ddd.method.trace.sample.rate=$3"
    # 
fi
if [ "$1" == "dd-mlt-heuristic" ];
then
    echo "heuristic mode"
    OPTIONS="-javaagent:../../dd-java-agent-0.57.0-MLT-SNAPSHOT.jar -Ddd.profiling.enabled=true -Ddd.profiling.api-key-file=../../profiling-api-key -Ddd.trace.enabled=true"
    # 
fi
# jdk flavors
if [ "$2" == "zulu8" ];
then
  export JAVA_HOME=../../jdk/zulu8.46.0.19-ca-jdk8.0.252-linux_x64
fi
if [ "$2" == "jdk8dev" ];
then
  export JAVA_HOME=../../jdk/jdk8dev
fi
if [ "$2" == "jdk15" ];
then
    export JAVA_HOME=../../jdk/jdk15dev
fi
if [ "$2" == "8nightly" ];
then
    export JAVA_HOME=../../jdk/jdk8u262-b09-nightly//
fi
if [ "$2" == "jdk11" ];
then
  export JAVA_HOME=../../jdk/jdk-11.0.7+10
fi
export PATH=$PATH:$JAVA_HOME/bin
$JAVA_HOME/bin/java ${OPTIONS} \
		    -Dcom.sun.management.jmxremote.port=18000 -Dcom.sun.management.jmxremote.rmi.port=18000 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=127.0.0.1 \
		    -DnbThreads=200 \
		    -Ddd.service.name=PetClinic-Benchmark \
		    -XX:-UseBiasedLocking \
    -jar ../target/spring-petclinic-2.2.0.BUILD-SNAPSHOT.jar > out_petclinic.txt
