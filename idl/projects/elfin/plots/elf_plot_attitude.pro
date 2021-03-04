;+
; PROCEDURE:
;         elf_plot_attitude
;
; PURPOSE:
;         Create attitude plots (3 panels - att_gei vector, theta, phi) with timebars for maneuvers
;
; KEYWORDS:
;         trange:       time range of interest [starttime, endtime] with the format
;                       ['YYYY-MM-DD','YYYY-MM-DD'] or to specify more or less than a day
;                       ['YYYY-MM-DD/hh:mm:ss','YYYY-MM-DD/hh:mm:ss']
;
; EXAMPLES:
;         elf> elf_plot_attitude, trange=['2019-07-01', '2019-11-01']
;
; NOTES:
;
;-

pro elf_plot_attitude, trange=trange

 ;trange=['2020-01-01','2020-02-29']
  ; Initialize elfin system variables
  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init
  ; verify time range parameter is properly set
  if (~undefined(trange) && n_elements(trange) eq 2) && (time_double(trange[1]) lt time_double(trange[0])) then begin
    dprint, dlevel = 0, 'Error, endtime is before starttime; trange should be: [starttime, endtime]'
    return
  endif
  if ~undefined(trange) && n_elements(trange) eq 2 $
    then tr = timerange(trange) $
  else tr = timerange()
  daily_names = file_dailynames(trange=tr, /unique, times=times)
  dname=daily_names[0]
  dname2=daily_names[n_elements(daily_names)-1]

  ; set up times and titles
  tdate=strmid(time_string(time_double(trange[0])),0,10)
  tdate1=strmid(time_string(time_double(trange[1])),0,10)  
  atitle='ELFIN A Attitude, '+tdate+' to ' + tdate1
  btitle='ELFIN B Attitude, '+tdate+' to ' + tdate1
  
  ; Get position and attitude data
  elf_load_state, probe='a', trange=trange
  elf_load_state, probe='b', trange=trange
  get_data, 'ela_pos_gei', data=ela_pos, dlimits=dlap
  get_data, 'elb_pos_gei', data=elb_pos, dlimits=dlbp 
  get_data, 'ela_vel_gei', data=ela_vel, dlimits=dlav
  get_data, 'elb_vel_gei', data=elb_vel, dlimits=dlbv
  get_data, 'ela_att_gei', data=ela_att, dlimits=dla
  get_data, 'elb_att_gei', data=elb_att, dlimits=dlb
  dlb.labels=dla.labels
  store_data, 'elb_att_gei', data=elb_att, dlimits=dlb
  options, 'ela_att_gei', title=atitle
  options, 'ela_att_gei', yrange=[-2,2]
  options, 'elb_att_gei', yrange=[-2,2]
  options, 'elb_att_gei', title=btitle

  ; get MRM spin period
;  n_days = fix((time_double(trange[1]) - time_double(trange[0]))/86400.)
;  for nd=0,n_days-1 do begin
;    this_time = trange[0] + nd*86400.
;    a_rpm=elf_load_att(probe='a', tdate=this_time)
;    a_sp=60./a_rpm
;    append_array, mrm_spin, a_sp
;    append_array, mrm_time, this_time
;  endfor
;  stop  
;  dlm={ysubtitle:'[deg]', labels:['ela_mrm_spin'], colors:[2]}
;  store_data, 'ela_mrm_spin', data={x:mrm_time, y:mrm_spin}, dlimits=dlm
;  ; REPEAT for B
;  for nd=0,n_days-1 do begin
;    this_time = trange[0] + nd*86400.
;    b_rpm=elf_load_att(probe='b', tdate=this_time)
;    b_sp=60./b_rpm
;    append_array, mrm_spin, b_sp
;    append_array, mrm_time, this_time
;  endfor

