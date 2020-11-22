import cdsapi
import sys

info = sys.argv


# Form use: python download_era5.py 2020 10 02
year_isue = info[1]
month_isue = info[2]
day_isue = info[3]

ofile_hourly = info[4] 

# TODO: Delete demo date
#year_isue = 2020
#month_isue = 10
#day_isue = 2



c = cdsapi.Client()
r = c.retrieve(
    'reanalysis-era5-single-levels', {
            'variable'    : ['total_precipitation', '2m_temperature', 'minimum_2m_temperature_since_previous_post_processing', 'maximum_2m_temperature_since_previous_post_processing', 'surface_solar_radiation',],
            'product_type': 'reanalysis',
            'year'        : year_isue,
            'month'       : month_isue,
            'day'         : day_isue,
            'area': "-2.05/-81.95/-6.95/-78.05",
            'grid': "0.1/0.1", # los datos proporcionados por UFZ están bajo está resolución
            'time'        : [
                '00:00','01:00','02:00',
                '03:00','04:00','05:00',
                '06:00','07:00','08:00',
                '09:00','10:00','11:00',
                '12:00','13:00','14:00',
                '15:00','16:00','17:00',
                '18:00','19:00','20:00',
                '21:00','22:00','23:00'
            ],
            'format'      : 'netcdf'
    })
r.download(f'{ofile_hourly}')