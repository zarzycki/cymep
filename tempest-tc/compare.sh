#!/bin/bash

clear
awk '{if ($1=="start") print $0; else printf "%s\t%s\t%.3e\t%.3e\t%.3e\t%.1e\t%.3e\t%s\t%s\t%s\t%s\t%s\n", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12}' trajectories.txt.ERA5 > tmp1
awk '{if ($1=="start") print $0; else printf "%s\t%s\t%.3e\t%.3e\t%.3e\t%.1e\t%.3e\t%s\t%s\t%s\t%s\t%s\n", $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12}' ../cymep/trajs/trajectories.txt.ERA5 > tmp2
diff tmp1 tmp2
rm -v tmp1 tmp2
