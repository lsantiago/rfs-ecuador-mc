
#Script to convert lat lon coordinates and add extra "northing" and "easting" variables to the EOBS netcdf files
# Author - Akash Koppa 
# Date - 2/10/2020
# Modify - Santiago Quiñones
#     - Use de script with external parameter
# Date - 16/11/2020

# rext external args
args = commandArgs (trailingOnly = TRUE)
# Use: Rscript --vanilla latlon2northeast.R working_directory input.nc name_netcdf_file
# Example: Rscript --vanilla latlon2northeast.R ./ ./pre.nc pre

# set working directory
setwd(args[1])

# load required libraries
library(ncdf4)
library(raster)
library(rgdal)

# source epsg
epsg_source = "+init=epsg:4326" # WGS 84
epsg_target = "+init=epsg:32717" # WGS 84/ UTM 17 S

# read in the lat and lon coordinates         # pre.nc # dem_0p1.nc # dem0p01.nc
id = nc_open(args[2]) # netcdf file
data = ncvar_get(id, varid = args[3]) # name inside the netcd file
northing = ncvar_get(id, varid = "lat") # name of latitude
easting  = ncvar_get(id, varid = "lon") # name of longitude 
nc_close(id)

# create a two dimensional matrix of latitudes and longitudes
north2d = NULL
for(i in 1:length(easting)){
  north2d = rbind(north2d, northing)
}

east2d = NULL
for (i in 1:length(northing)){
  east2d = cbind(east2d, easting)
}

# convert latitude and longitude  into northing and easting 
coord_latlon = data.frame(Longitude = c(east2d),
                          Latitude  = c(north2d))
coord_latlon = coordinates(coord_latlon)
# input EPSG here
coord_latlon = SpatialPoints(coord_latlon, CRS(epsg_source))
coord_edkready = spTransform(coord_latlon, CRS(epsg_target))
coord_reqd = coordinates(coord_edkready)
north2d_reqd = matrix(data = coord_reqd[,2],nrow=nrow(data))
east2d_reqd  = matrix(data = coord_reqd[,1],nrow=nrow(data))

# write these variables into the netcdf files
id = nc_open(args[2],write=TRUE)
xdim = id$dim[['lon']] # name of longitude
ydim = id$dim[['lat']] # name of latitude

var_north2d = ncvar_def(name = "northing",units = "meter",dim = list(xdim, ydim), missval = -9999,longname = "Northing in EPSG:32717")
var_east2d = ncvar_def(name = "easting",units = "meter",dim = list(xdim, ydim), missval = -9999,longname = "Easting in EPSG:32717")

# put variables
id = ncvar_add(id, var_north2d)
id = ncvar_add(id, var_east2d)
ncvar_put(id, var_north2d, north2d_reqd)
ncvar_put(id, var_east2d, east2d_reqd)
nc_close(id)
