#! /bin/bash
# Purpose: 		Code to download meteo forcings from SaWaM THREDDS server
# Date: 		February 2020
# Developer: 	PK Shrestha
# Project:		Radar based Forecasting System for Ecuador - Model Chain (RFS-Ecuador-MC)
#
# Modifications:	1) xx xxxxx, DD month YYYY
# #########################################################

set -e

# # Load OpenDAP compatible version of CDO
# ml cdo/1.6.7-1

#ml foss/2018b CDO

#============ THREDDS path ==================================

# Samples:
# 		Baseline
#		https://thredds.imk-ifu.kit.edu:9670/thredds/fileServer/SF_Basin/daily/ERA5_Land/ERA5_Land_daily_tp_2019_SF_Basin.nc

# 		Hindcast/ Forecast
# 		https://thredds.imk-ifu.kit.edu:9670/thredds/fileServer/SF_Basin/daily/SEAS5_BCSD/v2.1/SEAS5_BCSD_v2.1_daily_201612_0.1_SF_Basin.nc



#============ CONSTRUCT PATH: THREDDS ==================================

# Load data user to conection (usr, psd)
projpath="/home/utpl/rfs-ecuador-mc"
source $projpath/scripts/rfs-ecuador-mc/private_vars_download.sh


products=("ERA5_Land" "SEAS5_BCSD")

# Common
cPart1="thredds.imk-ifu.kit.edu:9670/thredds/fileServer/"
cPart2=".nc"

# Baseline
bPart1="/daily/"
bPart2="_daily_"

# Hindcast/ Forecast
fPart1=$bPart1
fPart2=$bPart2
fPart3="/v2.1/"
fPart4="_v2.1_daily_"
fPart5="_0.1_"

# Variable vectors
# TODO Don't work "Chira"
country_server=( "SF_Basin" ) # "Khuzestan" "TABN" "Chira" "SF_Basin")
var=( "tp" "t2m" "t2max" "t2min" "dwpnt" "sfcWind" )


##========= CONSTRUCT PATH: EVE ================


main_folder="download_meteo"


# Variable vectors
country=( "ecuador" ) #"iran" "sudan" "ecuador" )
domain=( "chiracatamayo" ) #  "chiracatamayo"  ) #"saofrancisco") #  "karun" "iran" "atbara" "bluenile" "sudan")
domainparent=( 0 ) # 1 ) # 2 2 3 3 3 ) # connects domains to the country index; starting from 0
forecast_phases=("baseline" "forecast")
products_ufz=("ERA5_Land" "SEAS5_BCSD_v2p1")


##========= DATE control ================

# # Get issue year and month from system clock
# issueyear=$(date +'%Y')
# issuemonth=$(date +'%m')
# issueday=$(date +'%m')

# TODO delete, only test
issueyear=2010
issuemonth=01
issueday=01


# Generate baseline year and month
if [[ $issuemonth == 01 ]]; then
	baselinemonth=12
	baselineyear=$(($issueyear-1))
else
	baselinemonth=$(printf "%02d" $((10#$issuemonth - 1)) ) # To control octal error.
	baselineyear=$issueyear
fi

		
# --- domain loop	
for idomain in "${!domain[@]}" ; do

	# --- forecast phase loop
	for iforecastphase in "${!forecast_phases[@]}" ; do

		# set year-month
		if [[ $iforecastphase == 0 ]]; then 
			year=$baselineyear
			month=$baselinemonth
		else 
			year=$issueyear
			month=$issuemonth
		fi

		echo ${forecast_phases[iforecastphase]} $year $month 

		# Set output path
		#opath=$projpath"/"$main_folder"/"${country[${domainparent[idomain]}]}"/"${forecast_phases[iforecastphase]}"/"
		opath=$projpath"/"$main_folder"/catamayo_chira/"$issueyear"-"$issuemonth"-"$issueday"/era5sd/"${forecast_phases[iforecastphase]}"/"
		# E.g.
		# /data/sawam/data/raw/sawamsfs/download_meteo/brazil/baseline/


		# Create directory to opath
		if [ ! -d ${opath} ]; then
			mkdir -p $opath
		fi


		# Output file name and location
		ofile=$opath${products_ufz[iforecastphase]}"_"${country[${domainparent[idomain]}]}"_"$year"_"$month$cPart2
		# E.g.
		# ../ERA5_Land_brazil_1981_01.nc
		# ../SEAS5_BCSD_v2p1_brazil_1981_02.nc

		# Download data
		if [[ $iforecastphase == 0 ]]; then 

			#=== Baseline

			if [[ $year < 1981 ]]; then
				:
			else
				for ivar in "${!var[@]}"; do
					# Generate OpenDAP query
					ODAP_query="https://"$usr":"$psd"@"$cPart1${country_server[idomain]}$bPart1${products[iforecastphase]}"/"\
${products[iforecastphase]}$bPart2${var[ivar]}"_"$year"_"${country_server[idomain]}$cPart2
					# Download
					wget -O $opath$year$month${var[ivar]}_temp1.nc $ODAP_query
					cdo -O -f nc4c -k grid -z zip_4 selmon,$month $opath$year$month${var[ivar]}_temp1.nc $opath$year$month${var[ivar]}_temp2.nc
				done
				# Merge individual variables to one file
				cdo -O -f nc4c -k grid -z zip_4 merge $opath$year$month*_temp2.nc $ofile
				# Remove temporary files
				rm $opath$year$month*_temp*.nc
			fi

		else

			#=== Hindcast/ Forecast

			# Generate OpenDAP query
			ODAP_query="https://"$usr":"$psd"@"$cPart1${country_server[idomain]}$bPart1${products[iforecastphase]}$fPart3\
${products[iforecastphase]}$fPart4$year$month$fPart5${country_server[idomain]}$cPart2
			# Download
			wget -O $ofile $ODAP_query

		fi

		echo $ofile " - done" 

	done # forecast phase loop

done # country loop




