;20190522 Ali

pro spp_swp_spi_snap,load=load,type=type,level=level

  if ~keyword_set(type) then type='sf00'
  if ~keyword_set(level) then level='L2'
  if keyword_set(load) then begin
    spp_swp_spi_load ;loads L3 files and cleates tplot variables
    spp_swp_spi_load,/save,type=type,level=level,/no_load
  endif

  obj=spp_data_product_hash('spi_'+type)
  dat=obj.data
  
  if ~tag_exist(dat,'EFLUX') then message,'EFLUX not loaded'
  eflux=dat.eflux
  energy=dat.energy
  theta=dat.theta
  phi=dat.phi
  times=dat.time

  dim=size(/dimen,eflux)
  nt=dim[1]
  datdimen=[8,32,8] ;theta,energy,phi
  newdim=[datdimen,nt]

  eflux=reform(eflux,newdim,/overwrite)
  theta=reform(theta,newdim,/overwrite)
  phi=reform(phi,newdim,/overwrite)
  energy=reform(energy,newdim,/overwrite)

  if type eq 'sf00' then minmax=[7,11]
  if type eq 'sf01' then minmax=[6,10]
  
  axis_style=2

  while 1 do begin
    ctime,t,np=1,/silent
    if ~keyword_set(t) then return
    tmin=min(abs(times-t),tminsub,/nan)

    eflux2=eflux[*,*,*,tminsub]
    theta2=theta[*,*,*,tminsub]
    phi2=phi[*,*,*,tminsub]
    energy2=energy[*,*,*,tminsub]

    eflux_theta=total(eflux2,1) ;sum over theta (deflection angle)
    eflux_energy=total(eflux2,2) ;sum over energy
    eflux_phi=total(eflux2,3,/nan) ;sum over phi (anode)

    theta_vals=mean(mean(theta2,dim=2),dim=2,/nan)
    energy_vals=mean(mean(energy2,dim=1),dim=2,/nan)
    phi_vals=mean(mean(phi2,dim=1),dim=1)

    wphi=where(finite(phi_vals),/null)

    windowname='spp_swp_spi_snap'
    p=getwindows(windowname)
    if keyword_set(p) then p.setcurrent else p=window(name=windowname,dimensions=[500,500])
    p.erase

    p=text(.35,.97,time_string(times[tminsub]))
    p=image(transpose(alog10(eflux_theta[*,wphi])),.5+findgen(7),.5+findgen(32),/current,rgb=colortable(33),min=minmax[0],max=minmax[1],axis_style=axis_style,$
      xtitle='anode #',ytitle='energy bin',xrange=[0,8],yrange=[33,0],position=[.1,.1,.4,.9])
    p=image(alog10(eflux_phi),.5+findgen(8),.5+findgen(32),/current,rgb=colortable(33),min=minmax[0],max=minmax[1],axis_style=axis_style,$
      xtitle='deflection bin',ytitle='energy bin',xrange=[0,9],yrange=[33,0],position=[.4,.1,.7,.9])
    p=image(transpose(alog10(eflux_energy[*,wphi])),0.5+findgen(7),0.5+findgen(8),/current,rgb=colortable(33),min=minmax[0],max=minmax[1],axis_style=axis_style,$
      ytitle='deflection bin',xtitle='anode #',yrange=[0,9],xrange=[0,8],position=[.75,.1,.95,.3])
    p=colorbar(title='Log10 (Eflux)',/orientation,position=[.85,.5,.9,.9])

  end

end