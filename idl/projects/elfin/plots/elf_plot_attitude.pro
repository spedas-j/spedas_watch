pro elf_plot_attitude, tdate=tdate, dur=dur

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  tdate='2020-01-01'
  if undefined(dur) then dur=90
  if undefined(tdate) then begin
    dprint, 'You must enter a date (e.g. 2020-02-24/03:45:00)'
    return
  endif else begin
    tdate1=strmid(time_string(time_double(tdate)+dur*86400.),0,10)
    title='ELFIN Attitude, '+tdate+' to ' + tdate1
;    tdate=time_double(tdate)
    timespan, tdate, dur
  endelse
  
  elf_load_state, probe='a', trange=trange
  elf_load_state, probe='b', trange=trange
  get_data, 'ela_pos_gei', data=ela_pos, dlimits=dlap
  get_data, 'elb_pos_gei', data=elb_pos, dlimits=dlbp
  
  get_data, 'ela_att_gei', data=ela_att, dlimits=dla
  get_data, 'elb_att_gei', data=elb_att, dlimits=dlb
  dlb.labels=dla.labels
  store_data, 'elb_att_gei', data=elb_att, dlimits=dlb
  options, 'ela_att_gei', title=title
  options, 'ela_att_gei', yrange=[-2,2]
  options, 'elb_att_gei', yrange=[-2,2]
    
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

;  store_data, 'ela_theta_phi', data='ela_theta ela_phi'
;  store_data, 'elb_theta_phi', data='elb_theta elb_phi'
;  options, 'ela_theta_phi', yrange=[-180,180]
;  options, 'elb_theta_phi', yrange=[-180,180]
  
  ; set up plot parameters
  thm_init
  window, xsize=850, ysize=950

  tplot, ['ela_att_gei', $
          'ela_theta', $
          'ela_phi', $
          'elb_att_gei', $
          'elb_theta', $
          'elb_phi']

  xyouts,  .75, .005, 'Created: '+systime(),/normal,charsize=.9

  dir_products = !elf.local_data_dir + 'attplots/
  file_mkdir, dir_products

  gif_file = dir_products+'elf_attitude_plot_'+tdate+'_'+tdate1
  dprint, 'Making gif file '+gif_file+'.gif'
  makegif, gif_file
      
end