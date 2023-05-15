#!/bin/bash

# Script to run the RPM install of the TAKServer database.
# This is meant to be run as root with the RPM in the current directory.
echo "Getting the platform we are running on..."
platform=$(cat /etc/os-release | grep "^ID=" | cut -d= -f2)
# This line is filled in automatically at build time with the correct filename
db_rpm="takserver-database-4.9-RELEASE23.noarch.rpm"

# Make sure the expected RPM file is in the same directory.
if [ ! -f $db_rpm ]; then
   echo "Please run this script from the same directory as the RPM file ($db_rpm)."
   echo "Exiting..."
   exit 1
fi

if [ "$platform" = "fedora" ]; then
   echo "First setup the extra postgres yum repo for the latest postgres and postgis"
   sudo dnf install https://download.postgresql.org/pub/repos/yum/reporpms/F-36-x86_64/pgdg-fedora-repo-latest.noarch.rpm -y
   sudo dnf update -y

   echo "Second, install the takserver DB RPM"
   sudo yum install $db_rpm --setopt=clean_requirements_on_remove=false -y
else
   echo "First setup the extra postgres yum repo for the latest postgres and postgis"
   sudo yum install epel-release -y
   sudo yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm -y
   sudo yum update -y

   # Need to disable the default postgresql stream because it will eclipse the version specific postgresql stuff due to
   # "modular filtering" even with the version specific repo visible.
   echo "Disabling the postgresql stream to install the specific postgres version we depend on"
   sudo yum module disable postgresql

   if [ "$platform" = "rocky" ]; then
      echo "Rocky Linux detected.  Need to enable the 'powertools' repo for postgis dependencies."
      sudo yum config-manager --set-enabled powertools
   fi

   echo "Second, install the takserver DB RPM (and its dependencies)"
   sudo yum install $db_rpm --setopt=clean_requirements_on_remove=false -y
fi
