; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-11-29 11:49:42 -0800 (Thu, 29 Nov 2018) $
; $LastChangedRevision: 26184 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/COMMON/spp_swp_crib.pro $
;spp_swp_crib
;

; change the default root data directory. This will affect all SPEDAS load files. I don't recomment changing from the default
;setenv,'ROOT_DATA_DIR=/cache/'       ; Can be put in personal startup file.  If you've been using SPEDAS you won't need this and I don't recomment changing it.


; Define a time range
timespan,'2018-10-3',1    ; 2 days starting on venus encounter

trange = timerange()        ; get global time range

printdat,time_string(trange)    ;  print the time range


; define a password
;setenv,'SPP_USER_PASS=guest:superspan'    ; A line like this can be put in each user's personal startup file.  I recommend: "idl_startup_$user$"  Where $user$ is your username.


ssrfile = spp_file_retrieve(/ssr)
spp_ssr_file_read,ssrfile


spp_swp_tplot,'swem',/setlim

spp_swp_tplot,'sumplot'





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


if 0 then begin
  
  ap = spp_apdat('spa_sf1')
  spe=spp_swp_spe_param()
  nums = spe.etables.keys()
  nrgsarr= =  findgen(32)  # replicate(1,22) 
  foreach n,nums do begin
    nrgsarr[*,n] = 
  endforeach
 
  
  
endif


if 0 then begin
  
  spp_swp_spane_3dtest,span=0,t1
  makepng,wind=1,'spec-b-1'
  spp_swp_spane_3dtest,span=0,t2
  makepng,wind=1,'spec-b-2'
  spp_swp_spane_3dtest,span=0,t3
  makepng,wind=1,'spec-b-3'
  spp_swp_spane_3dtest,span=0,t4
  makepng,wind=1,'spec-b-4'
  
  spp_swp_spane_3dtest,span=1,t1
  makepng,wind=1,'spec-a-1'
  spp_swp_spane_3dtest,span=1,t2
  makepng,wind=1,'spec-a-2'
  spp_swp_spane_3dtest,span=1,t3
  makepng,wind=1,'spec-a-3'
  spp_swp_spane_3dtest,span=1,t4
  makepng,wind=1,'spec-a-4'


endif



