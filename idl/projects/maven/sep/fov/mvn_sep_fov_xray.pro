;20180413 Ali
;plots sco x-1 x-ray count rates vs. sep fov map

pro mvn_sep_fov_xray,det=det,sep=sep,occ=occ

  @mvn_sep_fov_common.pro

  if ~keyword_set(mvn_sep_fov) then begin
    dprint,'sep fov data not loaded. Please run mvn_sep_fov first! returning...'
    return
  endif

  pos   =mvn_sep_fov.pos
  tal   =mvn_sep_fov.tal
  crh   =mvn_sep_fov.crh
  crl   =mvn_sep_fov.crl
  att   =mvn_sep_fov.att
  times =mvn_sep_fov.time

  if ~keyword_set(sep) then sep=0
  if ~keyword_set(det) then det=2

  if keyword_set(occ) then begin
    hialt=tal.mar gt 1000.
    wpos=pos[0,*].sx1 gt .9
;    new=times gt time_double('16-3-12') lt time_double('16-3-14')
    
    whr=where(hialt and wpos)
    ;whr=lindgen(nt)

    ;p=plot(sep2sx1[whr],sep2ao.y[whr,0],'.',/ylog,xtitle='sep2.m1',ytitle='sep2_AO_0')
    crsep2bfbin=average_hist(crl[sep,det,whr],tal[whr].sx1,binsize=10.,xbins=taltsx1bin,/nan)
    p=plot(crl[sep,det,whr],tal[whr].sx1,xrange=[.1,10],yrange=[-100,200],'.',xtitle='SEP'+strtrim(sep+1,2)+' '+detlab[det]+' Count Rate (Hz)',ytitle='Sco X-1 Tangent Altitude (km)')
    p=plot(crsep2bfbin,taltsx1bin,/o)
    p=text(0,0,time_string(minmax(times)))
    return
  endif


  wcrl=finite(crl[sep,det,*]) ;finite x-ray counts
  wcrh=crh[sep,det,*] lt 1. ;low background
  watt=att[sep,*] eq 1. ;open attenuator
  wtal=tal.sx1 gt 200. ;sco x1 not behind mars
  wher=where(wcrl and wcrh and watt and wtal,/null) ;where good signal 
  wpos=pos[0,*].sx1 gt .9
  wcr3=crl[sep,det,*] gt 1.

  range=[-1.,1.]
  crscaled=bytscl(alog10(reform(crl[sep,det,wher])),min=range[0],max=range[1])
  mvn_sep_fov_plot,pos=pos[*,wher].sx1,cr=crscaled,time=minmax(times)
  p=colorbar(rgb=33,range=range,title='log10[SEP'+strtrim(sep+1,2)+' '+detlab[det]+' Count Rate (Hz)]',position=[0.5,.1,0.9,.15])

end