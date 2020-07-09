;+
; NAME:
;   rbsp_efw_make_l4
;
; PURPOSE:
;   Generate level-4 EFW CDF files
;
;
; CALLING SEQUENCE:
;   rbsp_efw_make_l4, sc, date
;
; ARGUMENTS:
;   sc: IN, REQUIRED
;         'a' or 'b'
;   date: IN, REQUIRED
;         A date string in format like '2013-02-13'
;
; KEYWORDS:
;   folder: IN, OPTIONAL
;         Default is something like
;           !rbsp_efw.local_data_dir/rbspa/l2/spinfit/2012/
;
;
;   boom_pair -> specify for the spinfit routine. E.g. '12', '34', '24', etc.
;                Defaults to '12'
;
;
;
; HISTORY:
;   Jan 2020: Created by Aaron W Breneman, U. Minnesota
;
;
; VERSION:
; $LastChangedBy: aaronbreneman $
; $LastChangedDate: 2020-07-08 08:38:26 -0700 (Wed, 08 Jul 2020) $
; $LastChangedRevision: 28864 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/rbsp/efw/cdf_file_production/rbsp_efw_make_l4.pro $
;
;-

;***********************************************
;Spinfits with E*B=0  - all boompairs
;The "best" spinfit duplicated and called something else.
;All density calculations

;***********************************************



pro rbsp_efw_make_l4,sc,date,$
  folder=folder,$
  version=version,$
  testing=testing,$
  density_min=dmin


  if ~keyword_set(dmin) then dmin = 10.


  if ~keyword_set(testing) then begin
     openw,lun,'output.txt',/get_lun
     printf,lun,'date = ',date
     printf,lun,'date type: ',typename(date)
     printf,lun,'probe = ',sc
     printf,lun,'probe type: ',typename(sc)
     printf,lun,'bp = ',bp

     close,lun
     free_lun,lun
  endif


;*********WHAT IS THIS????
  compile_opt idl2
  ;*********WHAT IS THIS????


  timespan,date


  ;Clean slate
  store_data,tnames(),/delete


  ;Only download if you don't have the file locally
  extra_spicelocation = create_struct('local_spice_only_if_exist_locally',1)


  ;Initial (and only) load of these
  rbsp_load_spice_kernels,_extra=extra_spicelocation
  rbsp_efw_init


  ;Define keyword inheritance to pass to subroutines. This will ensure that
  ;subsequent routines don't reload spice kernels or rbsp_efw_init
  extra = create_struct('no_spice_load',1,$
                        'no_rbsp_efw_init',1,$
                        'no_waveform_load',0,$
                        'no_emfisis_load',0)


  if n_elements(version) eq 0 then version = 1
  vstr = string(version, format='(I02)')

  rbx = 'rbsp' + strlowcase(sc[0]) + '_'


;------------ Set up paths. BEGIN. ----------------------------


  year = strmid(date, 0, 4)

  if ~keyword_set(folder) then folder = !rbsp_efw.local_data_dir + $
                                       'rbsp' + strlowcase(sc[0]) + path_sep() + $
                                       'l2' + path_sep() + $
                                       'spinfit' + path_sep() + $
                                       year + path_sep()

  ;make sure we have the trailing slash on folder
  if strmid(folder,strlen(folder)-1,1) ne path_sep() then folder=folder+path_sep()
  if ~keyword_set(no_cdf) then file_mkdir, folder



  ;Grab the skeleton file.
  ;     skeleton='/Volumes/UserA/user_homes/kersten/RBSP_l2/'+rbspx+'_efw-l2_00000000_v02.cdf'
  skeleton='/Volumes/UserA/user_homes/kersten/Code/tdas_svn_daily/general/missions/rbsp/efw/l1_to_l2/'+rbx+'efw-lX_00000000_vXX.cdf'


  ;make sure we have the skeleton CDF
  found = 1
  if ~keyword_set(testing) then skeletonFile=file_search(skeleton,count=found)
  if keyword_set(testing) then $
    skeletonfile = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/rbsp'+$
                   sc+'_efw-lX_00000000_vXX.cdf'



  if ~found then begin
    dprint,'Could not find skeleton CDF, returning.'
    return
  endif
                            ; fix single element source file array
  skeletonFile=skeletonFile[0]

  if keyword_set(testing) then folder = '~/Desktop/code/Aaron/RBSP/TDAS_trunk_svn/general/missions/rbsp/efw/l1_to_l2/'