;  dlm={ysubtitle:'[deg]', labels:['elb_mrm_spin'], colors:[2]}
;  store_data, 'elb_mrm_spin', data={x:mrm_time, y:mrm_spin}, dlimits=dlm
  
  ;get EPD spin period ('ela_pef_spinper')
  elf_load_epd, probe='a',trange=trange, datatype='pef'
  elf_load_epd, probe='b',trange=trange, datatype='pef'
  dlr={ysubtitle:'[rpm]', labels:['spinper'], colors:[2]}
  get_data, 'ela_pef_spinper', data=d
  store_data, 'ela_pef_spinper', data=d, dlimits=dlr
  get_data, 'elb_pef_spinper', data=d
  store_data, 'elb_pef_spinper', data=d, dlimits=dlr

   ; Get maneuver Times
   ; ELFIN A
   man_file = !elf.local_data_dir + 'ela/attplots/ela_attitude_maneuvers_times.txt'
   openr, lun, man_file, /GET_LUN
   line = ''
   ; Read first line - header info
   readf, lun, line
   ; Read one line at a time, saving the result into array
   while not EOF(lun) do begin 
     readf, lun, line
     append_array, atimes, line
   endwhile
   free_lun, lun

   ; ELFIN B
   man_file = !elf.local_data_dir + 'elb/attplots/elb_attitude_maneuvers_times.txt'
   openr, lun, man_file, /GET_LUN
   line = ''
   ; Read first line - header info
   readf, lun, line
   ; Read one line at a time, saving the result into array
   while not EOF(lun) do begin
     readf, lun, line
     append_array, btimes, line
   endwhile
   free_lun, lun 

  ; Calculate Theta Phi and create tplot var
  cart_to_sphere, ela_att.y[*,0], ela_att.y[*,1], ela_att.y[*,2], rda, tha, pha
  cart_to_sphere, elb_att.y[*,0], elb_att.y[*,1], elb_att.y[*,2], rdb, thb, phb 
  dlt={ysubtitle:'[deg]', labels:['theta'], colors:[2]}
  dlp={ysubtitle:'[deg]', labels:['phi'], colors:[2]}   
  store_data, 'ela_theta', data={x:ela_att.x, y:tha}, dlimits=dlt
  store_data, 'ela_phi', data={x:ela_att.x, y:pha}, dlimits=dlp
  options, 'ela_theta', yrange=[-95,95]
  options, 'ela_theta', ystyle=1
  options, 'ela_phi', yrange=[-185,185]
  options, 'ela_phi', ystyle=1
  store_data, 'elb_theta', data={x:elb_att.x, y:thb}, dlimits=dlt
  store_data, 'elb_phi', data={x:elb_att.x, y:phb}, dlimits=dlp
  options, 'elb_theta', yrange=[-95,95]
  options, 'elb_theta', ystyle=1
  options, 'elb_phi', yrange=[-185,185]
  options, 'elb_phi', ystyle=1
  options, 'ela_att_gei', yrange=[-1.05,1.05]
  options, 'ela_att_gei', ystyle=1
  options, 'elb_att_gei', yrange=[-1.05,1.05]
  options, 'elb_att_gei', ystyle=1
  
  ; set up plot parameters
  window, xsize=850, ysize=950
  thm_init
 
  ; Plot Probe A
  tplot, ['ela_att_gei', $
         'ela_theta',$
         'ela_phi', $
;         'ela_mrm_spin', $
         'ela_pef_spinper']           
  timebar, atimes, linestyle=2
  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9 
  dir_products = !elf.local_data_dir + 'ela/attplots/
  file_mkdir, dir_products
  gif_file = dir_products+'ela_attitude_plot_'+dname+'_'+dname2
  dprint, 'Making gif file '+gif_file+'.gif'
  elf_make_att_gif, gif_file
stop
  ; Plot probe B
  tplot, ['elb_att_gei', $
          'elb_theta', $
          'elb_phi', $
 ;         'elb_mrm_spin', $
          'elb_pef_spinper']
  timebar, btimes, linestyle=2
  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9
  dir_products = !elf.local_data_dir + 'elb/attplots/
  file_mkdir, dir_products
  gif_file = dir_products+'elb_attitude_plot_'+dname+'_'+dname2
  dprint, 'Making gif file '+gif_file+'.gif'
  elf_make_att_gif, gif_file
