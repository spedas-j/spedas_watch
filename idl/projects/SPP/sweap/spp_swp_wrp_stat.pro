;Ali: June 2020
;spp_swp_wrp_stat,apid=apid
;if no apid is set, shows all stats
;for wrapper apids, shows stats for their content_apid.
;for the rest of the apids, shows which wrapper apids they are routed to. (does not work for cdf)
;typically run after loading SSR or PTP files (spp_ssr_file_read or spp_ptp_file_read)
;can also show stats for swem_wrp L1 cdf files using keywords 'load' (used once to load cdf files) and 'cdf'
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-06-18 16:14:26 -0700 (Thu, 18 Jun 2020) $
; $LastChangedRevision: 28787 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/spp_swp_wrp_stat.pro $
;-

pro spp_swp_wrp_stat,load=load,cdf=cdf,apid=apid,capid=capid0,noheader=noheader,npackets=npackets,all=all

  spp_swp_apdat_init
  apr=[0,'7ff'x] ;range of all apids: to check for possible bad packets
  if keyword_set(all) then apr=['340'x,'3c0'x] ;range of sweap apids
  wapr=['348'x,'350'x] ;range of wrapper apids
  npackets=replicate(0ul,apr[1]-apr[0]+1)

  if ~keyword_set(apid) then begin
    npackets2=replicate(0ul,[apr[1]-apr[0]+1,wapr[1]-wapr[0]+1])
    names=replicate('',wapr[1]-wapr[0]+1)
    for wapid=wapr[0],wapr[1] do begin
      spp_swp_wrp_stat,load=load,cdf=cdf,apid=wapid,npackets=npackets,all=all
      npackets2[*,wapid-wapr[0]]=npackets
      names[wapid-wapr[0]]=(spp_apdat(wapid)).name
    endfor
    print,format='(146("-"))'
    print,'Number of packets in each wrapper APID:',[wapr[0]:wapr[1]],format='(a,Z9,8Z12)'
    for ap=apr[0],apr[1] do begin
      if (ap eq apr[0]) || (ap eq apr[1]) then print,'Name','APID dec','0xhex',names,format='(a4,a20,10a12)
      if (ap ne apr[1]) && keyword_set(all) || (total(npackets2[ap-apr[0],*]) ne 0) then print,(spp_apdat(ap)).name,ap,ap,npackets2[ap-apr[0],*],format='(a-20,i4,7(" "),"0x",Z3,9(i12))
    endfor
    return
  endif

  if keyword_set(capid0) then apr=[capid0,capid0] else print,'APID:'+(spp_apdat(apid)).name,apid,apid,format='(146("-"),/,a-20,i4,7(" "),"0x",Z3)'

  if keyword_set(cdf) then begin
    type=(spp_apdat(apid)).name
    if keyword_set(load) then spp_swp_load,type=type,spx='swem'
    get_data,'psp_swp_swem_'+type+'_L1_CONTENT_APID',t,capid
    get_data,'psp_swp_swem_'+type+'_L1_PKT_SIZE',t,ps
    if ~keyword_set(capid) then return
  endif else begin
    apdat=(spp_apdat(apid)).array
    if ~keyword_set(apdat) then return
    str_element,apdat,'content_apid',success=success
    if success then begin
      capid=apdat.content_apid
      ps=apdat.pkt_size
    endif
  endelse

  if ~keyword_set(capid) then begin
    for wapid=wapr[0],wapr[1] do spp_swp_wrp_stat,load=load,cdf=cdf,apid=wapid,capid=apid,noheader=wapid ne wapr[0]
    return
  endif

  if ~keyword_set(noheader) then print,'Name','APID dec','0xhex','N_packets','Bytes','average','stdev','db/b',format='(a4,a20,6a12)'
  for ap=apr[0],apr[1] do begin
    w=where(capid eq ap,nw)
    if nw eq 0 then continue
    tot=total(ps[w])
    npackets[ap-apr[0]]=nw
    tot2=total(ps[w]^2)
    stdev=sqrt(tot2/nw-(tot/nw)^2)
    av=tot/nw
    if keyword_set(capid0) then ap2=apid else ap2=ap
    print,(spp_apdat(ap2)).name,ap2,ap2,nw,tot,av,stdev,stdev/av,format='(a-20,i4,7(" "),"0x",Z3,i12,i12,f12.3,f12.3,f12.2)'
  endfor


  if 0 then begin ;old method 1
    h=histogram(capid,locations=xbins,min=capid0,max=capid0)
    w=where(h,nw)
    if nw eq 0 then return
    av=average_hist(float(ps),capid,binsize=1,stdev=stdev)
    tot=av*h
    if keyword_set(capid0) then begin
      xbins=apid
      tot=total(ps[where(capid eq capid0)])
      av=tot/h
    endif
    for iw=0,nw-1 do print,(spp_apdat(xbins[w[iw]])).name,xbins[w[iw]],xbins[w[iw]],h[w[iw]],tot[w[iw]],av[w[iw]],stdev[w[iw]],stdev[w[iw]]/av[w[iw]],format='(a-20,i3,Z12,i12,i12,f12.3,f12.3,f12.2)'
    ;print,transpose([[xbins[w]],[xbins[w]],[h[w]],[tot[w]],[av[w]],[stdev[w]]]),format='(i,Z,i,i,f,f)'
  endif

  if 0 then begin ;old method 2
    h=histogram(capid,locations=xbins,min=apr[0],max=apr[1])
    w=where(h,nw)
    av=average_hist(float(ps),capid,binsize=1,stdev=stdev,range=[-.5+apr[0],apr[1]],xbins=xbinsav)
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