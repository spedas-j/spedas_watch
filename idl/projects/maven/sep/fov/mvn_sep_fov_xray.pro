;20180413 Ali
;plots sco x-1 x-ray count rates vs. sep fov map

pro mvn_sep_fov_xray_filter,pos,pdm,sep,det,crl,crh,wcrl,wcrh,wmsh
  wcrl=finite(crl[sep,det,*]) ;finite x-ray counts
  wcrh=crh[sep,det,*] lt 1. ;low background
  wmsh=([-1,0,0,1,0,0])[det]*pos[sep*2,*].mar lt cos(acos(pdm.mar)+20.*!dtor) ;no mars shine
end

pro mvn_sep_fov_xray,det=det,sep=sep,occ=occ,spec=spec,sld=sld,xlog=xlog

  @mvn_sep_fov_common.pro
  @mvn_sep_handler_commonblock.pro

  if ~keyword_set(mvn_sep_fov) then begin
    dprint,'sep fov data not loaded. Please run mvn_sep_fov first! returning...'
    return
  endif

  detlab=mvn_sep_fov0.detlab
  pos   =mvn_sep_fov.pos
  pdm   =mvn_sep_fov.pdm
  tal   =mvn_sep_fov.tal
  crh   =mvn_sep_fov.crh
  crl   =mvn_sep_fov.crl
  att   =mvn_sep_fov.att
  times =mvn_sep_fov.time

  if n_elements(sep) eq 0 then sep=0
  if n_elements(det) eq 0 then det=0
  if n_elements(sld) eq 0 then sld=0 ;look direction 0:front 1:rear

  watt=att[sep,*] eq 1. ;open attenuator
  wtal=tal[0,*].sx1 gt 100. ;sco x1 not behind mars
  ;  wsun=pos[0,*].sun
  ;  wcr3=crl[sep,det,*] gt 1.

  if keyword_set(occ) then begin
    hialt=tal[2,*].mar gt 1000.
    wpos=([1.,-1.])[sld]*pos[sep*2,*].sx1 gt .97 ;within 14 degrees of center of fov
    wtime=times gt time_double('16-3-12/1:00') and times lt time_double('16-3-12/2:00')
    wtime=1
    whr=where(hialt and wpos and watt and wtime,/null,nwhr)
    if nwhr eq 0 then message,'no occultation found!'
    ;p=plot(sep2sx1[whr],sep2ao.y[whr,0],'.',/ylog,xtitle='sep2.m1',ytitle='sep2_AO_0')
    p=plot([0],/nodat,xlog=xlog,xrange=[-1,9],yrange=[-100,200],xtitle='SEP'+strtrim(sep+1,2)+' '+detlab[det]+' Count Rate (Hz)',ytitle='Sco X-1 Tangent Altitude (km)')
    p=plot(/o,crl[sep,det,whr],tal[2,whr].sx1,'.')
    crsep2bfbin=average_hist(crl[sep,det,whr],tal[2,whr].sx1,binsize=10.,xbins=taltsx1bin,/nan,stdev=stdev,hist=hist)
    p=errorplot(/o,crsep2bfbin,taltsx1bin,stdev/sqrt(hist),0,errorbar_color='g')
    p=text(0,0,time_string(minmax(times[whr])))
    get_data,'mvn_sep_xray_transmittance',data=modelcrate
    p=plot(1.+5.*modelcrate.y[whr,0],tal[2,whr].sx1,/o,'r')
    p=plot(1.+5.*modelcrate.y[whr,1],tal[2,whr].sx1,/o,'b')
    return
  endif

  if keyword_set(spec) then begin
    map1=mvn_sep_get_bmap(9,sep+1)
    if sep eq 0 then sep1=*(sep1_svy.x) else sep1=*(sep2_svy.x)
    wpos=([1.,-1.])[sld]*pos[sep*2,*].sx1 gt +.97 ;in fov
    wpo0=abs(pos[sep*2,*].sx1) lt .5 ;out of fov: for background calculation
    p=getwindows('mvn_sep_xray_spec')
    if keyword_set(p) then p.setcurrent else p=window(name='mvn_sep_xray_spec')
    p.erase
    p=plot([0],/nodata,/xlog,/ylog,/current,xrange=[1,100],yrange=[.001,10],title='Sco X-1 X-ray Response for SEP'+strtrim(sep+1,2)+' '+(['Front','Rear'])[sld]+' Look Direction',xtitle='Deposited Energy (keV)',ytitle='Count Rate (Hz)')
    ndet=n_elements(detlab)
    for idet=0,ndet-1 do begin
      mvn_sep_fov_xray_filter,pos,pdm,sep,idet,crl,crh,wcrl,wcrh,wmsh
      whr=where(wcrl and wcrh and watt and wtal and wmsh and wpos,/null) ;where good signal
      wh0=where(wcrl and wcrh and watt and wtal and wmsh and wpo0,/null) ;where background
      ind=where(map1.name eq detlab[idet],nen,/null)
      sepspec=mean(sep1[whr].data[ind]/(replicate(1.,nen)#sep1[whr].delta_time),dim=2,/nan) ;in fov count rate
      sepspe0=mean(sep1[wh0].data[ind]/(replicate(1.,nen)#sep1[wh0].delta_time),dim=2,/nan) ;background
      sepspe1=sepspec-sepspe0 ;background subtracted spectra
      sepspe1[where(sepspe1 lt 0.,/null)]=1e-10 ;low counts (to prevent idl plotting routine to mess up negative numbers)
      p=plot(/o,map1[ind].nrg_meas_avg,sepspe1,/stairs,color=mvn_sep_fov0.detcol[idet],name=detlab[idet])
    endfor
    p=legend()
    p=text(0,0,time_string(minmax(times)))
    return
  endif

  mvn_sep_fov_xray_filter,pos,pdm,sep,det,crl,crh,wcrl,wcrh,wmsh
  wher=where(wcrl and wcrh and watt and wtal and wmsh,/null) ;where good signal
  range=[-1.,1.]
  crscaled=bytscl(alog10(reform(crl[sep,det,wher])),min=range[0],max=range[1])
  mvn_sep_fov_plot,pos=pos[*,wher].sx1,cr=crscaled,time=minmax(times)
  p=colorbar(rgb=33,range=range,title='log10[SEP'+strtrim(sep+1,2)+' '+detlab[det]+' Count Rate (Hz)]',position=[0.5,.1,0.9,.15])

end