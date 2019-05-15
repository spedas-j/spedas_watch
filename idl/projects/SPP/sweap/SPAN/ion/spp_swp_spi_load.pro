;+
;
; $LastChangedBy: ali $
; $LastChangedDate: 2019-05-14 14:17:46 -0700 (Tue, 14 May 2019) $
; $LastChangedRevision: 27231 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_load.pro $
; Created by Davin Larson 2018
;
;-

pro spp_swp_spi_load,types=types,level=level,trange=trange,no_load=no_load,save=save,verbose=verbose

  if ~keyword_set(level) then level='L3'
  if ~keyword_set(types) then types=['sf00', 'sf01','af00', 'af01']

  dir = 'SP?/'+level+'/YYYY/MM/SP?_TYP/'
  l2or3=dir+'spp_swp_SP?_TYP_'+level+'_8Dx32Ex8A_YYYYMMDD_v??.cdf'
  fileprefix='spp/data/sci/sweap/'

  ;; Product File Names
  loc=orderedhash()
  loc['sf00'] =l2or3
  loc['sf01'] =l2or3
  loc['af00'] =l2or3
  loc['af01'] =l2or3
  loc['hkp']  ='SP?/L1/YYYY/MM/SP?_hkp/spp_swp_SP?_hkp_L1_YYYYMMDD_v??.cdf'
  loc['tof']  ='SP?/L1/YYYY/MM/SP?_tof/spp_swp_SP?_tof_L1_YYYYMMDD_v??.cdf'
  loc['rates']='spi/L1/YYYY/MM/SP?_rates/spp_swp_spi_rates_L1_YYYYMMDD_v??.cdf'

  ;; Product TPLOT Parameters
  vars = orderedhash()
  vars['hkp']    = '*TEMP* *_BITS *_FLAG* RAW_EVENTS'
  vars['tof']    = 'TOF'
  vars['rates']  = 'VALID_CNTS'
  ;;vars['events']

  tr = timerange(trange)
  foreach type,types do begin

    ;; Instrument string substitution
    fileformat = str_sub(loc[type],'SP?', 'spi')
    fileformat = str_sub(fileformat,'TYP',type)
    prefix = 'psp_swp_spi_'+type+'_'+level+'_'

    ;; Find file locations
    files = spp_file_retrieve(fileformat,trange=tr,/daily_names,/valid_only,prefix=fileprefix,verbose=verbose)

    if keyword_set(save) then begin
      vardata = !null
      novardata = !null
      loadcdfstr,filenames=files,vardata,novardata
      dummy = spp_data_product_hash('spi_'+type,vardata)
    endif

    ;; Do not load the files
    if keyword_set(no_load) then continue

    ;; Load TPLOT Formats
    if vars.haskey(type) then varformat=vars[type]

    ;; Convert to TPLOT
    cdf2tplot,files,prefix=prefix,varformat=varformat,verbose=verbose

    ;; Set tplot Preferences
    ylim,prefix+'EFLUX_VS_ENERGY',100.,20e3,1,/default,verbose=0
    zlim,prefix+'EFLUX_VS_*',1,1,1,/default,verbose=0
    options,prefix+'TOF',zlog=1,spec=1,/default,verbose=0
    options,prefix+'VALID_CNTS',zlog=1,spec=1,/default,verbose=0

  endforeach

end
