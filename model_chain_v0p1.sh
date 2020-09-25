#!/bin/bash

#=======================================================================
#							 RFS-Ecuador-MC 
#
# Radar based Forecasting System for Ecuador - Model Chain
#=======================================================================
#
# ABOUT:
#
# This is the model chain software to control the RFS-Ecuador.
# The model chain produces a cron job that carries out the RFS system
# at instructed time points to produce hydrological indicators. The
# model chain includes the following three steps:
# 
# 	1. 	Preprocess for and execute external drift krigging with elevation
#		as the external drift variable to interpolate 
#		meteorologic fields at required resolution from input data source 
#		(e.g. radar precipitation). The software being used is the 
#		external drift kriging (EDK) Fortran program developed at the 
#		Dept. Computational Hydrosystems at the Helmholtz Centre for 
#		Environmental Research - UFZ
#
#		EDK in Git: https://git.ufz.de/chs/progs/edk_nc
#
# 	2. 	Preprocess EDK prepared meteorological forcings and execute a 
#		distributed precipitation-runoff model to obtain soil moisture 
#		fields. The model software being used is the mesoscale Hydrological 
#		Model (mHM) Fortran program developed at the Dept. Computational 
#		Hydrosystems at the Helmholtz Centre for Environmental Research 
#		- UFZ
#
#		mHM in Git: https://git.ufz.de/mhm/mhm
#
# 	3. 	Preprocess the mHM soil moisture output and calculate soil moisture 
#		drought index fields from the soil moisture fields. The software 
#		being used is the Soil Moisture Index (SMI) Fortran program 
#		developed at the Dept. Computational Hydrosystems at the Helmholtz 
#		Centre for Environmental Research - UFZ
#
#		SMI in Git: https://git.ufz.de/chs/progs/SMI/-/tree/master
#
# 
# 
# AUTHORS: 
#
#	Santiago Quiñones
#						University of Loja
#						Ecuador	
#
#	Pallav Kumar Shrestha
#						Computational Hydrosystems
#						Helmholtz Centre for Environmental Research - UFZ
#						Germany	
#	Luis Samaniego	
#						Computational Hydrosystems
#						Helmholtz Centre for Environmental Research - UFZ
#						Germany
#
# 
# CREATED: April 2020
# 
# VERSION: 0.1
# 
#=======================================================================
#
# Modifications:
#
# Pallav Shrestha 		24 Apr 2020 - added model chain script description
# Pallav Shrestha 		24 Apr 2020 - added rfs folder structure reference
#
#=======================================================================

#---------------
# FOLDER structure
#---------------

# rfs-ecuador-mc
	# templates
		# catamayo_chira
			# executables
				# edk
				# mhm
				# smi
			# namelists
				# edk.nml
				# mhm.nml, mhm_output.nml, mrm_output.nml, mhm_parameters.nml
				# main.dat
			# variogram_parameters
				# var_param_pre.txt
				# var_param_tavg.txt
				# var_param_tmax.txt
				# var_param_tmin.txt
			# meteo_headers
				# header.txt
			# primal_restart (e.g. end of 2010)
				# mhm_restart_001.nc
				# mrm_restart_001.nc
			# smi_cdf
				# cdf_info.nc
	# scripts
		# rfs-ecuador-mc (git synced!)
	# setup_mhm
		# catamayo_chira
			# gauge
			# lai
			# latlon
			# morph
	# download_meteo
		# catamayo_chira
			# 2011-01-01
				# radar_precipitation
				# era5sd
	# preprocess_meteo
		# catamayo_chira
			# 2011-01-01
				# meteo
	# execute_edk
		# catamayo_chira
			# 2011-01-01
				# contol
					# edk.nml (sed modified)
					# soft link to variogram parameters
					# soft link to edk executable
				# output
	# execute_mhm
		# catamayo_chira
			# 2011-01-01
				# contol
					# mhm.nml (sed modified)
					# soft link to mhm_output, mrm_output, mhm_parameters.nml
					# soft link to mhm executable
				# output
				# restart
					# t1
					# t2
	# execute_smi
		# catamayo_chira
			# 2011-01-01
				# contol
					# main.dat (sed modified)
					# soft link to cdf_info.nc
					# soft link to smi executable
				# output
	# postprocess
		# catamayo_chira
			# 2011-01-01
				# ... (for future work)




#---------------
# DATE control
#---------------

#==> Cron job commands (to do...). Cron job checks the system clock and 
#	 decides whether to run the rest of the script

# Get issue year and month from system clock
#issueyear=$(date +'%Y')		# 4 digit year
#issuemonth=$(date +'%m')	# 2 digit month
#issueday=$(date +'%d')		# 2 digit day

