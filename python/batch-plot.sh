#!/bin/bash

theFile=$1

ncl ./plotting/plot-spatial.ncl 'ncfile="'$1'"'
ncl ./plotting/plot-temporal.ncl 'ncfile="'$1'"'
ncl ./plotting/plot-taylor.ncl 'ncfile="'$1'"'