;------------ Set up paths. END. ----------------------------


  ;Load ECT's magnetic ephemeris
  rbsp_read_ect_mag_ephem,sc



  ;Load both the spinfit data and also the E*B=0 version

  bps = ['12','13','14','23','24','34']


  for uu=0,n_elements(bps)-1 do begin
    rbsp_efw_edotb_to_zero_crib,date,sc,$
      /noplot,$
      suffix='edotb',$
      boom_pair=bps[uu],$
      /noremove,$   ;Don't remove "bad" E*B=0 data
      _extra=extra


    ;data not always on exact same time base
    tinterpol_mxn,rbx+'efw_esvy_mgse_vxb_removed_spinfit',times,/overwrite,/spline
    tinterpol_mxn,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit',times,/overwrite,/spline
    tinterpol_mxn,rbx+'efw_esvy_mgse_vxb_removed_spinfit_edotb',times,/overwrite,/spline
    tinterpol_mxn,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb',times,/overwrite,/spline


    ;Rename useful variables based on their boom pair
    copy_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit',rbx+'efw_esvy_mgse_vxb_removed_spinfit_'+bps[uu]
    copy_data,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit',rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_'+bps[uu]
    copy_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit_edotb',rbx+'efw_esvy_mgse_vxb_removed_spinfit_edotb_'+bps[uu]
    copy_data,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb',rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_'+bps[uu]


    ;For each boompair
    if uu eq 0 then begin

      ;Get the official times to which all quantities are interpolated to
      ;For spinfit data use the spinfit times.
      get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit_'+bps[0],data=tmp
      times = tmp.x
      epoch = tplot_time_to_epoch(times,/epoch16)


      ;Interpolate Vsvy data to time base
      tinterpol_mxn,rbx+'efw_vsvy',times,/spline;,/overwrite
      get_data,rbx+'efw_vsvy_interp',data=vsvy


      ;Following calls don't need to load waveform or EMFISIS data
      extra.no_waveform_load = 1.
      extra.no_emfisis_load = 1.
    endif


    store_data,[rbx+'efw_esvy_mgse_vxb_removed_spinfit',$
                rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit',$
                rbx+'efw_esvy_mgse_vxb_removed_spinfit_edotb',$
                rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb'],/del

  endfor







  ;; full resolution (V1+V2)/2
  vsvy_vavg = [[(vsvy.y[*,0] - vsvy.y[*,1])/2.],$
               [(vsvy.y[*,0] - vsvy.y[*,2])/2.],$
               [(vsvy.y[*,0] - vsvy.y[*,3])/2.],$
               [(vsvy.y[*,1] - vsvy.y[*,2])/2.],$
               [(vsvy.y[*,1] - vsvy.y[*,3])/2.],$
               [(vsvy.y[*,2] - vsvy.y[*,3])/2.]]



  ;--------------------------------------------------
  ;Get flag values (also gets density values from v12 and v34)
  ;--------------------------------------------------

;  stop

  ;*********************************************
  ;*********************************************
;*********************************************
;save,/all,filename='~/Desktop/l4_sav.sav'
;tplot_save,'*',filename='~/Desktop/l4_sav.tplot'
;*********************************************
;*********************************************
;*********************************************

  flag_str12 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='12',_extra=extra)
  flag_str13 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='13',_extra=extra)
  flag_str14 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='14',_extra=extra)
  flag_str23 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='23',_extra=extra)
  flag_str24 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='24',_extra=extra)
  flag_str34 = rbsp_efw_get_flag_values(sc,times,density_min=dmin,boom_pair='34',_extra=extra)


  ;Create master flag array
  flag_arr = intarr(n_elements(times),20,n_elements(bps))
  flag_arr[*,*,0] = flag_str12.flag_arr
  flag_arr[*,*,1] = flag_str13.flag_arr
  flag_arr[*,*,2] = flag_str14.flag_arr
  flag_arr[*,*,3] = flag_str23.flag_arr
  flag_arr[*,*,4] = flag_str24.flag_arr
  flag_arr[*,*,5] = flag_str34.flag_arr

;   flag_arr = flag_str.flag_arr
;   bias_sweep_flag = flag_str.bias_sweep_flag
;   ab_flag = flag_str.ab_flag
;   charging_flag = flag_str.charging_flag
;   ibias = flag_str12.ibias


