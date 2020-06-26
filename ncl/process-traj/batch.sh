#!/bin/bash

source activate ncl_stable

ALLFILES=`find ~/PSUGDrive/HighResMIP/*NH* -name "*nc"`
for f in $ALLFILES; do
  ncl convert-ibtracs-to-tempest.ncl 'fname="'$f'"'
done
