# CyMeP

### Recreating "Metrics for evaluating tropical cyclones in climate data"

To recreate the figures from Zarzycki et al., (2021), the following steps are needed from the root of the CyMeP package.

```
cd jamc/
tar -C ../cymep/ -xvf jamc-paper.tar.gz 
chmod +x run-all.sh
./run-all.sh
```

This set of commands will untar the required configuration and trajectory files archived in `jamc-paper.tar.gz` and then run a set of CyMeP calls to generate relevant statistics and graphical files in `./fig/`.