#!/bin/bash
# Convert SINEX files to gls and combine with local glx files with
# glred/glorg, restricting site list to a geographic region
# using the use_pos command. The final products are combined GLX and org
# files for subsequent processing.

# Usage
if [ $# -lt 2 ]; then
    echo ""
    echo "SNX2GLX.SH: Convert GAGE SINEX to gls and combine with local glx."
    echo "Work flow assumes the geographic region is restricted via the glred"
    echo "use_site list. Output includes both org and GLX files to be used in"
    echo "subsequent processing. The script assumes ../glx and ../GLX"
    echo "directories, located parallel to the directory from which the script"
    echo "was run. The script will form combinations only for those days for"
    echo "which GAGE SINEX are present in the provided location."
    echo ""
    echo "Usage: $0 <wwww> <nw> <snxdir>"
    echo ""
    echo "where:"
    echo "wwww   = first week to process"
    echo "nw     = number of weeks to process"
    echo "snxdir = directory where sinex data are stored"
    echo ""
    exit
fi

# Name the command line arguments
wwww=$1
nw=$2
snxdir=$3

# Test existence of SINEX directory
if [ -d $snxdir ]; then
    echo "SINEX directory exists"
else
    echo "SINEX directory does not exist"
    exit
fi

i=0
while [ $i -lt $nw ]; do  # Loop over weeks

    # Preprocess the sinex files
    for sinex in $snxdir\/*$wwww*.snx.gz; do
        if [ -f "$sinex" ]; then
            echo Copying $sinex to local directory
            \cp $sinex ./
        fi
    done
    for sinex in *$wwww*.snx.gz; do
        if [ -f $sinex ]; then
            echo Unziping $sinex
            gunzip -f $sinex
        fi
    done

    # Run htoglb, note may need to increase memory allocation (-m option) depending on sinex file size.
    for sinex in *$wwww*.snx; do
        if [ -f $sinex ]; then
            gcode=`echo ${sinex:9:3}${sinex:7:1}`
            echo Converting $sinex to $gcode gls
            htoglb . ephem -f=$gcode -m=1024 $sinex
        fi
    done

    # Remove local sinex files to manage disk space
    \rm *$wwww*.snx

    # Make an array of unique dates
    date_array=`ls *.gls | cut -d '_' -f 1 | sed s/h//`
    uniq_dates=($(printf "%s\n" "${date_array[@]}" | sort -u))

    for datetag in ${uniq_dates[@]}; do
	      echo Processing data for $datetag
        for glxname in $(ls ..\/glx\/????/h$datetag*glx); do
            echo Linking $glxname
            ln -s $glxname
        done
    done

    # Loop over the days of the week
    for datetag in ${uniq_dates[@]}; do

      echo Setting up glred/glorg run for $datetag

      # Make gdl for this day
      ls h$datetag*.gl? > comb.gdl
      hplus.pl comb.gdl
      echo Created comb.gdl for $datetag
      cat comb.gdl

      # Run glred to form combined GLX
      glred 6 comb.prt comb.log comb.gdl glred_comb.cmd
      echo Ran GLRED on comb.gdl

      # Organize output files
      \mv comb.org ./org_files/comb$datetag.org
      \mv H*GLX ../GLX

      # Clean up
      \rm *.status *.warning
      \rm comb.com comb.log comb.srt comb.svs_A comb.gdl

    done

    i=$(( $i + 1 ))
    wwww=$(( $wwww + 1 ))

    # Clean gls files and glx links
    \rm *.gls *.glx

done # End loop over weeks
