#!/bin/bash -l

##### ICDS ROAR
#PBS -l nodes=1:ppn=20
#PBS -l walltime=12:00:00
#PBS -A open
#PBS -j oe
#PBS -N hrmip-process

#module load ncl
module load parallel
NUMCORES=10

SOFTPATH=/storage/home/cmz5202/sw/cymep/convert-traj

TIMESTAMP=`date +%s%N`
COMMANDFILE=commands.${TIMESTAMP}.txt

cd ${SOFTPATH}

BASEDIR=/storage/home/cmz5202/group/highresmip
ALLFILES=`find ${BASEDIR} -name "*-?H_*nc"`
echo $ALLFILES
for f in $ALLFILES; do
  NCLCOMMAND="ncl highresmip-to-tempest.ncl
      'fname=\"'$f'\"' "
  echo ${NCLCOMMAND} >> ${COMMANDFILE}
done

parallel --jobs ${NUMCORES} --workdir $PWD < ${COMMANDFILE}

rm -v ${COMMANDFILE}