;-------------------------------------------------------
   ;Get diagnostics related to the E*B=0 calculation
;-------------------------------------------------------

;*******************************
;*******************************
;NEED TO DO THIS FOR EACH BOOM PAIR
;*******************************
;*******************************

   ;By/Bx and Bz/Bx
   get_data,'B2Bx_ratio',data=edotb_b2bx_ratio
   if is_struct(edotb_b2bx_ratio) then begin
     badyx = where(edotb_b2bx_ratio.y[*,0] gt 3.732)
     badzx = where(edotb_b2bx_ratio.y[*,1] gt 3.732)
   endif



   ;--------------------------------------------------
   ;Get burst times
   ;This is a bit complicated for spinperiod data b/c the short
   ;B2 snippets can be less than the spinperiod.
   ;So, I'm padding the B2 times by +/- a half spinperiod so that they don't
   ;disappear upon interpolation to the spinperiod data.
   ;--------------------------------------------------


   b1_flag = intarr(n_elements(times))
   b2_flag = b1_flag

   ;get B1 times and rates from this routine
   b1t = rbsp_get_burst_times_rates_list(sc)

   ;get B2 times from this routine
   b2t = rbsp_get_burst2_times_list(sc)
   ;Pad B2 by +/- half spinperiod
   b2t.startb2 -= 6.
   b2t.endb2   += 6.

   for q=0,n_elements(b1t.startb1)-1 do begin $
     goodtimes = where((times ge b1t.startb1[q]) and (times le b1t.endb1[q])) & $
     if goodtimes[0] ne -1 then b1_flag[goodtimes] = b1t.samplerate[q]
   endfor
   for q=0,n_elements(b2t.startb2[*,0])-1 do begin $
     goodtimes = where((times ge b2t.startb2[q]) and (times le b2t.endb2[q])) & $
     if goodtimes[0] ne -1 then b2_flag[goodtimes] = 1
   endfor



  ;--------------------------------------------------
  ;save all spinfit resolution Efield quantities
  ;--------------------------------------------------
  ;*******************************
  ;*******************************
  ;NEED TO DO THIS FOR EACH BOOM PAIR
  ;*******************************
  ;*******************************

;  eclipse_tmp = where(flag_arr[*,1] eq 1)
  eclipse_tmp = where(flag_str12.flag_arr[*,1] eq 1)

  efield_inertial_spinfit_mgse = fltarr(n_elements(times),3,n_elements(bps))
  efield_corotation_spinfit_mgse = fltarr(n_elements(times),3,n_elements(bps))
  efield_inertial_spinfit_edotb_mgse = fltarr(n_elements(times),3,n_elements(bps))
  efield_corotation_spinfit_edotb_mgse = fltarr(n_elements(times),3,n_elements(bps))



  ;Populate the Efield variables
  for uu=0,n_elements(bps)-1 do begin

    get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit_'+bps[uu],data=tmp
    if is_struct(tmp) then begin
;          tmp.y[*,0] = -1.0E31  ;remove spin-axis component
;          if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,1] = -1.0E31
;          if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,2] = -1.0E31
       efield_inertial_spinfit_mgse[*,*,uu] = tmp.y
       tmp = 0.
    endif

    get_data,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_'+bps[uu],data=tmp
    if is_struct(tmp) then begin
;          tmp.y[*,0] = -1.0E31  ;remove spin-axis component
;          if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,1] = -1.0E31
;          if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,2] = -1.0E31
       efield_corotation_spinfit_mgse[*,*,uu] = tmp.y
       tmp = 0.
    endif

    get_data,rbx+'efw_esvy_mgse_vxb_removed_spinfit_edotb_'+bps[uu],data=tmp
    if is_struct(tmp) then begin
;      if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,*] = -1.0E31
;      ;Remove spin-axis component if not reliable
;      if badyx[0] ne -1 then tmp.y[badyx,0] = -1.0E31
;      if badzx[0] ne -1 then tmp.y[badzx,0] = -1.0E31
      efield_inertial_spinfit_edotb_mgse[*,*,uu] = tmp.y
      tmp = 0.
    endif

    get_data,rbx+'efw_esvy_mgse_vxb_removed_coro_removed_spinfit_edotb_'+bps[uu],data=tmp
    if is_struct(tmp) then begin
