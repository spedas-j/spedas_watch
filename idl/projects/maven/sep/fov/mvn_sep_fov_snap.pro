;20180411 Ali
;use mouse curser on a tplot window to choose times for plotting useful sep fov info

pro mvn_sep_fov_snap,resdeg=resdeg,vector=vector

  @mvn_sep_fov_common.pro
  
  if ~keyword_set(mvn_sep_fov) then begin
    dprint,'sep fov data not loaded. Please run mvn_sep_fov first! returning...'
    return
  endif
  dprint,'left click on the tplot window to choose a time for plotting sep fov, right click to exit.'

  pos   =mvn_sep_fov.pos
  pdm   =mvn_sep_fov.pdm
  tal   =mvn_sep_fov.tal
  rad   =mvn_sep_fov.rad
  times =mvn_sep_fov.time

  ones3 =replicate(1.,3)
  nth=360l ;number of points on edge of visible mars by MAVEN
  th=2.*!pi*findgen(nth)/float(nth) ;angle (radians)

  while 1 do begin
    ctime,t,np=1,/silent
    if ~keyword_set(t) then return
    tmin=min(abs(times-t),tminsub,/nan)

    v1=pos[*,tminsub].mar
    s1=pos[*,tminsub].sun
    v2=[0.,v1[2,*],-v1[1,*]]/(ones3#sqrt(total(v1[1:2,*]^2,1))) ;perp to posmar
    s2=[0.,s1[2,*],-s1[1,*]]/(ones3#sqrt(total(s1[1:2,*]^2,1)))
    v3=[v1[1,*]*v2[2,*]-v2[1,*]*v1[2,*],v1[2,*]*v2[0,*]-v2[2,*]*v1[0,*],v1[0,*]*v2[1,*]-v2[0,*]*v1[1,*]]
    s3=[s1[1,*]*s2[2,*]-s2[1,*]*s1[2,*],s1[2,*]*s2[0,*]-s2[2,*]*s1[0,*],s1[0,*]*s2[1,*]-s2[0,*]*s1[1,*]]
    v4=v2#cos(th)+v3#sin(th) ;unit circle perp to posmar
    s4=s2#cos(th)+s3#sin(th) ;unit circle perp to possun
    v5=v4*sqrt(-1.+1./pdm[tminsub].mar^2)+rebin(v1,[3,nth])
    v6=v4*sqrt(-1.+1./pdm[tminsub].ram^2)+rebin(v1,[3,nth])
    suredge=v5/(ones3#sqrt(total(v5^2,1))) ;mars surface edge circle
    occedge=v6/(ones3#sqrt(total(v6^2,1))) ;mars occultation altitude edge circle

    fraction=mvn_sep_fov_mars_shine(mvn_sep_fov0.rmars,rad[tminsub].mar*pos[*,tminsub].mar,pos[*,tminsub].sun,resdeg=resdeg,vector=vector)
;   fraction2=mvn_sep_anc_fov_mars_fraction(times[tminsub],check_objects=['MAVEN_SC_BUS']) ;Rob's routine (slow)
    mvn_sep_fov_plot,tminsub,suredge=suredge,occedge=occedge,sunedge=s4,fraction=fraction
  endwhile

end