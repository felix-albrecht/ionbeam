#!/bin/bash
#Script to set the position of slitpair SLT S2-1
#by Felix Albrecht, March 2023

set_pos () {
  #1: new Slit position
  #2: x or y
  
  #set $now as current position
  freadxpar "L:Slt S2-1|${2}cPosR" now
  if [ $(echo "${now} > ${1}" |bc -l) -eq 1 ]
  then
    #if current position is greater that desired value, move left/down
    fsetpar "Slt S2-1|${2}cMovC" 1
    movein=1
  elif [ $(echo "${now} < ${1}" |bc -l) -eq 1 ]
  then
    #if current position is less that desired value, move right/up
    fsetpar "Slt S2-1|${2}cMovC" 3
    movein=0
  else
    break
  fi
  
  #calculate the estimated time (eta) to move the slits
  speed=0.08
  start=$(date +%s)
  eta=$(echo "($now - $1) / $speed" | bc -l)
  fin=$(echo "${eta#-} + $start" | bc -l)
  
  while [ $(echo "$now < $fin" | bc -l) -eq 1 ]
  do
    usleep 100000
    #get current position and output it
    freadxpar "L:Slt S2-1|${2}cPosR" current
    echo $current
    if [ $(echo "$current <= $1 && $movein" |bc -l) -eq 1 ]
    then
      #break out of loop if desired position is reached (too early)
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
  fsetpar "Slt S2-1|${2}cMovC" 0
}

#call the main function two times to get more accurate results
set_position () {
  set_pos $1 $2
  sleep 2
  set_pos $1 $2
}

. $SCRIPTDIR/scriptheader
#actual function call
set_position $1 $2