;          if eclipse_tmp[0] ne -1 then tmp.y[eclipse_tmp,*] = -1.0E31
          ;Remove spin-axis component if not reliable
;          if badyx[0] ne -1 then tmp.y[badyx,0] = -1.0E31
;          if badzx[0] ne -1 then tmp.y[badzx,0] = -1.0E31
       efield_corotation_spinfit_edotb_mgse[*,*,uu] = tmp.y
       tmp = 0.
    endif

  endfor

  ;--------------------------------------------------
  ;Nan out various values when global flag is thrown
  ;--------------------------------------------------


  ;Set the density and density flag based on the antenna pair used.
  flag_arr[*,16,*] = 0
  density = fltarr(n_elements(times),n_elements(bps))
  for uu=0,n_elements(bps)-1 do begin
    tinterpol_mxn,rbx+'density'+bps[uu],times,/overwrite,/spline
    get_data,rbx+'density'+bps[uu],data=tmp
    density[*,uu] = tmp.y
    if uu eq 0 then goo = where(flag_str12.flag_arr[*,0] eq 1)
    if uu eq 1 then goo = where(flag_str13.flag_arr[*,0] eq 1)
    if uu eq 2 then goo = where(flag_str14.flag_arr[*,0] eq 1)
    if uu eq 3 then goo = where(flag_str23.flag_arr[*,0] eq 1)
    if uu eq 4 then goo = where(flag_str24.flag_arr[*,0] eq 1)
    if uu eq 5 then goo = where(flag_str34.flag_arr[*,0] eq 1)
    ;    if goo[0] ne -1 and is_struct(tmp) then density[goo,uu] = -1.e31
    if goo[0] ne -1 and is_struct(tmp) then flag_arr[goo,16,uu] = 1
  endfor



  ;--------------------------------------------------
  ;Set a 3D flag variable for the survey plots
  ;--------------------------------------------------

  ;Flags for each time and boom pair
  ;charging, autobias, eclipse, and extreme charging flags all in one variable for convenience
  flags = fltarr(n_elements(times),4,n_elements(bps))

  flags[*,*,0] = [[flag_str12.flag_arr[*,15]],[flag_str12.flag_arr[*,14]],[flag_str12.flag_arr[*,1]],[flag_str12.flag_arr[*,16]]]
  flags[*,*,1] = [[flag_str13.flag_arr[*,15]],[flag_str13.flag_arr[*,14]],[flag_str13.flag_arr[*,1]],[flag_str13.flag_arr[*,16]]]
  flags[*,*,2] = [[flag_str14.flag_arr[*,15]],[flag_str14.flag_arr[*,14]],[flag_str14.flag_arr[*,1]],[flag_str14.flag_arr[*,16]]]
  flags[*,*,3] = [[flag_str23.flag_arr[*,15]],[flag_str23.flag_arr[*,14]],[flag_str23.flag_arr[*,1]],[flag_str23.flag_arr[*,16]]]
  flags[*,*,4] = [[flag_str24.flag_arr[*,15]],[flag_str24.flag_arr[*,14]],[flag_str24.flag_arr[*,1]],[flag_str24.flag_arr[*,16]]]
  flags[*,*,5] = [[flag_str34.flag_arr[*,15]],[flag_str34.flag_arr[*,14]],[flag_str34.flag_arr[*,1]],[flag_str34.flag_arr[*,16]]]
;  flags = [[flag_arr[*,15]],[flag_arr[*,14]],[flag_arr[*,1]],[flag_arr[*,16]]]



