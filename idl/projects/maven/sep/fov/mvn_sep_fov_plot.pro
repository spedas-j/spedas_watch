;20180330 Ali
;plots celestial objects w.r.t. 4 sep fov's
;includes useful info such as mars shine, fraction of each fov covered by mars, etc.
;
pro mvn_sep_fov_plot,pos=pos,suredge=suredge,fraction=fraction,time=time

  shcoa=30.
  srefa=15.5 ;ref angle
  scrsa=21.0 ;cross angle
  phi=!dtor*findgen(360) ;azimuth angle
  x=shcoa*cos(phi)
  y=shcoa*sin(phi)
  edges=[[-srefa,-scrsa],[-srefa,scrsa],[srefa,scrsa],[srefa,-scrsa],[-srefa,-scrsa]]

  title=['1F','2F','1R','2R']

  p=getwindows('mvn_sep_fov')
  if keyword_set(p) then p.setcurrent else p=window(name='mvn_sep_fov')
  p.erase
  p=plot([0],/nodat,/aspect_ratio,xrange=[180,-180],yrange=[-90,90],xtickinterval=45.,ytickinterval=45.,xminor=8.,yminor=8.,xtitle='SEP XZ (ref) angle',ytitle='SEP XY (cross) angle',/current)
  p=image(fraction.cossza,fraction.phid,fraction.thed-90.,rgb=colortable(64,/reverse),/o,min=0.,max=1.) ;Mars surface
  p=colorbar(target=p,rgb=colortable(64,/reverse),range=[0,1],title='cos(SZA)',position=[0.2,.1,0.8,.15])

  tags=strlowcase(tag_names(pos))
  tags=[tags,'Mars Surface']
  colors=['orange','deep_sky_blue','r','g','m','b','c','r']
  syms=['o','o','o','*','*','*','*','.']
  npos=n_tags(pos)
  for ipos=-1,npos-1 do begin
    if ipos eq -1 then pdf1=suredge ;Mars edge
    if ipos ge 0  then pdf1=pos.(ipos) ;planets and x-ray sources
    septheta=90.-!radeg*acos(-pdf1[1,*]) ;sep-xy angle (degrees)
    sep1fphi=!radeg*atan(pdf1[2,*],pdf1[0,*]) ;sep1f-xz angle (degrees) [-180,180]
    sepphi=sep1fphi-45. ;to align phi=0 with s/c +Z axis
    wlt180=where(sepphi lt -180.,/null)
    if n_elements(wlt180) gt 0 then sepphi[wlt180]+=360.
    p=plot([sepphi,sepphi],[septheta,septheta],/o,name=tags[ipos],sym_color=colors[ipos],sym=syms[ipos],/sym_filled,' ')
  endfor
  p=legend(/orient)

  for pn=-1,2 do begin  ;SEP 2R,1F,2F,1R
    p=plot(edges+rebin([90.*pn-45.,0.],[2,5]),/o)
    p=text((3.-pn)/5.,.85,'SEP'+title[pn])
    p=text((3.-pn)/5.,.82,strtrim(fraction.mars_surfa[pn],2))
    p=text((3.-pn)/5.,.80,strtrim(fraction.mars_shine[pn],2))
    p=text((3.-pn)/5.,.78,strtrim(fraction.mshine_fov[pn],2))
  endfor
  p=plot(45.*[-3.,-1.,0.,1.,3.],[0.,0.,0.,0.,0.],'+',/o) ;centers of fov
  p=text(.01,.88,time_string(time))
  p=text(.02,.82,'Mars Surface')
  p=text(.02,.80,'Mars Shine')
  p=text(.02,.78,'Shine*FOV')

  ;  septheta= 90.-!radeg*acos(pdf[*,2]) ;sep-xy angle (degrees)
  ;  sep1fphi=!radeg*atan(pdf[*,1],pdf[*,0]) ;sep1f-xz angle (degrees) [-180,180]
  ;  wlt45=where(sep1fphi lt -45.,/null)
  ;  if n_elements(wlt45) gt 0 then sep1fphi[wlt45]+=360. ;[-45,315]
  ;  sepphi=[[sep1fphi],[sep1fphi-90.],[sep1fphi-180.],[sep1fphi-270.]]
  ;  crscaled=bytscl(cr,min=.1,max=3.)

  ;    for isep=0,1 do begin
  ;      for ifov=0,1 do begin
  ;        pn=isep+2*ifov
  ;        p=plot(edges,layout=[2,2,pn+1],title='SEP'+title[pn]+' FOV',xtitle='xz (ref) angle',ytitle='xy (cross) angle',xrange=[-shcoa,shcoa],yrange=[-shcoa,shcoa],/aspect_ratio,/current)
  ;        p=plot(x,y,/o)
  ;        ;      p=scatterplot(/o,reform(sep1fphi,n_elements(sep1fphi)),reform(septheta,n_elements(septheta)),rgb=33,sym='.',magnitude=reform(sdea,n_elements(sdea)))
  ;        wcrf=where(finite(cr[*,ifov,isep]),/null)
  ;        p=scatterplot(/o,sepphi[wcrf,pn],septheta[wcrf],rgb=33,sym='.',magnitude=crscaled[wcrf,ifov,isep])
  ;      endfor
  ;    endfor


end