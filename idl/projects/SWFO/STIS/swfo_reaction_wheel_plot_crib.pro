pro swfo_reaction_wheel_plot_output,tr
  if n_elements(tr) ne 2 then   ctime,tr,/silent

  sigma_name = 'swfo_stis_L1a_NOISE_SIGMA'
  wheels_name = 'swfo_stis_L0b_REACTION_WHEEL_SPEED_RPM'



  sigma = tsample(sigma_name,tr)
  sigma_max = max(sigma,dimen=1)

  wheels = data_cut(wheels_name,tr)


  print

  print,time_string(tr),wheels,sigma_max,format='%s - %s :  %6.0f,%6.0f   %6.0f %6.0f   %6.0f %6.0f    %6.0f %6.0f      %5.2f %5.2f %5.2f %5.2f %5.2f %5.2f  '

end





pro swfo_reaction_wheel_plot_crib ,trange

  sigma_name = 'swfo_stis_L1a_NOISE_SIGMA'
  wheels_name = 'swfo_stis_L0b_REACTION_WHEEL_SPEED_RPM'

  sigma_name = 'swfo_stis_L1a_NOISE_SIGMA'
  wheels_name = 'swfo_stis_L0b_REACTION_WHEEL_SPEED_RPM'

  ;sigma_name  = 'swfo_stis_L0b_IRU_BITS'

  if 0 then begin
    sigma = tsample(sigma_name,trange,times=times)
    wheels = data_cut(wheels_name,times)
  endif
  ; plot,wheels[*,0], sigma[*,0]


  xlim,lim,-4000,6000
  options,lim,charsize=2,ytitle='SIGMA'
  if 0  then begin
    !p.multi = [0,0,4]
    options,lim,xtitle='#1  WHEEL SPEED (RPM)'
    scat_plot,WHEELs_name,SIGMA_name,xdimen=0,ydimen=0,lim=lim,trange=trange
    options,lim,xtitle='#2  WHEEL SPEED (RPM)'
    scat_plot,WHEELs_name,SIGMA_name,xdimen=1,ydimen=0,lim=lim,trange=trange
    options,lim,xtitle='#3  WHEEL SPEED (RPM)'
    scat_plot,WHEELs_name,SIGMA_name,xdimen=2,ydimen=0,lim=lim,trange=trange
    options,lim,xtitle='#4  WHEEL SPEED (RPM)'
    scat_plot,WHEELs_name,SIGMA_name,xdimen=3,ydimen=0,lim=lim,trange=trange
    !p.multi = 0

  endif else begin
    options,lim,xtitle='#1  WHEEL SPEED (RPM)'
    scat_plot,WHEELs_name,SIGMA_name,xdimen=0,ydimen=0,lim=lim,trange=trange,/over ;,color=6

  endelse


end