;  for uu=0,n_elements(bps)-1 do begin $
;    goo = where(density[*,uu] eq -1.e31) & $
;    if goo[0] ne -1 then flag_arr[goo,16,uu] = 1
;  endfor


  ;the times for the mag spinfit can be slightly different than the times for the
  ;Esvy spinfit.
  tinterpol_mxn,rbx+'mag_mgse',times,newname=rbx+'mag_mgse',/spline
  get_data,rbx+'mag_mgse',data=mag_mgse


  ;Downsample the GSE position and velocity variables to cadence of spinfit data
  varstmp = [rbx+'E_coro_mgse',rbx+'vscxb',rbx+'state_vel_coro_mgse',rbx+'state_pos_gse',$
  rbx+'state_vel_gse',$
  rbx+'state_mlt',rbx+'state_mlat',rbx+'state_lshell',$
  rbx+'ME_orbitnumber',rbx+'spinaxis_direction_gse','angles']


  ;Interpolate all data to common time base
  for qq=0,n_elements(varstmp)-1 do tinterpol_mxn,varstmp[qq],times,newname=varstmp[qq],/spline

  ;Grab all the data
  get_data,rbx+'vxb',data=vxb
  get_data,rbx+'state_pos_gse',data=pos_gse
  get_data,rbx+'state_vel_gse',data=vel_gse
  get_data,rbx+'E_coro_mgse',data=corotation_efield_mgse
  ;get_data,rbx+'state_vel_coro_mgse',data=vcoro_mgse
  get_data,rbx+'spinaxis_direction_gse',data=sa
  get_data,rbx+'angles',data=angles
  get_data,rbx+'state_mlt',data=mlt
  get_data,rbx+'state_mlat',data=mlat
  get_data,rbx+'state_lshell',data=lshell
  get_data,rbx+'ME_orbitnumber',data=orbit_num

  if is_struct(orbit_num) then orbit_num = orbit_num.y else orbit_num = replicate(-1.e31,n_elements(times))
;  if is_struct(lstar) then lstar = lstar.y[*,0]


  year = strmid(date,0,4) & mm = strmid(date,5,2) & dd = strmid(date,8,2)


  datafile = folder+rbx+'efw-l4_e-spinfit-mgse_'+year+mm+dd+'_v'+vstr+'.cdf'

  file_copy, skeletonFile, datafile, /overwrite ; Force to replace old file.
  cdfid = cdf_open(datafile)



  ;Final list of variables to NOT delete
  varsave_general = ['diagBratio',$
    'epoch',$
    'efield_inertial_spinfit_mgse_12',$
    'efield_inertial_spinfit_mgse_13',$
    'efield_inertial_spinfit_mgse_14',$
    'efield_inertial_spinfit_mgse_23',$
    'efield_inertial_spinfit_mgse_24',$
    'efield_inertial_spinfit_mgse_34',$
    'efield_corotation_spinfit_mgse_12',$
    'efield_corotation_spinfit_mgse_13',$
    'efield_corotation_spinfit_mgse_14',$
    'efield_corotation_spinfit_mgse_23',$
    'efield_corotation_spinfit_mgse_24',$
    'efield_corotation_spinfit_mgse_34',$
    'efield_inertial_spinfit_edotb_mgse_12',$
    'efield_inertial_spinfit_edotb_mgse_13',$
    'efield_inertial_spinfit_edotb_mgse_14',$
    'efield_inertial_spinfit_edotb_mgse_23',$
    'efield_inertial_spinfit_edotb_mgse_24',$
    'efield_inertial_spinfit_edotb_mgse_34',$
    'efield_corotation_spinfit_edotb_mgse_12',$
    'efield_corotation_spinfit_edotb_mgse_13',$
    'efield_corotation_spinfit_edotb_mgse_14',$
    'efield_corotation_spinfit_edotb_mgse_23',$
    'efield_corotation_spinfit_edotb_mgse_24',$
    'efield_corotation_spinfit_edotb_mgse_34',$
    'corotation_efield_mgse',$
    'vsvy_vavg_combo',$
;    'VxB_mgse','velocity_corotation_mgse',$
    'density_12',$
    'density_13',$
    'density_14',$
    'density_23',$
    'density_24',$
    'density_34',$
    'orbit_num','velocity_gse','position_gse','angle_spinplane_Bo','mlt','mlat','lshell',$
    'spinaxis_gse',$
    'flags_all_12',$
    'flags_all_13',$
    'flags_all_14',$
    'flags_all_23',$
    'flags_all_24',$
    'flags_all_34',$
    'flags_charging_bias_eclipse_12',$
    'flags_charging_bias_eclipse_13',$
    'flags_charging_bias_eclipse_14',$
    'flags_charging_bias_eclipse_23',$
    'flags_charging_bias_eclipse_24',$
    'flags_charging_bias_eclipse_34',$
    'burst1_avail',$
    'burst2_avail']




