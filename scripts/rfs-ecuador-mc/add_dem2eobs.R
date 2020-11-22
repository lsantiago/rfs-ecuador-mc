# Script to add DEM data to the EOBS netcdf file
# Author - Akash Koppa
# Date - 03/04/2020
# Modify - Santiago Quiñones
#     - Use de script with external parameter
# Date - 16/11/2020

# rext external args
args = commandArgs(trailingOnly=TRUE)

# clear workspace 
#rm(list=ls())

# load required libraries
library(ncdf4)
library(raster)
library(sp)

# read in the 10km dem for Europe (E-OBS grid)
id = nc_open("/home/utpl/sawam/data/era5/add-dem/dem_0p1.nc")
dem = ncvar_get(id, varid="dem_0p1")
nc_close(id)

# write the DEM variable into the netcdf files, input file in args[1] 
id = nc_open(args[1],write=TRUE)
xdim = id$dim[['longitude']]
ydim = id$dim[['latitude']]

# create the dimension information for the netcdf files
var_dem = ncvar_def(name = "dem_0p1",units="meter",dim=list(xdim, ydim),missval=-9999,longname="Elevation")

# put variables
id = ncvar_add(id, var_dem)
ncvar_put(id, var_dem, dem)
nc_close(id)

