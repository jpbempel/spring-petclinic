#!/bin/bash
if [ "$1" == "" ];
then
  BASEDIR=$(cd ../..; pwd)
else
  BASEDIR=$1
fi
echo "Base directory: $BASEDIR"
if [ ! -d $BASEDIR/jdk ];
then
  echo "Downloading JDKs..."
  pushd .
  cd $BASEDIR
  mkdir jdk
  cd jdk
  curl -OL https://github.com/AdoptOpenJDK/openjdk8-binaries/releases/download/jdk8u275-b01/OpenJDK8U-jdk_x64_linux_hotspot_8u275b01.tar.gz
  tar xzvf OpenJDK8U-jdk_x64_linux_hotspot_8u275b01.tar.gz
  curl -OL https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11.0.9%2B11.1/OpenJDK11U-jdk_x64_linux_hotspot_11.0.9_11.tar.gz
  tar xzvf OpenJDK11U-jdk_x64_linux_hotspot_11.0.9_11.tar.gz
  curl -OL https://github.com/AdoptOpenJDK/openjdk15-binaries/releases/download/jdk-15.0.1%2B9/OpenJDK15U-jdk_x64_linux_hotspot_15.0.1_9.tar.gz
  tar xzvf OpenJDK15U-jdk_x64_linux_hotspot_15.0.1_9.tar.gz
  popd
fi
if [ ! -d $BASEDIR/ap ];
then
  ./fetch_ap.sh
fi
if [ ! -f $BASEDIR/dd-java-agent.jar ];
then
  ./fetch_dd.sh
fi
echo "Building spring-petclinic"
cd $BASEDIR/spring-petclinic
export JAVA_HOME=$BASEDIR/jdk/jdk8u275-b01
./mvnw spring-javaformat:apply package -DskipTests=true
