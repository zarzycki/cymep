#!/bin/bash

### NOTE: this script is meant to be used by CMZ to pull files used for JAMC
### into repo. It should *not* be run as part of the reproducibility tree by
### other users!

# Remove existing files in jamc dir and generate new empty ones
rm -rf config-lists/
rm -rf trajs/
mkdir config-lists/
mkdir trajs/

# Copy required config lists over
cp ../cymep/config-lists/hyp_configs.csv ./config-lists/
cp ../cymep/config-lists/rean_configs.csv ./config-lists/
cp ../cymep/config-lists/sens_configs.csv ./config-lists/
cp ../cymep/config-lists/strict_configs.csv ./config-lists/

# Get traj files based on config lists
cd config-lists/
ARR=`cat *csv | cut -d, -f1`
for i in $ARR
do
  echo $i
  cp -v ../../cymep/trajs/${i} ../trajs/
done
cd ..

# create tarball
rm jamc-paper.tar.gz
tar -zcvf jamc-paper.tar.gz config-lists/ trajs/ 

# cleanup
rm -rf config-lists/
rm -rf trajs/