;  ;Rename the appropriate variables to more generic names. The rest will get deleted.
;  cdf_varrename,cdfid,'efield_spinfit_mgse_'+bp,'efield_spinfit_mgse'
;  cdf_varrename,cdfid,'efield_inertial_spinfit_mgse_'+bp,'efield_inertial_spinfit_mgse'
;  cdf_varrename,cdfid,'efield_corotation_spinfit_mgse_'+bp,'efield_corotation_spinfit_mgse'
;  cdf_varrename,cdfid,'efield_inertial_spinfit_edotb_mgse_'+bp,'efield_inertial_spinfit_edotb_mgse'
;  cdf_varrename,cdfid,'efield_corotation_spinfit_edotb_mgse_'+bp,'efield_corotation_spinfit_edotb_mgse'
;  cdf_varrename,cdfid,'density_'+bp,'density'


  ;Now that we have renamed some of the variables to our liking,
  ;get list of all the variable names in the CDF file.
  inq = cdf_inquire(cdfid)
  CDFvarnames = ''
  for varNum = 0, inq.nzvars-1 do begin $
    stmp = cdf_varinq(cdfid,varnum,/zvariable) & $
    if stmp.recvar eq 'VARY' then CDFvarnames = [CDFvarnames,stmp.name]
  endfor
  CDFvarnames = CDFvarnames[1:n_elements(CDFvarnames)-1]



  ;Delete all variables we don't want to save.
  for qq=0,n_elements(CDFvarnames)-1 do begin $
    tstt = array_contains(varsave_general,CDFvarnames[qq]) & $
    if not tstt then print,'Deleting var:  ', CDFvarnames[qq]
    if not tstt then cdf_vardelete,cdfid,CDFvarnames[qq]
  endfor




  ;--------------------------------------------------
  ;Populate the remaining variables
  ;--------------------------------------------------

;NOTE: VARIABLES TO ADD
;  'vel_coro_mgse',$

;***********************************
;STOP  ------I'M HERE
;***********************************
;***********************************
;***********************************
;***********************************
;***********************************
;***********************************
;***********************************

