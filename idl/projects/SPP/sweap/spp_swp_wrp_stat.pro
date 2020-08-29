;Ali: June 2020
;spp_swp_wrp_stat,apid=apid
;if no apid is set, shows all stats
;for wrapper apids, shows stats for their content_apid.
;for the rest of the apids, shows which wrapper apids they are routed to.
;typically run after loading SSR or PTP files (spp_ssr_file_read or spp_ptp_file_read)
;can also show stats for swem_wrp L1 cdf files using keywords 'load' (used once to load cdf files) and 'cdf'
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-08-28 14:56:20 -0700 (Fri, 28 Aug 2020) $
; $LastChangedRevision: 29089 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/spp_swp_wrp_stat.pro $
;-

pro spp_swp_wrp_stat,load=load,cdf=cdf,apid=apid,capid=capid0,noheader=noheader,npackets=npackets,totbytes=totbytes,all=all,comp=comp,group=group,trange=trange

  spp_swp_apdat_init
  apr=[0,'7ff'x] ;range of all apids: to check for possible bad packets
  if keyword_set(all) then apr=['340'x,'3c0'x] ;range of sweap apids
  wapr=['348'x,'34f'x] ;range of wrapper apids
  aprs=orderedhash('spc_all',['351'x,'35f'x],'spa_all',['360'x,'36f'x],'spb_all',['370'x,'37f'x],'spe_all',['360'x,'37f'x],'spi_all',['380'x,'3bf'x],$
    'spa_archive',['360'x,'363'x],'spb_archive',['370'x,'373'x],'spi_archive',['380'x,'397'x],$
    'spa_survey' ,['364'x,'36f'x],'spb_survey' ,['374'x,'37f'x],'spi_survey' ,['398'x,'3bf'x],'TOTAL',apr)
  npackets=replicate(0ull,apr[1]-apr[0]+1)
  totbytes=npackets

  if ~isa(apid) then begin
    npackets2=replicate(0ull,[apr[1]-apr[0]+1,wapr[1]-wapr[0]+1])
    totbytes2=npackets2
    names=replicate('',wapr[1]-wapr[0]+1)
    for wapid=wapr[0],wapr[1] do begin
      spp_swp_wrp_stat,load=load,cdf=cdf,apid=wapid,npackets=npackets,totbytes=totbytes,all=all,comp=comp,group=group,trange=trange
      npackets2[*,wapid-wapr[0]]=npackets
      totbytes2[*,wapid-wapr[0]]=totbytes
      names[wapid-wapr[0]]=(spp_apdat(wapid)).name
    endfor
    format='(a-20,i4,7(" "),"0x",Z03,9i12)
    for itot=0,1 do begin
      headertext=['Number of pkts','Total pkt size']+' in each wrapper APID:'
      print,headertext[itot],[wapr[0]:wapr[1]],'all',format='(156("-"),/,a-36,8Z12,a12)'
      print,'Name','APID dec','0xhex',names,'wrp_all',format='(a4,a20,10a12)
      pkts=itot ? totbytes2:npackets2
      for ap=apr[0],apr[1]-1 do begin
        totpkts=total(pkts[ap-apr[0],*])
        if keyword_set(all) || (totpkts ne 0) then print,(spp_apdat(ap)).name,ap,ap,pkts[ap-apr[0],*],totpkts,format=format
      endfor
      print,headertext[itot],[wapr[0]:wapr[1]],'all',format='(156("-"),/,a-36,8Z12,a12)'
      print,'Name','APID dec','0xhex',names,'wrp_all',format='(a4,a20,10a12)
      foreach apr0,aprs,apr1 do begin
        totpkts=total(pkts[apr0[0]-apr[0]:apr0[1]-apr[0],*],1)
        if keyword_set(all) || (total(totpkts) ne 0) then print,apr1,0,0,totpkts,total(totpkts),format=format
      endforeach
    endfor
    return
  endif

  if (apid lt wapr[0]) || (apid gt wapr[1]) then begin ;apid is not a wrapper apid
    print,(spp_apdat(apid)).name,apid,apid,format='(a-20,i4,7(" "),"0x",Z03)'
    for wapid=wapr[0],wapr[1] do spp_swp_wrp_stat,load=load,cdf=cdf,apid=wapid,capid=apid,comp=comp,group=group,trange=trange,noheader=wapid ne wapr[0]
    return
  endif

  if isa(capid0) then apr=[capid0,capid0] else print,(spp_apdat(apid)).name,apid,apid,format='(156("-"),/,a-20,i4,7(" "),"0x",Z03)'
  if ~keyword_set(noheader) then print,'Name','APID dec','0xhex','N_packets','Total Bytes','Decomp.','ratio','Average','Decomp.','stdev','Decomp.','%db/b','Decomp.',format='(a4,a20,11a12)'

  if keyword_set(cdf) then begin
    type=(spp_apdat(apid)).name
    if ~keyword_set(type) then message,'unknown apid!'
    if keyword_set(load) then spp_swp_load,type=type,spx='swem'
    get_data,'psp_swp_swem_'+type+'_L1_SEQ_GROUP',t,sg
    get_data,'psp_swp_swem_'+type+'_L1_PKT_SIZE',t,ps
    get_data,'psp_swp_swem_'+type+'_L1_CONTENT_TIME_DIFF',t,td
    get_data,'psp_swp_swem_'+type+'_L1_CONTENT_APID',t,ca
    get_data,'psp_swp_swem_'+type+'_L1_CONTENT_DECOMP_SIZE',t,ds
    get_data,'psp_swp_swem_'+type+'_L1_CONTENT_COMPRESSED',t,cc
    if ~keyword_set(ca) then return
  endif else begin
    apdat=(spp_apdat(apid)).array
    if ~keyword_set(apdat) then return
    str_element,apdat,'content_apid',success=success
    if success then begin
      t=apdat.time
      sg=apdat.seq_group
      ps=apdat.pkt_size
      td=apdat.content_time_diff
      ca=apdat.content_apid
      ds=apdat.content_decomp_size
      cc=apdat.content_compressed
    endif
  endelse

  if keyword_set(trange) then begin
    trange=time_double(trange)
    wt=where((t gt trange[0]) and (t lt trange[1]),/null)
    if ~keyword_set(wt) then return
    sg=sg[wt]
    ps=ps[wt]
    ca=ca[wt]
    ds=ds[wt]
    cc=cc[wt]
  endif

  if n_elements(group) ne 0 then begin
    wsg=where(sg eq group,/null)
    if ~keyword_set(wsg) then return
    ps=ps[wsg]
    ca=ca[wsg]
    ds=ds[wsg]
    cc=cc[wsg]
  endif
  if n_elements(comp) ne 0 then begin
    if comp eq 1 then wcc=where(cc,/null) else wcc=where(~cc,/null)
    if ~keyword_set(wcc) then return
    ps=ps[wcc]
    ca=ca[wcc]
    ds=ds[wcc]
  endif else begin
    wncc=where(~cc,/null)
    ds[wncc]=ps[wncc];-12
  endelse
  ps=double(ps)
  ds=double(ds)

  for ap=apr[0],apr[1] do begin
    w=where(ca eq ap,nw)
    if nw eq 0 then continue
    tot=total(ps[w])
    tod=total(ds[w])
    to2=total(ps[w]^2)
    td2=total(ds[w]^2)
    stdev=sqrt(to2/nw-(tot/nw)^2)
    stded=sqrt(td2/nw-(tod/nw)^2)
    av=tot/nw
    ad=tod/nw
    npackets[ap-apr[0]]=nw
    totbytes[ap-apr[0]]=tot
    if keyword_set(capid0) then ap2=apid else ap2=ap
    print,(spp_apdat(ap2)).name,ap2,ap2,nw,tot,tod,tod/tot,av,ad,stdev,stded,100.*stdev/av,100.*stded/ad,format='(a-20,i4,7(" "),"0x",Z03,3i12,7f12.3)'
  endfor


  if 0 then begin ;old method 1
    h=histogram(ca,locations=xbins,min=capid0,max=capid0)
    w=where(h,nw)
    if nw eq 0 then return
    av=average_hist(float(ps),ca,binsize=1,stdev=stdev)
    tot=av*h
    if keyword_set(capid0) then begin
      xbins=apid
      tot=total(ps[where(ca eq capid0)])
      av=tot/h
    endif
    for iw=0,nw-1 do print,(spp_apdat(xbins[w[iw]])).name,xbins[w[iw]],xbins[w[iw]],h[w[iw]],tot[w[iw]],av[w[iw]],stdev[w[iw]],stdev[w[iw]]/av[w[iw]],format='(a-20,i3,Z12,i12,i12,f12.3,f12.3,f12.2)'
    ;print,transpose([[xbins[w]],[xbins[w]],[h[w]],[tot[w]],[av[w]],[stdev[w]]]),format='(i,Z,i,i,f,f)'
  endif

  if 0 then begin ;old method 2
    h=histogram(ca,locations=xbins,min=apr[0],max=apr[1])
    w=where(h,nw)
    av=average_hist(float(ps),ca,binsize=1,stdev=stdev,range=[-.5+apr[0],apr[1]],xbins=xbinsav)
    tot=av*h
    if keyword_set(capid0) then begin
      w=capid0-apr[0]
      if h[w] eq 0 then return
      nw=1
      xbins[w]=apid
    endif
    for iw=0,nw-1 do print,(spp_apdat(xbins[w[iw]])).name,xbins[w[iw]],xbins[w[iw]],h[w[iw]],tot[w[iw]],av[w[iw]],stdev[w[iw]],stdev[w[iw]]/av[w[iw]],format='(a-20,i3,Z12,i12,i12,f12.3,f12.3,f12.2)'
  endif
end