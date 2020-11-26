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
    OPT_TRACER="-javaagent:../../dd-java-agent-0.63.0-SNAPSHOT.jar -Ddd.trace.enabled=true"
    OPT_SYNTH="-DvetsSyntheticCpu=0 -DvetsSyntheticSleep=0  -DvetsSyntheticSpans=0 -DvetsSyntheticSpanSleep=0"
    OPT_PROFILER="-Ddd.profiling.enabled=true -Ddd.profiling.api-key-file=../../profiling-api-key"
    OPT_LOGGING="-Ddatadog.slf4j.simpleLogger.defaultLogLevel=info"
    OPTIONS="$OPT_TRACER $OPT_PROFILER $OPT_LOGGING $OPT_SYNTH"
fi
if [ "$1" == "dd-profileonly" ];
then
    OPT_TRACER="-javaagent:../../dd-java-agent-0.63.0-SNAPSHOT.jar -Ddd.trace.enabled=false"
    OPT_SYNTH="-DvetsSyntheticCpu=0 -DvetsSyntheticSleep=0  -DvetsSyntheticSpans=0 -DvetsSyntheticSpanSleep=0"
    OPT_PROFILER="-Ddd.profiling.enabled=true -Ddd.profiling.api-key-file=../../profiling-api-key"
    OPT_LOGGING="-Ddatadog.slf4j.simpleLogger.defaultLogLevel=info"
    OPTIONS="$OPT_TRACER $OPT_PROFILER $OPT_LOGGING $OPT_SYNTH"
fi
# jdk flavors
if [ "$2" == "jdk8" ];
then
    export JAVA_HOME=../../jdk/jdk8u275-b01
    GC_OPTIONS="-Xloggc:$GC_FILENAME -XX:+PrintGCDetails"
fi
if [ "$2" == "jdk11" ];
then
    export JAVA_HOME=../../jdk/jdk-11.0.9+11
    GC_OPTIONS="-Xlog:gc*:file=$GC_FILENAME"
fi
if [ "$2" == "jdk15" ];
then
    export JAVA_HOME=../../jdk/jdk-15.0.1+9
    GC_OPTIONS="-Xlog:gc*:file=$GC_FILENAME"
fi      
export PATH=$PATH:$JAVA_HOME/bin
$JAVA_HOME/bin/java ${OPTIONS} \
		    -Dcom.sun.management.jmxremote.port=18000 -Dcom.sun.management.jmxremote.rmi.port=18000 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Djava.rmi.server.hostname=127.0.0.1 \
		    -DnbThreads=200 \
		    -Ddd.service.name=PetClinic-Benchmark \
                    $GC_OPTIONS \
    -jar ../target/spring-petclinic-2.2.0.BUILD-SNAPSHOT.jar > out_petclinic.txt
