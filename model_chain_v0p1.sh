#!/bin/bash

# Vars
yEnd_edk=2018
mEnd_edk=11
dEnd_edk=02
yStart_mhm=2012
mStart_mhm=01
dStart_mhm=01
yEnd_mhm=2012
mEnd_mhm=12
yEnd_mhm=31


# Directories
edk_dir="~/sawam/apps/edk_nc/post_proc/"
mhm_dir="~/sawam/apps/mhm/setup"
smi_dir="~/sawam/apps/smi/"



# 1 EDK
# Step 1.1:     Update metereologicla input file

# Step 1.2:     Update processing period and get pre.nc
cd $edk_dir

cd ./pre/
sed -i -e  "'/yEnd/c yEnd=${yEnd_edk}'" edk.nml
sed -i -e  '/mEnd/c mEnd=${mEnd_edk}' edk.nml
sed -i -e  '/dEnd/c dEnd=${dEnd_edk}' edk.nml
./edk
cdo -f nc4c -z zip_4 copy pre.nc pre_small.nc

# Step 1.3:     Update processing period and get tmin.nc
cd  ../tmin
sed -i -e  "'/yEnd/c yEnd=${yEnd}'" edk.nml
sed -i -e  "'/mEnd/c mEnd=${mEnd}'" edk.nml
sed -i -e  "'/dEnd/c dEnd=${dEnd}'" edk.nml
./edk
cdo -f nc4c -z zip_4 copy tmin.nc tmin_small.nc


# Step 1.4:     Update processing period and get tmax.nc
cd  ../tmax/
sed -i -e  "'/yEnd/c yEnd=${yEnd}'" edk.nml
sed -i -e  "'/mEnd/c mEnd=${mEnd}'" edk.nml
sed -i -e  "'/dEnd/c dEnd=${dEnd}'" edk.nml
./edk
cdo -f ncd4c -z zip_4 copy tmax.nc tmax_small.nc

# Step 1.5:     Update processing period and get pre.nc
cd  cd ../tavg/
sed -i -e  "'/yEnd/c yEnd=${yEnd}'" edk.nml
sed -i -e  "'/mEnd/c mEnd=${mEnd}'" edk.nml
sed -i -e  "'/dEnd/c dEnd=${dEnd}'" edk.nml
./edk
cdo -f ncd4c -z zip_4 copy tavg.nc tavg_small.nc



# 2 MHM
cd  $mhm_dir

# Step 2.1:     Update restart
# + Step 2.1.1: Link files nc metereological
cd $mhm_dir/02_input/meteo

ln -s $edk_dir/pre/pre_small.nc pre.nc
ln -s $edk_dir/tmin/tmin_small.nc tmin.nc
ln -s $edk_dir/tmax/tmax_small.nc tmax.nc
ln -s $edk_dir/tavg/tavg_small.nc tavg.nc


# + Step 2.1.2: Backup  content t1 in t0
cp $mhm_dir/03_output/restart/t1/* $mhm_dir/03_output/restart/t0/

# + Step 2.1.3: Copy content restart t2 to t1
cp $mhm_dir/03_output/restart/t2/* $mhm_dir/03_output/restart/t1/

# + Step 2.2:   Update eval_Per in mhm.nml 
cd $mhm_dir/01_control/
sed -i -e  "'/yStart/c eval_Per(1)%yStart=${yStart_mhm}'" mhm.nml
sed -i -e  "'/mStart/c eval_Per(1)%mStart=${mStart_mhm}'" mhm.nml
sed -i -e  "'/dStart/c eval_Per(1)%dStart=${dStart_mhm}'" mhm.nml
sed -i -e  "'/yEnd/c eval_Per(1)%yEnd=${yEnd_mhm}'" mhm.nml
sed -i -e  "'/mEnd/c eval_Per(1)%mEnd=${mEnd_mhm}'" mhm.nml
sed -i -e  "'/dEnd/c eval_Per(1)%dEnd=${dEnd_mhm}'" mhm.nml

# + Step 2.2:   Run MHM
./mhm


# 3 SMI
# Step 3.1: Run SMI
cd $smi_dir
./smi