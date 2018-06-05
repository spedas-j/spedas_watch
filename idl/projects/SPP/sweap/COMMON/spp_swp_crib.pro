; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-06-03 18:19:29 -0700 (Sun, 03 Jun 2018) $
; $LastChangedRevision: 25316 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_crib.pro $
;spp_swp_crib
;

; change the default root data directory. This will affect all SPEDAS load files. I don't recomment changing from the default
;setenv,'ROOT_DATA_DIR=/mytestdata/'       ; Can be put in personal startup file.  If you've been using SPEDAS you won't need this and I don't recomment changing it.


; Define a time range
timespan,'2020-1-199',2    ; 2 days starting on July 17, 2020

trange = timerange()        ; get global time range

printdat,time_string(trange)    ;  print the time range


; define a password
setenv,'SPP_USER_PASS=guest:SWEAP-2018'    ; A line like this belongs can be put in each user's personal startup file.  I recommend: "idl_startup_$user$"  Where $user$ is your username.



; I don't yet have a wrapper routine for loading the data.  Do this by hand for SPANI rates packets.

; First test data
output_prefix = 'spp/data/sci/sweap/prelaunch/test3/SSR/'
ratesformat = output_prefix+ 'cdf/YYYY/MM/DD/spp_spi_rates_L1_YYYYMMDD.cdf'

;  Different test data  (includes unknown version number)
output_prefix = 'spp/data/sci/sweap/prelaunch/test5/SSR/'
ratesformat = output_prefix+ 'spanai/cdf/YYYY/MM/DD/spp_spi_rates_L1_YYYYMMDD_v??.cdf'

; go get the data from the website
cdffiles = spp_file_retrieve(ratesformat,trange=trange,/daily_names)
print,transpose(cdffiles)   ;print  the file names

; Run the same routne a second time to show that files only get downloaded as needed
cdffiles = spp_file_retrieve(ratesformat,trange=trange,/daily_names)


;I don't yet have a spanai specific load routine.  Now using the generic version and load all '*' data .
cdf2tplot,cdffiles,varformat = '*',prefix='psp_swp_spi_rates_

tplot_names   ; display the current variables

tplot,'psp_*_CNTS'

ylim,'psp_*_CNTS',1,10000,/log

tplot

options,'psp_*_CNTS',spec=1
ylim,'psp_*_CNTS'
zlim,'psp_*_CNTS',1,1e4,1

tplot     ; replot

tlimit, ['2020-07-17/21:54:00', '2020-07-18/09:56:00']

tlimit    ; use cross hairs to zoom in

tlimit,/last   ;  switch to last used tlimit


;Get some different (housekeeping) data:
ratesformat = output_prefix+ 'spanai/cdf/YYYY/MM/DD/spp_spi_hkp_L1_YYYYMMDD_v??.cdf'
cdffiles = spp_file_retrieve(ratesformat,trange=trange,/daily_names)
;I don't yet have a spanai specific load routine.  Now using the generic version and load all '*' data .
cdf2tplot,cdffiles,varformat = '*',prefix='psp_swp_spi_hkp_'