stop
  ; Plot keplerian elements
  ; set up plot parameters
  ; Convert position vector to keplerian elements
  vec2elem, ela_pos.y[*,0], ela_pos.y[*,1], ela_pos.y[*,2], $
    ela_vel.y[*,0], ela_vel.y[*,1], ela_vel.y[*,2], $
    ela_ecc, ela_ra, ela_inc, ela_aper, ela_ma, ela_sma
  dl_ecc={labels:['ecc'], colors:[2]}
  dl_ra={ysubtitle:['[deg]'],labels:['ra'], colors:[2],yrange:[0,360]}
  dl_inc={ysubtitle:['[deg]'],labels:['inc'], colors:[2],yrange:[92,94]}
  dl_aper={ysubtitle:['[deg]'],labels:['aper'], colors:[2],yrange:[0,360]}
  dl_ma={ysubtitle:['[deg]'],labels:['ma'], colors:[2],yrange:[0,360]}
  dl_alt={ysubtitle:['[km]'],labels:['alt'], colors:[2],yrange:[400,500]}
  store_data, 'ela_ecc', data={x:ela_pos.x,y:[ela_ecc]}, dlimits=dl_ecc
  store_data, 'ela_ra', data={x:ela_pos.x,y:[ela_ra*!radeg]}, dlimits=dl_ra
  store_data, 'ela_inc', data={x:ela_pos.x,y:[ela_inc*!radeg]}, dlimits=dl_inc
  store_data, 'ela_aper', data={x:ela_pos.x,y:[ela_aper*!radeg]}, dlimits=dl_aper
  store_data, 'ela_ma', data={x:ela_pos.x,y:[ela_ma*!radeg]}, dlimits=dl_ma
  store_data, 'ela_alt', data={x:ela_pos.x,y:[ela_sma-6374.]}, dlimits=dl_alt
  options, 'ela_alt', title='ELFIN A, Keplerian Elements'

  vec2elem, elb_pos.y[*,0], elb_pos.y[*,1], elb_pos.y[*,2], $
    elb_vel.y[*,0], elb_vel.y[*,1], elb_vel.y[*,2], $
    elb_ecc, elb_ra, elb_inc, elb_aper, elb_ma, elb_sma
  store_data, 'elb_ecc', data={x:elb_pos.x,y:[elb_ecc]}, dlimits=dl_ecc
  store_data, 'elb_ra', data={x:elb_pos.x,y:[elb_ra*!radeg]}, dlimits=dl_ra
  store_data, 'elb_inc', data={x:elb_pos.x,y:[elb_inc*!radeg]}, dlimits=dl_inc
  store_data, 'elb_aper', data={x:elb_pos.x,y:[elb_aper*!radeg]}, dlimits=dl_aper
  store_data, 'elb_ma', data={x:elb_pos.x,y:[elb_ma*!radeg]}, dlimits=dl_ma
  store_data, 'elb_alt', data={x:elb_pos.x,y:[elb_sma-6374.]}, dlimits=dl_alt
  options, 'elb_alt', title='ELFIN B, Keplerian Elements'

  atitle='ELFIN A Elements, '+tdate+' to ' + tdate1
  btitle='ELFIN B Elements, '+tdate+' to ' + tdate1

  ; Plot Probe A Elements
  window, xsize=850, ysize=950
  tplot, ['ela_alt', $
    'ela_inc', $
    'ela_ecc', $
    'ela_ra', $
    'ela_aper', $
    'ela_ma']
  timebar, atimes, linestyle=2
  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9
  dir_products = !elf.local_data_dir + 'ela/attplots/
  file_mkdir, dir_products
  gif_file = dir_products+'ela_elements_plot_'+dname+'_'+dname2
  dprint, 'Making gif file '+gif_file+'.gif'
  elf_make_att_gif, gif_file
stop
  ; Plot Probe B Elements
  tplot, ['elb_alt', $
    'elb_inc', $
    'elb_ecc', $
    'elb_ra', $
    'elb_aper', $
    'elb_ma']
  timebar, btimes, linestyle=2
  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9
  dir_products = !elf.local_data_dir + 'elb/attplots/
  file_mkdir, dir_products
  gif_file = dir_products+'elb_elements_plot_'+dname+'_'+dname2
  dprint, 'Making gif file '+gif_file+'.gif'
  elf_make_att_gif, gif_file
stop

end