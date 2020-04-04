; $LastChangedBy: davin-mac $
; $LastChangedDate: 2020-04-03 17:10:37 -0700 (Fri, 03 Apr 2020) $
; $LastChangedRevision: 28491 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_load.pro $
; Created by Davin Larson 2018
;
;-

pro spp_swp_spi_load,types=types,level=level,trange=trange,no_load=no_load,tname_prefix=tname_prefix,save=save,$
  verbose=verbose,varformat=varformat,fileprefix=fileprefix,overlay=overlay

  if ~keyword_set(level) then level='L3'
  level=strupcase(level)
  if ~keyword_set(types) then types=['sf00','sf01','sf0a']

  if types[0] eq 'all' then begin
    types=['hkp','fhkp','tof','rates','events']
    foreach type0,['s','a'] do foreach type1,['f','t'] do foreach type2,['0','1','2'] do foreach type3,['0','1','2','3','a'] do types=[types,type0+type1+type2+type3]
  endif

  ;; Product File Names
  ;dir='spi/'+level+'/YYYY/MM/spi_TYP/' ;old directory structure
  dir='spi/'+level+'/spi_TYP/YYYY/MM/'
  fileformat=dir+'psp_swp_spi_TYP_'+level+'*_YYYYMMDD_v??.cdf'
  if not keyword_set(fileprefix) then fileprefix='psp/data/sci/sweap/'

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

    ;; Find file locations
    dprint,filetype,/phelp
    files=spp_file_retrieve(filetype,trange=tr,/daily_names,/valid_only,/last_version,prefix=fileprefix,verbose=verbose)

    if keyword_set(save) then begin
      vardata = !null
      novardata = !null
      loadcdfstr,filenames=files,vardata,novardata
      dummy=spp_data_product_hash('spi_'+type+'_'+level,vardata)
    endif

    ;; Do not load the files
    if keyword_set(no_load) then continue

    ;; Load TPLOT Formats
    if keyword_set(varformat) then varformat2=varformat else if vars.haskey(type) then varformat2=vars[type] else varformat2=[]

    prefix='psp_swp_spi_'+type+'_'+level+'_'
    if keyword_set(tname_prefix) then prefix=tname_prefix+prefix
    ;; Convert to TPLOT
    cdf2tplot,files,prefix=prefix,varformat=varformat2,verbose=verbose
    spp_swp_qf,prefix=prefix

    if keyword_set(overlay) && strmatch(type,'[sa]f??') then begin
      xyz_to_polar,prefix+'VEL'
      get_data,prefix+'VEL_mag',time,vel_mag
      store_data,prefix+'NRG0',time,velocity(vel_mag,/proton,/inverse)
      vname_nrg = prefix+['EFLUX_VS_ENERGY','NRG0']
      vname_th  = prefix+['EFLUX_VS_THETA','VEL_th']
      vname_phi = prefix+['EFLUX_VS_PHI','VEL_phi']

      spcname = 'psp_swp_spc_l3i_vp_moment_SC'
      ;spcname = 'psp_swp_spc_l3i_vp_fit_SC'
      if keyword_set(spcname) then begin   ; add SPC data
        dat = data_cut(spcname,time)       ; interpolate onto span timescale
        if keyword_set(dat) then begin
          store_data,prefix+'SPCVEL',time,dat
          param=spp_swp_spi_param2(detname='spi')
          rotmat = param.cal.rotmat_sc_inst
          newname = rotate_data(prefix+'SPCVEL',rotmat,name='SPI' )   ;,repname='_SC')
          xyz_to_polar,newname,/ph_0_360
          get_data,newname+'_mag',time,vel_mag
          store_data,newname+'_nrg',time,velocity(vel_mag,/proton,/inverse)
          options,newname+'_*',colors='b'
          vname_nrg = [vname_nrg,newname+'_nrg']
          vname_th = [vname_th,newname+'_th']
          vname_phi = [vname_phi,newname+'_phi']
        endif
      endif

      store_data,prefix+'EFLUX_VS_ENERGY_OVL',data = vname_nrg,dlimit={yrange:[100.,20000.],ylog:1,zlog:1}
      store_data,prefix+'EFLUX_VS_THETA_OVL',data =vname_th ,dlimit={yrange:[-60,60],ylog:0,zlog:1}
      store_data,prefix+'EFLUX_VS_PHI_OVL',data = vname_phi,dlimit={yrange:[90.,190.],ylog:0,zlog:1}
    endif

  endforeach
  options,'psp_swp_spi_sf??_L3_VEL',colors='bgr',labels=['Vx','Vy','Vz'],labflag=-1

  ;; Set tplot Preferences
  if level eq 'L1' then begin
    options,'psp_swp_spi_fhkp_L1_ADC',zlog=1,spec=1
    options,'psp_swp_spi_tof_L1_TOF',zlog=1,spec=1
    options,'psp_swp_spi_rates_L1_*_CNTS',zlog=1,spec=1
  endif

  if keyword_set(overlay) then begin
    options,'psp_swp_spc_l3i_np_fit',colors='b'
    options,'psp_swp_spc_l3i_np_moment',colors='c'
    store_data,'psp_swp_density',data = 'psp_swp_spc_l3i_np_moment psp_swp_spc_l3i_np_fit psp_swp_spi_??0[01]_L3_DENS',dlimit={yrange:[10,600],ylog:1}
  endif

end
