#!/bin/bash

source activate ncl_stable

#BASEDIR=/Users/cmz5202/Downloads/highresmip/
#BASEDIR=~/PSUGDrive/HighResMIP/
BASEDIR=~/Downloads/HRMIP/
ALLFILES=`find ${BASEDIR} -name "*-?H_*nc"`
echo $ALLFILES
for f in $ALLFILES; do
  echo ncl highresmip-to-tempest.ncl 'fname="'$f'"'
done
