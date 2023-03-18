#!/bin/bash
#Script to set the distance of slitpair SLT S2-1
#by Felix Albrecht, March 2023

set_dist () {
  #1: new Slit distance
  #2: x or y
  
  #set $now as current distance
  freadxpar "L:Slt S2-1|${2}dPosR" now
  if [ $(echo "${now} > ${1}" |bc -l) -eq 1 ]
  then
    #if current distance is greater that desired value, reduce
    fsetpar "Slt S2-1|${2}dMovC" 1
    movein=1
  elif [ $(echo "${now} < ${1}" |bc -l) -eq 1 ]
  then
    #if current distance is less that desired value, increase
    fsetpar "Slt S2-1|${2}dMovC" 3
    movein=0
  else
    break
  fi
  
  #calculate the estimated time (eta) to move the slits
  speed=0.075
  start=$(date +%s)
  eta=$(echo "($now - $1) / $speed" | bc -l)
  fin=$(echo "${eta#-} + $start" | bc -l)
  
  while [ $(echo "$now < $fin" | bc -l) -eq 1 ]
  do
    usleep 230000
    #get current distance and output it
    freadxpar "L:Slt S2-1|${2}dPosR" current
    echo $current
    if [ $(echo "$current <= $1 && $movein" |bc -l) -eq 1 ]
    then
      #break out of loop if desired distance is reached (too early)
      break
    elif [ $(echo "$current >= $1 && $movein==0" |bc -l) -eq 1 ]
    then
      #likewise, but for the other movement direction
      break
    fi
    #get current time
    now=$(date +%s)
  done
  #stop moving
  fsetpar "Slt S2-1|${2}dMovC" 0
}

#call the main function 3 times to get more accurate results
set_distance () {
  set_dist $1 $2
  sleep 2
  set_dist $1 $2
  sleep 2
  set_dist $1 $2
}

. $SCRIPTDIR/scriptheader
#actual function call
set_distance $1 $2

