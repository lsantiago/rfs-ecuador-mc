#!/bin/bash

issueyear=1981
issuemonth=12
issueday=31


##========= Paths ================
projpath="/home/utpl/rfs-ecuador-mc"
edkexefile=$projpath"/templates/catamayo_chira/executables/edk/edk"
namelist_dir=$projpath"/templates/catamayo_chira/namelists"

##========= Variable vectors ================
typemeteo=("tavg") #("pre" "tmin" "tmax" "tavg")


echo "================================================"
echo "issue:   " $issueyear $issuemonth $issueday
echo "================================================"

##========= Run edk ================
ctrlfolder_edk=$projpath/execute_edk/catamayo_chira/2011-01-01/control/
    
# Create symbolic link to edk executable
if [ -f $ctrlfolder_edk/edk ]; then
    rm $ctrlfolder_edk/edk # remove any pre-exisintg links
fi
ln -s $edkexefile $ctrlfolder_edk

# Get output by type meteorology
for itypemeteo in "${!typemeteo[@]}" ; do
    echo "Work with.. " ${typemeteo[itypemeteo]}
    
    # Copy template edk to control folder
    cp $namelist_dir/edk_${typemeteo[itypemeteo]}.nml $ctrlfolder_edk/edk.nml
    
    # Update configuration edk nml
    cd $ctrlfolder_edk/
    sed -i -e  "/yEnd/c yEnd=$issueyear" edk.nml
    sed -i -e  "/mEnd/c mEnd=$issuemonth" edk.nml
    sed -i -e  "/dEnd/c dEnd=$issueday" edk.nml
    
    #time ./edk > ./runlog.txt
    #./edk

    cdo -f nc4c -z zip_4 copy ../output/${typemeteo[itypemeteo]}.nc ../output/${typemeteo[itypemeteo]}_small.nc
done


#read -p "Press any key"









