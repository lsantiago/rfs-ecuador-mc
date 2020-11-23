# RFS-Ecuador-MC 
### Radar based Forecasting System for Ecuador - Model Chain


 ABOUT:

 This is the model chain software to control the RFS-Ecuador.
 The model chain produces a cron job that carries out the RFS system
 at instructed time points to produce hydrological indicators. The
 model chain includes the following three steps:
 
 	1. 	Preprocess for and execute external drift krigging with elevation
		as the external drift variable to interpolate 
		meteorologic fields at required resolution from input data source 
		(e.g. radar precipitation). The software being used is the 
		external drift kriging (EDK) Fortran program developed at the 
		Dept. Computational Hydrosystems at the Helmholtz Centre for 
		Environmental Research - UFZ

		EDK in Git: https://git.ufz.de/chs/progs/edk_nc

 	2. 	Preprocess EDK prepared meteorological forcings and execute a 
		distributed precipitation-runoff model to obtain soil moisture 
		fields. The model software being used is the mesoscale Hydrological 
		Model (mHM) Fortran program developed at the Dept. Computational 
		Hydrosystems at the Helmholtz Centre for Environmental Research 
		- UFZ

		mHM in Git: https://git.ufz.de/mhm/mhm

 	3. 	Preprocess the mHM soil moisture output and calculate soil moisture 
		drought index fields from the soil moisture fields. The software 
		being used is the Soil Moisture Index (SMI) Fortran program 
		developed at the Dept. Computational Hydrosystems at the Helmholtz 
		Centre for Environmental Research - UFZ

		SMI in Git: https://git.ufz.de/chs/progs/SMI/-/tree/master


AUTHORS: 

	>> Santiago Quiñones
	>> Fernando Oñate
	Universidad Técnica Particular de Loja
	Water Resources Section
	Ecuador	
--------------------------------------------------
	>> Pallav Kumar Shrestha
	Computational Hydrosystems
	Helmholtz Centre for Environmental Research - UFZ
	Germany	
--------------------------------------------------
	>> Luis Samaniego
	Computational Hydrosystems
	Helmholtz Centre for Environmental Research - UFZ
	Germany
