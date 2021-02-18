;Ali: Feb 2021
; $LastChangedBy: ali $
; $LastChangedDate: 2021-02-16 22:57:38 -0800 (Tue, 16 Feb 2021) $
; $LastChangedRevision: 29661 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_swem_events_tplot.pro $

pro spp_swp_swem_events_tplot_labels,limits=lims,data=data
  nlab=n_elements(lims.labels)
  plot,data.x,data.y,_extra=lims
  xyouts,replicate(!x.crange[1],nlab),indgen(nlab),' '+lims.labels
end

pro spp_swp_swem_events_tplot,prefix=prefix

  common spp_swp_swem_events_apdat_com, event_str
  if ~keyword_set(prefix) then prefix='psp_swp_swem_event_log_L1_'
  get_data,prefix+'CODE',eventt,eventcode
  if ~keyword_set(eventt) then return
  ;codeuniq=eventcode[UNIQ(eventcode, SORT(eventcode))]
  if n_elements(event_str) eq 0 then event_str=(strtrim(spp_swp_swem_events_strings(),2)).substring(4,-2)
  eventcode2=eventcode
  labels=event_str
  c=0
  for i=0,n_elements(event_str)-1 do begin
    w=where(eventcode eq i,/null,nw)
    if nw gt 0 then begin
      eventcode2[w]=c
      labels[c]=event_str[i]
      c++
    endif
  endfor
  if c eq 0 then message,'no known code found!'
  w=where(eventcode ge i,/null,nw)
  if nw gt 0 then message,'unknown code!'
  labels=labels[0:c-1]
  ytickinterval=1+c/59 ;idl direct graphics does not handle more than 59 major ytick marks!
  store_data,prefix+'CODE2',eventt,eventcode2,dlim={labels:labels,ytickinterval:ytickinterval,yrange:[-1,c],psym:2,yticklen:1,ygridstyle:1,$
    ystyle:3,yminor:1,panel_size:c/7.,tplot_routine:'spp_swp_swem_events_tplot_labels'}

end