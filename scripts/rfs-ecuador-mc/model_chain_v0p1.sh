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
#						University Tecnica Particular de Loja
#						Water Resources Section
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
# Santiago Quiñones		23 Sep 2020 - register changes to configuration to run EDK
# Santiago Quiñones		24 Sep 2020 - register changes to integration EDK and MHM
# Santiago Quiñones		25 Sep 2020 - add configuration to run SMI
# Santiago Quiñones		08 Oct 2020 - add download ERA5 data 
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

# TODO: Delete, this is a example
#issueyear=2011         # 4 digit year                                      │
#issuemonth=01        # 2 digit month                                     │
#issueday=02          # 2 digit day

issueyear=2019         # 4 digit year                                      │
issuemonth=01        # 2 digit month                                     │
issueday=01          # 2 digit day


# Yesteday date
#yester_year=$(date --date="-1 day" +'%Y')
#yester_month=$(date --date="-1 day" +'%m')
#yester_day=$(date --date="-1 day" +'%d')

# TODO: Delete, this is a example
yester_year=2011
yester_month=01
yester_day=01



#---------------
# Initialize
#---------------

# Directories
projpath="/home/utpl/rfs-ecuador-mc"
edkexefile=$projpath"/templates/catamayo_chira/executables/edk/edk"
namelist_dir=$projpath"/templates/catamayo_chira/namelists"

mhmexefile=$projpath"/templates/catamayo_chira/executables/mhm/mhm"
smiexefile=$projpath"/templates/catamayo_chira/executables/smi/smi"



#=======================================================================
# 1 EDK
#=======================================================================

# Step 1.1:     Update metereological input file

# +------------------+                 +----------------------------------+ 
# |                  |     retrieve    |                                  |
# |   CDS Server     |--<--------------|  UTPL SERVER                     |
# |   (ERA5 data)    |                 | ./download_meteo/catamayo_chira/ |
# |                  |     download    |                   year-month-day |
# |                  |------------->---|                                  |    
# |                  |                 |                                  |
# +------------------+                 +----------------------------------+


# Step 1.1.1:     Set dowload directories 
opath=$projpath"/download_meteo/catamayo_chira/"$issueyear"-"$issuemonth"-"$issueday
ofile_daily=$opath/$issueyear"-"$issuemonth"-"$issueday"_daily"
ofile_hourly=$opath/$issueyear"-"$issuemonth"-"$issueday"_hourly"

# Create directory to opath
if [ ! -d ${opath} ]; then
	mkdir -p $opath
fi


# Step 1.1.2:     Request era5 data
python3 $projpath/scripts/rfs-ecuador-mc/download_era5.py $issueyear $issuemonth $issueday $ofile_hourly".nc"



# Step 1.1.3:     Rename variables
#TODO: check variables
# UTPL ERA 5(tp=pre, t2m=tavg, mn2t=tmin, mx2t=tmax, ssr=ssrd)
# 			tp: Total precipitation
#			t2m: 2 metre temperature          
#			mn2t: Minimum temperature at 2 metres since previous post-processing
#			mx2t: Maximum temperature at 2 metres since previous post-processing
#			ssr: Surface net solar radiation

# UFZ ERA 5(tp=pre, t2m=tavg, t2min=tmin, t2max=tmax, ssrd=ssrd)

# cdo chname,PMSL,slp,U,u10,V,v10 ifile ofile
cdo chname,tp,pre,t2m,tavg,mn2t,tmin,mx2t,tmax,ssr,ssrd,longitude,lon,latitude,lat $ofile_hourly".nc" $ofile_hourly"_temp1.nc"



# Step 1.1.4:  Set a new Missing_value / Fill_value:
#TODO: Check, the UFZ ERA5 is -9999.f, not -9999.s 
cdo -setmissval,-9999.0 -setmissval,nan $ofile_hourly"_temp1.nc" $ofile_hourly"_temp2.nc"



# Step 1.1.5:     Change units of measurement
cdo zip_4 -expr,'pre=pre*1000;tavg=tavg-273.16;tmin=tmin-273.16;tmax=tmax-273.16;ssrd=ssrd' $ofile_hourly"_temp2.nc" $ofile_hourly"_temp3.nc"
# TODO: Recomiendan trabajar sin compresión
#cdo -f nc4c -z zip_4 -expr,'pre=pre*1000;tavg=tavg-273.16;tmin=tmin-273.16;tmax=tmax-273.16;ssrd=ssrd' $ofile_hourly"_temp2.nc" $ofile_hourly"_temp3.nc"
# cdo -f nc -expr,'P=1013.25*exp((-1)*(1.602769777072154)*log((exp(topo/10000.0)*213.15+75.0)/288.15));T=213.0+75.0*exp((-1)*topo/10000.0)-273.15' -setrtomiss,-100000,-0.0001 -topo out.nc
# cdo expr , ’ var1=a p rl+ap rc ; var2=t s −2 7 3. 1 5; ’ i f i l e o f i l e

