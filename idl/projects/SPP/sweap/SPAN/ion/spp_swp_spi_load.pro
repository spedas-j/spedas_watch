;+
;
; $LastChangedBy: ali $
; $LastChangedDate: 2019-05-16 12:35:14 -0700 (Thu, 16 May 2019) $
; $LastChangedRevision: 27239 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_load.pro $
; Created by Davin Larson 2018
;
;-

pro spp_swp_spi_load,types=types,level=level,files=files,trange=trange,no_load=no_load,save=save,verbose=verbose,varformat=varformat

  if ~keyword_set(level) then level='L3'
  if ~keyword_set(types) then types=['sf00','sf01','af00','af01']

  ;; Product File Names
  dir='spi/'+level+'/YYYY/MM/spi_TYP/'
  fileformat=dir+'spp_swp_spi_TYP_'+level+'*_YYYYMMDD_v??.cdf'
  fileprefix='psp/data/sci/sweap/'

  ;; Product TPLOT Parameters
  vars = orderedhash()
  vars['hkp']    = '*TEMP* *_BITS *_FLAG* RAW_EVENTS'
  vars['fhkp']   = 'ADC'
  vars['tof']    = 'TOF'
  vars['rates']  = '*_CNTS'
  vars['events'] = 'TOF DT CHANNEL

  tr=timerange(trange)
  foreach type,types do begin

    ;; Instrument string substitution
    filetype=str_sub(fileformat,'TYP',type)
    prefix='psp_swp_spi_'+type+'_'+level+'_'

    ;; Find file locations
    files=spp_file_retrieve(filetype,trange=tr,/daily_names,/valid_only,prefix=fileprefix,verbose=verbose)

    if keyword_set(save) then begin
      vardata = !null
      novardata = !null
      loadcdfstr,filenames=files,vardata,novardata
      dummy=spp_data_product_hash('spi_'+type,vardata)
    endif

    ;; Do not load the files
    if keyword_set(no_load) then continue

    ;; Load TPLOT Formats
    if vars.haskey(type) and ~keyword_set(varformat) then varformat=vars[type]

    ;; Convert to TPLOT
    cdf2tplot,files,prefix=prefix,varformat=varformat,verbose=verbose

    ;; Set tplot Preferences
    ylim,prefix+'EFLUX_VS_ENERGY',100.,20e3,1,/default,verbose=0
    zlim,prefix+'EFLUX_VS_*',1,1,1,/default,verbose=0
    options,'spp_swp_spi_tof_L3_TOF',zlog=1,spec=1,/default,verbose=0
    options,prefix+'ADC',zlog=1,spec=1,/default,verbose=0
    options,prefix+'*_CNTS',zlog=1,spec=1,/default,verbose=0

  endforeach

end
