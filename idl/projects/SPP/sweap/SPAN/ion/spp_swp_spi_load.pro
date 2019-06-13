;+
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-06-12 01:49:56 -0700 (Wed, 12 Jun 2019) $
; $LastChangedRevision: 27333 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_load.pro $
; Created by Davin Larson 2018
;
;-

pro spp_swp_spi_load_ovl,type=type,prefix=prefix

  overlay =1
  if keyword_set(overlay) && strmatch(type,'[sa]f??') then begin
    xyz_to_polar,prefix+'VEL'
    get_data,prefix+'VEL_mag',time,vel_mag
    store_data,prefix+'NRG0',time,velocity(vel_mag,/proton,/inverse)
    vname_nrg = prefix+['EFLUX_VS_ENERGY','NRG0']
    vname_th  = prefix+['EFLUX_VS_THETA','VEL_th']
    vname_phi = prefix+['EFLUX_VS_PHI','VEL_phi']

    spcname = 'psp_swp_spc_l3i_vp_moment_SC'
    spcname = 'psp_swp_spc_l3i_vp_fit_SC'
    if keyword_set(spcname) then begin   ; add SPC data
      dat = data_cut(spcname,time)       ; interpolate onto span timescale
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

    store_data,prefix+'EFLUX_VS_ENERGY_OVL',data = vname_nrg,dlimit={yrange:[100.,10000.],ylog:1,zlog:1}
    store_data,prefix+'EFLUX_VS_THETA_OVL',data =vname_th ,dlimit={yrange:[-60,60],ylog:0,zlog:1}
    store_data,prefix+'EFLUX_VS_PHI_OVL',data = vname_phi,dlimit={yrange:[90.,190.],ylog:0,zlog:1}
    
    options,'psp_swp_spc_l3i_np_fit',colors='b'
    options,'psp_swp_spc_l3i_np_moment',colors='c'
    store_data,'Density',data = 'psp_swp_spc_l3i_np_moment psp_swp_spc_l3i_np_fit psp_swp_spi_??0[01]_L3_DENS',dlimit={yrange:[10,600],ylog:1}
  endif
end





pro spp_swp_spi_load,types=types,level=level,files=files,trange=trange,no_load=no_load,tname_prefix=tname_prefix,save=save,$
  verbose=verbose,varformat=varformat,fileprefix=fileprefix,overlay=overlay
  

  if ~keyword_set(level) then level='L3'
  if ~keyword_set(types) then types=['sf00','sf01','af00','af01']

  ;; Product File Names
  dir='spi/'+level+'/YYYY/MM/spi_TYP/'
  fileformat=dir+'spp_swp_spi_TYP_'+level+'*_YYYYMMDD_v??.cdf'
  if not keyword_set(fileprefix) then fileprefix='psp/data/sci/sweap/'

  L2_fileformat =   'spi/L2/YYYY/MM/SP?_TYP/spp_swp_SP?_TYP_L2_8Dx32Ex8A_YYYYMMDD_v00.cdf'
  ; L3_fileformat = 'spi/L3/YYYY/MM/SP?_TYP/spp_swp_SP?_TYP_L3_8Dx32Ex8A_YYYYMMDD_v00.cdf' ; delete this line!
  L3_fileformat =   'spi/L3/YYYY/MM/SP?_TYP/spp_swp_SP?_TYP_L3_mom_INST_YYYYMMDD_v00.cdf'
  

  case strupcase(level) of
    'L2' : fileformat = L2_fileformat
    'L3' : fileformat = L3_fileformat
  endcase
  fileformat=str_sub(fileformat,'SP?','spi')

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

    prefix='psp_swp_spi_'+type+'_'+level+'_'
    if keyword_set(tname_prefix) then prefix=tname_prefix+prefix
    ;; Convert to TPLOT
    cdf2tplot,files,prefix=prefix,varformat=varformat,verbose=verbose

    ;; Set tplot Preferences
    ylim,prefix+'EFLUX_VS_ENERGY',100.,20e3,1,/default,verbose=0
    zlim,prefix+'EFLUX_VS_*',1e9,2e11,1,/default,verbose=0
    options,prefix+'VEL',colors='bgr',/default,yrange=[-800,200]
    options,prefix+'ADC',zlog=1,spec=1,/default,verbose=0
    options,prefix+'*_CNTS',zlog=1,spec=1,/default,verbose=0
    if keyword_set(overlay) && strmatch(type,'[sa]f??') then begin
      xyz_to_polar,prefix+'VEL'
      get_data,prefix+'VEL_mag',time,vel_mag
      store_data,prefix+'NRG0',time,velocity(vel_mag,/proton,/inverse)
      vname_nrg = prefix+['EFLUX_VS_ENERGY','NRG0']
      vname_th  = prefix+['EFLUX_VS_THETA','VEL_th']
      vname_phi = prefix+['EFLUX_VS_PHI','VEL_phi']
      
      spcname = 'psp_swp_spc_l3i_vp_moment_SC'
      spcname = 'psp_swp_spc_l3i_vp_fit_SC'
      if keyword_set(spcname) then begin   ; add SPC data
        dat = data_cut(spcname,time)       ; interpolate onto span timescale
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
      
      store_data,prefix+'EFLUX_VS_ENERGY_OVL',data = vname_nrg,dlimit={yrange:[100.,10000.],ylog:1,zlog:1}
      store_data,prefix+'EFLUX_VS_THETA_OVL',data =vname_th ,dlimit={yrange:[-60,60],ylog:0,zlog:1}
      store_data,prefix+'EFLUX_VS_PHI_OVL',data = vname_phi,dlimit={yrange:[90.,190.],ylog:0,zlog:1}
    endif

  endforeach
;  options,'psp_swp_spi_tof_L3_TOF',zlog=1,spec=1,/default,verbose=0

end
