;--------------------------------------------------------------------
; PSP SPAN Crib
; 
; Currently this holds all the scrap pieces from calibration / instrument development, which will get moved
; Also includes a log of the calibration files and instructions for processing them
; 
; In the future this will include instructions for looking at flight data:  IN PROG
; 
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2018-12-07 14:52:40 -0800 (Fri, 07 Dec 2018) $
; $LastChangedRevision: 26276 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/common/spp_swp_span_crib.pro $
;--------------------------------------------------------------------

; BASIC STEPS TO LOOKING AT DATA
; 
; Notes on Data Names:
; 
;   SPAN-E produces two products for data taken during the same 
;   time interval: a "P0" and a "P1" packet. The P0 packet will 
;   always be a higher-dimension product than the P1 packet. By
;   default, P0 is a 16X32X8 3D spectrum, and P1 is a 32 reduced 
;   energy spectrum. 
;   
;   SPAN-E also produces Archive and Survey data - expect the
;   Survey data all the time during encounter. Archive is few 
;   and far between since it's high rate data and takes up a lot
;   of downlink to pull from the spacecraft. 
;   
;   The last thing you need to know is that SPAN-E alternates
;   every other accumulation period sweeping either over the 
;   "Full" range of energies and deflectors, or a "Targeted" 
;   range where the signal is at a maximum.
;   
;   Therefore, when you look at the science data from SPAN-E, 
;   you can pull a "Survey, Full, 3D" distribution by calling
;   
;   IDL> tplot_names, '*sp[a,b]*SF0*SPEC*
;   
;   And the slices through that distribution will be called.
;   
;   Enjoy!
;   
;   



pro spp_swp_span_download_files,trange=trange

pathname = 'psp/data/sci/
L2_prefix='psp/data/sci/sweap/'
L2_fileformat = 'psp/data/sci/sweap/SP?/L2/YYYY/MM/SP?_TYP/spp_swp_SP?_TYP_L2_*_YYYYMMDD_v??.cdf'

spxs = ['spa','spb']
types = ['sf0','sf1','st1','st0']   ; add archive when available
tr = timerange(trange)

foreach type,types do begin
  foreach spx, spxs do begin
    fileformat = str_sub(L2_fileformat,'SP?', spx)              ; instrument string substitution
    fileformat = str_sub(fileformat,'TYP',type)                 ; packet type substitution
    L2_files = spp_file_retrieve(fileformat,trange=tr,/daily_names,/valid_only,prefix=ssr_prefix)
  endforeach
endforeach

end


pro spp_swp_span_load,spxs=spxs,types=types,trange=trange,no_load=no_load

  if ~keyword_set(spxs) then spxs = ['spa','spb']
  if 0 then begin
    spxs = orderedhash()
    spxs['spa'] = list('sf0','sf1','st1','st0')
    spxs['spb'] = spxs['spa']
    spxs['spi'] = list('sf20','sf10')
    spxs['spc'] = list('L2i')    
  endif
  prefix = 'psp/data/sci/sweap/'
  
  if ~keyword_set(stypes) then stypes = ['sf0','sf1','st1','st0']   ; add archive when available
  tr = timerange(trange)
  L2_fileformat = 'SP?/L2/YYYY/MM/SP?_TYP/spp_swp_SP?_TYP_L2_*_YYYYMMDD_v??.cdf'
  foreach type,types do begin
    foreach spx, spxs do begin
      fileformat = str_sub(L2_fileformat,'SP?', spx)              ; instrument string substitution
      fileformat = str_sub(fileformat,'TYP',type)                 ; packet type substitution
      L2_files = spp_file_retrieve(fileformat,trange=tr,/daily_names,/valid_only,prefix=prefix,verbose=2)
      if keyword_set(no_load) then continue
      cdf2tplot,l2_files
    endforeach
  endforeach

end

if 0 then begin
  timespan,'2018 10 2',3
  spp_swp_spe_make_l2  
endif

if 0 then begin
  spc_format = 'psp/data/sci/sweap/spc/L2/YYYY/MM/spp_swp_spc_l2i_YYYYMMDD_v??.cdf'
  spc_files = spp_file_retrieve(spc_format,/daily_names,/valid_only,/last_version,prefix=ssr_prefix,verbose=2,trange=tr)
  cdf2tplot,spc_files,prefix= 'psp_swp_spc_'

  spa_format = 'psp/data/sci/sweap/spa/L2/YYYY/MM/spa_sf1/spp_swp_spa_sf1_L2_*_YYYYMMDD_v??.cdf'
  spa_files = spp_file_retrieve(spa_format,/daily_names,/valid_only,/last_version,prefix=ssr_prefix,verbose=2,trange=tr)
  cdf2tplot,spa_files,prefix = 'psp_swp_spa_sf1_',varformat='EFLUX EMODE'

  spa_format = 'psp/data/sci/sweap/spa/L1/YYYY/MM/spa_sf1/spp_swp_spa_sf1_L1_YYYYMMDD_v??.cdf'
  spa_files = spp_file_retrieve(spa_format,/daily_names,/valid_only,/last_version,prefix=ssr_prefix,verbose=2,trange=tr)
  cdf2tplot,spa_files,prefix = 'psp_swp_spa_L1_sf1_',varformat='PDATA'

  spb_format = 'psp/data/sci/sweap/spb/L2/YYYY/MM/spa_sf0/spp_swp_spb_sf0_*_YYYYMMDD_v??.cdf'
  spb_files = spp_file_retrieve(spa_format,/daily_names,/valid_only,/last_version,prefix=ssr_prefix,verbose=2,trange=tr)
  cdf2tplot,spb_files,prefix = 'psp_swp_spb_sf0_'
  
endif


;spp_swp_span_load,spxs='spa',types='sf0'

end

