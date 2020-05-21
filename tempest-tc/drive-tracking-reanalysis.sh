#!/bin/bash -l

##SBATCH --job-name=tempest
##SBATCH --account=P05010048
##SBATCH --ntasks=4
##SBATCH --ntasks-per-node=4
##SBATCH --time=01:00:00
##SBATCH --partition=dav
##SBATCH --output=tempest.out.%j

###=======================================================================
#PBS -N tempest.par
#PBS -A UNSB0017 
#PBS -l walltime=0:59:00
#PBS -q premium
#PBS -j oe
#PBS -l select=4:ncpus=36:mpiprocs=36
###############################################################

############ USER OPTIONS #####################

## Unique string (useful for processing multiple data sets in same folder
UQSTR=MERRA2

## Path to TempestExtremes binaries on YS
TEMPESTEXTREMESDIR=/glade/work/zarzycki/tempestextremes/

## Topography filter file (needs to be on same grid as PSL, U, V, etc. data
TOPOFILE=/glade/u/home/zarzycki/work/reanalysis-detection/topo/MERRA2.topo.nc

## If using unstructured CAM-SE ne120 data
CONNECTFLAG="" 

## List of years to process
#YEARSTRARR=`seq 1980 2016`
YEARSTRARR=`seq 1980 2018`

## Path where files are
PATHTOFILES=/glade/u/home/zarzycki/scratch/h1files/MERRA2/
#PATHTOFILES=/glade/u/home/zarzycki/scratch/h1files/TC/h1files/JRA_DZ300500/
#PATHTOFILES=/glade/u/home/zarzycki/scratch/JRA-ETC/2017/

############ TRACKER MECHANICS #####################
starttime=$(date -u +"%s")

DATESTRING=`date +"%s%N"`
FILELISTNAME=filelist.txt.${DATESTRING}
TRAJFILENAME=trajectories.txt.${UQSTR}
touch $FILELISTNAME

for zz in ${YEARSTRARR}
do
  find ${PATHTOFILES} -name "*h1.${zz}????.nc" | sort -n >> $FILELISTNAME
done
# Add static file(s) to each line
sed -e 's?$?;'"${TOPOFILE}"'?' -i $FILELISTNAME

## DEFAULT
DCU_PSLFOMAG=200.0
DCU_PSLFODIST=5.5
DCU_WCFOMAG=-6.0    # Z300Z500 -6.0, T400 -0.4
DCU_WCFODIST=6.5
DCU_WCMAXOFFSET=1.0
DCU_WCVAR="_DIFF(Z300,Z500)"   #DCU_WCVAR generally _DIFF(Z300,Z500) or T400
DCU_MERGEDIST=6.0
SN_TRAJRANGE=8.0
SN_TRAJMINLENGTH=10
SN_TRAJMAXGAP=3
SN_MAXTOPO=150.0
SN_MAXLAT=50.0
SN_MINWIND=10.0
SN_MINLEN=10

## KARTHIK
# DCU_PSLFOMAG=300.0
# DCU_PSLFODIST=4.0
# DCU_WCFOMAG=-0.6    # DCU_WCFOMAG=-6.0
# DCU_WCFODIST=4.0
# DCU_WCMAXOFFSET=0.3
# DCU_WCVAR=T400   #DCU_WCVAR generally _DIFF(Z300,Z500) or T400
# DCU_MERGEDIST=6.0
# SN_TRAJRANGE=6.0
# SN_TRAJMINLENGTH=6
# SN_TRAJMAXGAP=1
# SN_MAXTOPO=999999.0
# SN_MAXLAT=40.0
# SN_MINWIND=17.5
# SN_MINLEN=6

STRDETECT="--verbosity 0 --timestride 1 ${CONNECTFLAG} --out cyclones_tempest.${DATESTRING} --closedcontourcmd PSL,${DCU_PSLFOMAG},${DCU_PSLFODIST},0;${DCU_WCVAR},${DCU_WCFOMAG},${DCU_WCFODIST},${DCU_WCMAXOFFSET} --mergedist ${DCU_MERGEDIST} --searchbymin PSL --outputcmd PSL,min,0;_VECMAG(UBOT,VBOT),max,2;PHIS,max,0"
echo $STRDETECT
touch cyclones.${DATESTRING}
#srun ${TEMPESTEXTREMESDIR}/bin/DetectNodes --in_data_list "${FILELISTNAME}" ${STRDETECT} </dev/null
mpiexec_mpt ${TEMPESTEXTREMESDIR}/bin/DetectNodes --in_data_list "${FILELISTNAME}" ${STRDETECT} </dev/null
cat cyclones_tempest.${DATESTRING}* >> cyclones.${DATESTRING}
rm cyclones_tempest.${DATESTRING}*

# Stitch candidate cyclones together
${TEMPESTEXTREMESDIR}/bin/StitchNodes --format "i,j,lon,lat,slp,wind,phis" --range ${SN_TRAJRANGE} --minlength ${SN_TRAJMINLENGTH} --maxgap ${SN_TRAJMAXGAP} --in cyclones.${DATESTRING} --out ${TRAJFILENAME} --threshold "wind,>=,${SN_MINWIND},${SN_MINLEN};lat,<=,${SN_MAXLAT},${SN_MINLEN};lat,>=,-${SN_MAXLAT},${SN_MINLEN};phis,<=,${SN_MAXTOPO},${SN_MINLEN}"

rm ${FILELISTNAME}
rm log*.txt
rm cyclones.${DATESTRING}   #Delete candidate cyclone file

endtime=$(date -u +"%s")
tottime=$(($endtime-$starttime))
printf "${tottime},${TRAJFILENAME}\n" >> timing.txt
