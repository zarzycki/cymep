#!/bin/bash

mkdir -p GLOB/

for f in trajectories.txt.TC-NH_* ; do
  NH=$f
  SH=${NH/NH/SH}
  GLOB=${NH/NH/GLOB}
  cat $NH $SH > GLOB/$GLOB
done