;NEED TO CREATE THE BELOW FLAG VARIABLES FOR EACH BOOM PAIR

  cdf_varput,cdfid,'epoch',epoch
  cdf_varput,cdfid,'flags_charging_bias_eclipse_12',transpose(flags[*,*,0])
  cdf_varput,cdfid,'flags_charging_bias_eclipse_13',transpose(flags[*,*,1])
  cdf_varput,cdfid,'flags_charging_bias_eclipse_14',transpose(flags[*,*,2])
  cdf_varput,cdfid,'flags_charging_bias_eclipse_23',transpose(flags[*,*,3])
  cdf_varput,cdfid,'flags_charging_bias_eclipse_24',transpose(flags[*,*,4])
  cdf_varput,cdfid,'flags_charging_bias_eclipse_34',transpose(flags[*,*,5])
  cdf_varput,cdfid,'flags_all_12',transpose(flag_arr[*,*,0])
  cdf_varput,cdfid,'flags_all_13',transpose(flag_arr[*,*,1])
  cdf_varput,cdfid,'flags_all_14',transpose(flag_arr[*,*,2])
  cdf_varput,cdfid,'flags_all_23',transpose(flag_arr[*,*,3])
  cdf_varput,cdfid,'flags_all_24',transpose(flag_arr[*,*,4])
  cdf_varput,cdfid,'flags_all_34',transpose(flag_arr[*,*,5])
  cdf_varput,cdfid,'burst1_avail',b1_flag
  cdf_varput,cdfid,'burst2_avail',b2_flag


  cdf_varput,cdfid,'efield_inertial_spinfit_mgse_12',transpose(efield_inertial_spinfit_mgse[*,*,0])
  cdf_varput,cdfid,'efield_inertial_spinfit_mgse_13',transpose(efield_inertial_spinfit_mgse[*,*,1])
  cdf_varput,cdfid,'efield_inertial_spinfit_mgse_14',transpose(efield_inertial_spinfit_mgse[*,*,2])
  cdf_varput,cdfid,'efield_inertial_spinfit_mgse_23',transpose(efield_inertial_spinfit_mgse[*,*,3])
  cdf_varput,cdfid,'efield_inertial_spinfit_mgse_24',transpose(efield_inertial_spinfit_mgse[*,*,4])
  cdf_varput,cdfid,'efield_inertial_spinfit_mgse_34',transpose(efield_inertial_spinfit_mgse[*,*,5])

  cdf_varput,cdfid,'efield_corotation_spinfit_mgse_12',transpose(efield_corotation_spinfit_mgse[*,*,0])
  cdf_varput,cdfid,'efield_corotation_spinfit_mgse_13',transpose(efield_corotation_spinfit_mgse[*,*,1])
  cdf_varput,cdfid,'efield_corotation_spinfit_mgse_14',transpose(efield_corotation_spinfit_mgse[*,*,2])
  cdf_varput,cdfid,'efield_corotation_spinfit_mgse_23',transpose(efield_corotation_spinfit_mgse[*,*,3])
  cdf_varput,cdfid,'efield_corotation_spinfit_mgse_24',transpose(efield_corotation_spinfit_mgse[*,*,4])
  cdf_varput,cdfid,'efield_corotation_spinfit_mgse_34',transpose(efield_corotation_spinfit_mgse[*,*,5])

  cdf_varput,cdfid,'efield_inertial_spinfit_edotb_mgse_12',transpose(efield_inertial_spinfit_edotb_mgse[*,*,0])
  cdf_varput,cdfid,'efield_inertial_spinfit_edotb_mgse_13',transpose(efield_inertial_spinfit_edotb_mgse[*,*,1])
  cdf_varput,cdfid,'efield_inertial_spinfit_edotb_mgse_14',transpose(efield_inertial_spinfit_edotb_mgse[*,*,2])
  cdf_varput,cdfid,'efield_inertial_spinfit_edotb_mgse_23',transpose(efield_inertial_spinfit_edotb_mgse[*,*,3])
  cdf_varput,cdfid,'efield_inertial_spinfit_edotb_mgse_24',transpose(efield_inertial_spinfit_edotb_mgse[*,*,4])
  cdf_varput,cdfid,'efield_inertial_spinfit_edotb_mgse_34',transpose(efield_inertial_spinfit_edotb_mgse[*,*,5])

  cdf_varput,cdfid,'efield_corotation_spinfit_edotb_mgse_12',transpose(efield_corotation_spinfit_edotb_mgse[*,*,0])
  cdf_varput,cdfid,'efield_corotation_spinfit_edotb_mgse_13',transpose(efield_corotation_spinfit_edotb_mgse[*,*,1])
  cdf_varput,cdfid,'efield_corotation_spinfit_edotb_mgse_14',transpose(efield_corotation_spinfit_edotb_mgse[*,*,2])
  cdf_varput,cdfid,'efield_corotation_spinfit_edotb_mgse_23',transpose(efield_corotation_spinfit_edotb_mgse[*,*,3])
  cdf_varput,cdfid,'efield_corotation_spinfit_edotb_mgse_24',transpose(efield_corotation_spinfit_edotb_mgse[*,*,4])
  cdf_varput,cdfid,'efield_corotation_spinfit_edotb_mgse_34',transpose(efield_corotation_spinfit_edotb_mgse[*,*,5])

  cdf_varput,cdfid,'density_12',transpose(density[*,0])
  cdf_varput,cdfid,'density_13',transpose(density[*,1])
  cdf_varput,cdfid,'density_14',transpose(density[*,2])
  cdf_varput,cdfid,'density_23',transpose(density[*,3])
  cdf_varput,cdfid,'density_24',transpose(density[*,4])
  cdf_varput,cdfid,'density_34',transpose(density[*,5])

  cdf_varput,cdfid,'corotation_efield_mgse',transpose(corotation_efield_mgse.y)


;  cdf_varput,cdfid,'VxB_mgse',transpose(vxb.y)
  cdf_varput,cdfid,'mlt',transpose(mlt.y)
  cdf_varput,cdfid,'mlat',transpose(mlat.y)
  cdf_varput,cdfid,'lshell',transpose(lshell.y)
  cdf_varput,cdfid,'position_gse',transpose(pos_gse.y)
  cdf_varput,cdfid,'velocity_gse',transpose(vel_gse.y)
  cdf_varput,cdfid,'spinaxis_gse',transpose(sa.y)
  cdf_varput,cdfid,'orbit_num',orbit_num
  cdf_varput,cdfid,'angle_spinplane_Bo',transpose(angles.y)
  if is_struct(edotb_b2bx_ratio) then cdf_varput,cdfid,'diagBratio',transpose(edotb_b2bx_ratio.y)



  cdf_close, cdfid

  stop

end
