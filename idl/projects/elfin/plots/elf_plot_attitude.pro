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
;         elf> elf_plot_attitude, trange=['2019-07-26', '2019-07-27']
;
; NOTES:
;
;-

pro elf_plot_attitude, trange=trange
 trange=['2020-01-01','2020-02-29']
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
  get_data, 'ela_att_gei', data=ela_att, dlimits=dla
  get_data, 'elb_att_gei', data=elb_att, dlimits=dlb
  dlb.labels=dla.labels
  store_data, 'elb_att_gei', data=elb_att, dlimits=dlb
  options, 'ela_att_gei', title=atitle
  options, 'ela_att_gei', yrange=[-2,2]
  options, 'elb_att_gei', yrange=[-2,2]
  options, 'elb_att_gei', title=btitle
 
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
  options, 'ela_theta', yrange=[-180,180]
  options, 'ela_phi', yrange=[-180,180]
  store_data, 'elb_theta', data={x:elb_att.x, y:thb}, dlimits=dlt
  store_data, 'elb_phi', data={x:elb_att.x, y:phb}, dlimits=dlp
  options, 'elb_theta', yrange=[-180,180]
  options, 'elb_phi', yrange=[-180,180]
  
  ; set up plot parameters
  thm_init
  window, xsize=850, ysize=950

  ; Plot Probe A
  tplot, ['ela_att_gei', $
         'ela_theta',$
         'ela_phi']           
  timebar, atimes, linestyle=2
  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9 
  dir_products = !elf.local_data_dir + 'ela/attplots/
  file_mkdir, dir_products
  gif_file = dir_products+'ela_attitude_plot_'+tdate+'_'+tdate1
  dprint, 'Making gif file '+gif_file+'.gif'
  makegif, gif_file

  ; Plot probe B
  tplot, ['elb_att_gei', $
          'elb_theta', $
          'elb_phi']
  timebar, btimes, linestyle=2
  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9
  dir_products = !elf.local_data_dir + 'elb/attplots/
  file_mkdir, dir_products
  gif_file = dir_products+'elb_attitude_plot_'+tdate+'_'+tdate1
  dprint, 'Making gif file '+gif_file+'.gif'
  makegif, gif_file

end