;Ali: June 2020
;spp_swp_wrp_stat,apid=apid
;for wrapper apids, shows stats for their content_apid.
;for the rest of the apids, shows which wrapper apids they are routed to.
;typically run after loading SSR or PTP files (spp_ssr_file_read or spp_ptp_file_read)
;can also show stats for swem_wrp L1 cdf files using keywords 'load' and 'type'
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-06-16 08:55:23 -0700 (Tue, 16 Jun 2020) $
; $LastChangedRevision: 28779 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/spp_swp_wrp_stat.pro $
;-

pro spp_swp_wrp_stat,type=type,load=load,apid=apid,capid=capid0,noheader=noheader

  if ~keyword_set(type) then type='wrp_P4'
  if keyword_set(load) then spp_swp_load,type=type,spx='swem'
  get_data,'psp_swp_swem_'+type+'_L1_CONTENT_APID',t,capid
  get_data,'psp_swp_swem_'+type+'_L1_PKT_SIZE',t,ps
  if keyword_set(apid) then begin
    if ~keyword_set(capid0) then print,'Stats for: ',(spp_apdat(apid)).name
    apdat=(spp_apdat(apid)).array
    str_element,apdat,'content_apid',success=success
    if ~success then begin
      str_element,apdat,'time',success=success
      if ~success then return
      for wapid='348'x,'350'x do spp_swp_wrp_stat,apid=wapid,capid=apid,noheader=wapid ne '348'x
      return
    endif
    capid=apdat.content_apid
    ps=apdat.pkt_size
  endif
  if ~keyword_set(capid) then return ;for the get_data method to not fail
  if ~keyword_set(noheader) then print,'Name','APID decmial','hex','N_packets','Bytes','average','stdev','db/b',format='(a-14,a8,a8,a12,a12,a12,a12,a12)'
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
  for iw=0,nw-1 do print,(spp_apdat(xbins[w[iw]])).name,xbins[w[iw]],xbins[w[iw]],h[w[iw]],tot[w[iw]],av[w[iw]],stdev[w[iw]],stdev[w[iw]]/av[w[iw]],format='(a-14,i8,Z8,i12,i12,f12.3,f12.3,f12.2)'
  ;print,transpose([[xbins[w]],[xbins[w]],[h[w]],[tot[w]],[av[w]],[stdev[w]]]),format='(i,Z,i,i,f,f)'
end