# Step 1.1.6	  Fix latlon 
cdo sellonlatbox,-81.5,-79,-5.5,-3.5 $ofile_hourly"_temp3.nc" $ofile_hourly"_temp4.nc"

# Step 1.1.7:     Mean of the day era5 data
# TODO: check correct metod
# cdo daymean $ofile_hourly @ofile_daily
# cdo daysum -shifttime,-1hour $ofile_hourly $ofile_daily
cdo timmean $ofile_hourly"_temp4.nc" $ofile_daily"_temp1.nc"
cdo -setattribute,pre@units="mm/day",ssrd@units="W m-2",tmin@units="C",tmax@units="C",tavg@units="C" $ofile_daily"_temp1.nc" $ofile_daily"_temp2.nc"
#cdo -setattribute,pre@units="mm/day",ssrd@units="W m-2" $ofile_daily"_temp1.nc" $ofile_daily"_temp2.nc"
cdo -settime,00:00:00 $ofile_daily"_temp2.nc" $ofile_daily".nc"

# Clear data
rm -f ~/era5data/updatefull20x25.nc
rm -f ~/era5data/*_temp.nc
rm -f ~/era5data/pre.nc
rm -f ~/era5data/tmin.nc
rm -f ~/era5data/tavg.nc
rm -f ~/era5data/tmax.nc
rm -f ~/era5data/tavg.nc
rm -f ~/era5data/ssrd.nc



# Step 1.1.8      Merge data
#cdo mergetime $ofile_daily".nc" ~/era5data/full20x25.nc "~/era5data/update_full20x25_"$issueyear$issuemonth$issueday".nc"
cdo mergetime $ofile_daily".nc" ~/era5data/full20x25.nc ~/era5data/updatefull20x25.nc



# Step 1.1.8:     Split data 
cdo -select,name=pre	~/era5data/updatefull20x25.nc   ~/era5data/pre_temp.nc
cdo -select,name=tavg	~/era5data/updatefull20x25.nc   ~/era5data/tavg_temp.nc
cdo -select,name=tmin	~/era5data/updatefull20x25.nc   ~/era5data/tmin_temp.nc
cdo -select,name=tmax	~/era5data/updatefull20x25.nc   ~/era5data/tmax_temp.nc
cdo -select,name=ssrd	~/era5data/updatefull20x25.nc   ~/era5data/ssrd_temp.nc

# Step 1.1.8:     Add EDM, Merge data pre, tavg, tmin, tmax with dem_0p1.nc
dem_path=$projpath/templates/catamayo_chira/dem
cdo merge $dem_path"/dem_0p1.nc" ~/era5data/pre_temp.nc   ~/era5data/pre.nc
cdo merge $dem_path"/dem_0p1.nc" ~/era5data/tavg_temp.nc  ~/era5data/tavg.nc
cdo merge $dem_path"/dem_0p1.nc" ~/era5data/tmin_temp.nc  ~/era5data/tmin.nc
cdo merge $dem_path"/dem_0p1.nc" ~/era5data/tmax_temp.nc  ~/era5data/tmax.nc
cdo merge $dem_path"/dem_0p1.nc" ~/era5data/ssrd_temp.nc  ~/era5data/ssrd.nc

# Clear data
# Update data to next iteration
# TODO: ENABLE IN SECOND DAY
#cp ~/era5data/updatefull20x25.nc ~/era5data/full20x25.nc


# Step 1.2:     Update processing period and get new files pre.nc, tmin.nc, tmax.nc, tavg.nc
##========= Variable vectors ================
typemeteo=("pre" "tmin" "tmax" "tavg") 


echo "================================================"
echo "issue:   " $issueyear $issuemonth $issueday
echo "================================================"

# Step 1.3:    Run EDK
# Create dinamic folder to control edk
ctrlfolder_edk=$projpath/execute_edk/catamayo_chira/$issueyear-$issuemonth-$issueday/control/
if [ ! -d ${ctrlfolder_edk} ]; then
	mkdir -p $ctrlfolder_edk
fi
    
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

    #cdo -f nc4c -z zip_4 copy ../output/${typemeteo[itypemeteo]}.nc ../output/${typemeteo[itypemeteo]}_edk_small.nc
done



#=======================================================================
# 2 MHM
#=======================================================================

# Step 2.1:     UPDATE RESTART
edkoutdir=$projpath"/execute_edk/catamayo_chira/"$issueyear"-"$issuemonth"-"$issueday"/output"
mhminputdir=$projpath"/setup_mhm/catamayo_chira/meteo"


execute_mhm_dir=$projpath/execute_mhm/catamayo_chira/$issueyear-$issuemonth-$issueday
if [ ! -d ${execute_mhm_dir} ]; then
	mkdir -p $execute_mhm_dir"/control"
	mkdir -p $execute_mhm_dir"/output"
	mkdir -p $execute_mhm_dir"/restart/t1"
	mkdir -p $execute_mhm_dir"/restart/t2"
fi

# + Step 2.1.1: Link files nc metereological

# Delete previous files
rm $mhminputdir/*.nc 

ln -s $edkoutdir/pre_edk_small.nc $mhminputdir/pre.nc
ln -s $edkoutdir/tmin_edk_small.nc $mhminputdir/tmin.nc
ln -s $edkoutdir/tmax_edk_small.nc $mhminputdir/tmax.nc
ln -s $edkoutdir/tavg_edk_small.nc $mhminputdir/tavg.nc

# TODO: TEST Delete, output edk 1980-2018. How to optimize when you have a daily data?
#era5demo=/home/utpl/sawam/apps/mhm/setup/02_input/meteo/ERA5_SD_EDK
#ln -s $era5demo"/pre_edk_1980to2018_small.nc" $mhminputdir"/pre.nc"
#ln -s $era5demo"/tmin_edk_1980to2018_small.nc" $mhminputdir"/tmin.nc"
#ln -s $era5demo"/tmax_edk_1980to2018_small.nc" $mhminputdir"/tmax.nc"
#ln -s $era5demo"/tavg_edk_1980to2018_small.nc" $mhminputdir"/tavg.nc"


# + Step 2.1.2: Copy templates
cp $namelist_dir/m*.nml $execute_mhm_dir/control/


# + Step 2.1.3: Create symbolic link to mhm executable
if [ -f $execute_mhm_dir/control/mhm ]; then
    rm $execute_mhm_dir/control/mhm # remove any pre-exisintg links
fi
ln -s $mhmexefile $execute_mhm_dir/control

# + Step 2.1.4: Move yesterday output
mhm_out_yesterday=$projpath/execute_mhm/catamayo_chira/$yester_year-$yester_month-$yester_day
cp $mhm_out_yesterday/restart/t2/*.nc $execute_mhm_dir/restart/t1/

# + Step 2.2:   Update eval_Per in mhm.nml 
cd $execute_mhm_dir/control/
sed -i -e  "/yStart/c eval_Per(1)%yStart=$issueyear" mhm.nml
sed -i -e  "/mStart/c eval_Per(1)%mStart=$issuemonth" mhm.nml
sed -i -e  "/dStart/c eval_Per(1)%dStart=$issueday" mhm.nml
sed -i -e  "/yEnd/c eval_Per(1)%yEnd=$issueyear" mhm.nml
sed -i -e  "/mEnd/c eval_Per(1)%mEnd=$issuemonth" mhm.nml
sed -i -e  "/dEnd/c eval_Per(1)%dEnd=$issueday" mhm.nml


# + Step 2.3:   RUN MHM
./mhm

#=======================================================================
# 3 SMI
#=======================================================================

# Step 3.1: Run SMI
# + Step 3.1.1: Create directories
execute_smi_dir=$projpath/execute_smi/catamayo_chira/$issueyear-$issuemonth-$issueday
if [ ! -d ${execute_smi_dir} ]; then
	mkdir -p $execute_smi_dir"/control"
	mkdir -p $execute_smi_dir"/output"
fi

# + Step 3.1.2: Copy templates
cp $namelist_dir/main.dat $execute_smi_dir/control/
cp $projpath/templates/catamayo_chira/smi_cdf/cdf_info_1981_2010.nc $execute_smi_dir/control/cdf_info.nc

# + Step 3.1.3: Copy mHMH_fluxes output
cp $execute_mhm_dir/output/mHM_Fluxes_States.nc $execute_smi_dir/control/

# + Step 3.1.3: Create symbolic link to smi executable
if [ -f $execute_smi_dir/control/smi ]; then
    rm $execute_smi_dir/control/smi # remove any pre-exisintg links
fi
ln -s $smiexefile $execute_smi_dir/control


# + Step 3.1.4	: Run SMI
cd $execute_smi_dir/control
./smi









