import numpy as np

def getTrajectories(filename,nVars,headerDelimStr,isUnstruc):
  print("Getting trajectories from TempestExtremes file...")
  print("Running getTrajectories on '%s' with unstruc set to '%s'" % (filename, isUnstruc))
  print("nVars set to %d and headerDelimStr set to '%s'" % (nVars, headerDelimStr))

  # Using the newer with construct to close the file automatically.
  with open(filename) as f:
      data = f.readlines()

  # Find total number of trajectories and maximum length of trajectories
  numtraj=0
  numPts=[]
  for line in data:
    if headerDelimStr in line:
      # if header line, store number of points in given traj in numPts
      headArr = line.split()
      numtraj += 1
      numPts.append(int(headArr[1]))
    else:
      # if not a header line, and nVars = -1, find number of columns in data point
      if nVars < 0:
        nVars=len(line.split())
  
  maxNumPts = max(numPts) # Maximum length of ANY trajectory

  print("Found %d columns" % nVars)
  print("Found %d trajectories" % numtraj)

  # Initialize storm and line counter
  stormID=-1
  lineOfTraj=-1

  # Create array for data
  if isUnstruc:
    prodata = np.empty((nVars+1,numtraj,maxNumPts))
  else:
    prodata = np.empty((nVars,numtraj,maxNumPts))

  prodata[:] = np.NAN

  for i, line in enumerate(data):
    if headerDelimStr in line:  # check if header string is satisfied
      stormID += 1      # increment storm
      lineOfTraj = 0    # reset trajectory line to zero
    else:
      ptArr = line.split()
      for jj in range(nVars-1):
        if isUnstruc:
          prodata[jj+1,stormID,lineOfTraj]=ptArr[jj]
        else:
          prodata[jj,stormID,lineOfTraj]=ptArr[jj]
      lineOfTraj += 1   # increment line

  print("... done reading data")
  return numtraj, maxNumPts, prodata




def getNodes(filename,nVars,isUnstruc):
  print("Getting nodes from TempestExtremes file...")

  # Using the newer with construct to close the file automatically.
  with open(filename) as f:
      data = f.readlines()

  # Find total number of trajectories and maximum length of trajectories
  numnodetimes=0
  numPts=[]
  for line in data:
    if re.match(r'\w', line):
      # if header line, store number of points in given traj in numPts
      headArr = line.split()
      numnodetimes += 1
      numPts.append(int(headArr[3]))
    else:
      # if not a header line, and nVars = -1, find number of columns in data point
      if nVars < 0:
        nVars=len(line.split())
  
  maxNumPts = max(numPts) # Maximum length of ANY trajectory

  print("Found %d columns" % nVars)
  print("Found %d trajectories" % numnodetimes)
  print("Found %d maxNumPts" % maxNumPts)

  # Initialize storm and line counter
  stormID=-1
  lineOfTraj=-1

  # Create array for data
  if isUnstruc:
    prodata = np.empty((nVars+5,numnodetimes,maxNumPts))
  else:
    prodata = np.empty((nVars+4,numnodetimes,maxNumPts))

  prodata[:] = np.NAN

  nextHeadLine=0
  for i, line in enumerate(data):
    if re.match(r'\w', line):  # check if header string is satisfied
      stormID += 1      # increment storm
      lineOfTraj = 0    # reset trajectory line to zero
      headArr = line.split()
      YYYY = int(headArr[0])
      MM = int(headArr[1])
      DD = int(headArr[2])
      HH = int(headArr[4])
    else:
      ptArr = line.split()
      for jj in range(nVars-1):
        if isUnstruc:
          prodata[jj+1,stormID,lineOfTraj]=ptArr[jj]
        else:
          prodata[jj,stormID,lineOfTraj]=ptArr[jj]
      if isUnstruc:
        prodata[nVars+1,stormID,lineOfTraj]=YYYY
        prodata[nVars+2,stormID,lineOfTraj]=MM
        prodata[nVars+3,stormID,lineOfTraj]=DD
        prodata[nVars+4,stormID,lineOfTraj]=HH
      else:
        prodata[nVars  ,stormID,lineOfTraj]=YYYY
        prodata[nVars+1,stormID,lineOfTraj]=MM
        prodata[nVars+2,stormID,lineOfTraj]=DD
        prodata[nVars+3,stormID,lineOfTraj]=HH
      lineOfTraj += 1   # increment line

  print("... done reading data")
  return numnodetimes, maxNumPts, prodata