issueyear=2018         # 4 digit year                                      │
issuemonth=12        # 2 digit month                                     │
issueday=31          # 2 digit day

#---------------
# Initialize
#---------------

# Vars
# yEnd_edk=2018
# mEnd_edk=11
# dEnd_edk=02
# yStart_mhm=2012
# mStart_mhm=01
# dStart_mhm=01
# yEnd_mhm=2012
# mEnd_mhm=12
# yEnd_mhm=31


# Directories
edk_dir="./apps/edk/"
mhm_dir="./apps/mhm/"
smi_dir="./apps/smi/"

projpath="/home/utpl/rfs-ecuador-mc"
edkexefile=$projpath"/templates/catamayo_chira/executables/edk/edk"
namelist_dir=$projpath"/templates/catamayo_chira/namelists"

mhmexefile=$projpath"/templates/catamayo_chira/executables/mhm/mhm"



#=======================================================================
# 1 EDK
#=======================================================================

# Step 1.1:     Update metereological input file

# Step 1.2:     Update processing period and get pre.nc
##========= Variable vectors ================
typemeteo=("pre" "tmin" "tmax" "tavg")


echo "================================================"
echo "issue:   " $issueyear $issuemonth $issueday
echo "================================================"

# Step 1.2:     Update processing period and get pre.nc
# TODO: Create dinamic folder with date
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

    #cdo -f nc4c -z zip_4 copy ../output/${typemeteo[itypemeteo]}.nc ../output/${typemeteo[itypemeteo]}_small.nc
done

exit

#=======================================================================
# 2 MHM
#=======================================================================

# Step 2.1:     UPDATE RESTART
edkoutdir=$projpath/execute_edk/catamayo_chira/2011-01-01/output
mhminputdir=$projpath/setup_mhm/catamayo_chira/meteo
#ctrlfolder_mhm=$projpath/execute_mhm/catamayo_chira/2011-01-01/control
execute_mhm_dir=$projpath/execute_mhm/catamayo_chira/2011-01-01

# + Step 2.1.1: Link files nc metereological

# TODO: Chech files febore to delete
rm $mhminputdir/*.nc 

ln -s $edkoutdir/pre_small.nc $mhminputdir/pre.nc
ln -s $edkoutdir/tmin_small.nc $mhminputdir/tmin.nc
ln -s $edkoutdir/tmax_small.nc $mhminputdir/tmax.nc
ln -s $edkoutdir/tavg_small.nc $mhminputdir/tavg.nc

# + Step 2.1.2: Copy templates
cp $namelist_dir/m*.nml $execute_mhm_dir/control/


# + Step 2.1.3: Create symbolic link to mhm executable
if [ -f $execute_mhm_dir/control/mhm ]; then
    rm $execute_mhm_dir/control/mhm # remove any pre-exisintg links
fi
ln -s $mhmexefile $execute_mhm_dir/control



# + Step 2.1.2: Archive content t1 in t0
#mkdir $mhm_dir/03_output/restart/t0/$issueyear-$issuemonth-$issueday
#mv $mhm_dir/03_output/restart/t1/* $mhm_dir/03_output/restart/t0/$issueyear-$issuemonth-$issueday/

# + Step 2.1.3: Move content restart t2 to t1
#mv $mhm_dir/03_output/restart/t2/* $mhm_dir/03_output/restart/t1/

# + Step 2.2:   Update eval_Per in mhm.nml 
#cd $mhm_dir/01_control/
#sed -i -e  "'/yStart/c eval_Per(1)%yStart=${issueyear}'" mhm.nml
#sed -i -e  "'/mStart/c eval_Per(1)%mStart=${issuemonth}'" mhm.nml
#sed -i -e  "'/dStart/c eval_Per(1)%dStart=${issueday}'" mhm.nml
#sed -i -e  "'/yEnd/c eval_Per(1)%yEnd=${issueyear}'" mhm.nml
#sed -i -e  "'/mEnd/c eval_Per(1)%mEnd=${issuemonth}'" mhm.nml
#sed -i -e  "'/dEnd/c eval_Per(1)%dEnd=${issueday}'" mhm.nml

# + Step 2.2:   RUN MHM
cd $execute_mhm_dir/control/
#./mhm

exit

# Step 2.3:     RELOCATE OUTPUT
mkdir $mhm_dir/03_output/$issueyear-$issuemonth-$issueday
mv $mhm_dir/03_output/*.nc $mhm_dir/03_output/$issueyear-$issuemonth-$issueday/




#=======================================================================
# 3 SMI
#=======================================================================

# Step 3.1: Run SMI
cd $smi_dir
./smi





