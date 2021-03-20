;Ali: Feb 2021
; $LastChangedBy: ali $
; $LastChangedDate: 2021-03-19 15:22:45 -0700 (Fri, 19 Mar 2021) $
; $LastChangedRevision: 29779 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SWEM/spp_swp_swem_events_tplot.pro $

pro spp_swp_swem_events_bad_blocks
  common spp_swp_swem_events_apdat_com, event_str
  if n_elements(event_str) eq 0 then event_str=(strtrim(spp_swp_swem_events_strings(),2)).substring(4,-2)
  wstring=where(event_str.contains('BLOCK',/fold_case),/null,nstring)
  if ~keyword_set(prefix) then prefix='psp_swp_swem_event_log_L1_'
  get_data,prefix+'CODE',t,code
  get_data,prefix+'ID',t,id
  block=replicate(0b,[0xFFFFFF,nstring])
  for it=0,n_elements(t)-1 do begin
    for is=0,nstring-1 do begin
      if code[it] eq wstring[is] then block[id[it,3]+id[it,2]*0x100+id[it,1]*0x10000+id[it,0]*0x1000000*0,is]+=1
    endfor
  endfor

  stop

end

pro spp_swp_swem_events_tplot_labels,limits=lims,data=data
  nlab=n_elements(lims.labels)
  plot,data.x,data.y,_extra=lims
  xyouts,replicate(!x.crange[1],nlab),indgen(nlab),' '+lims.labels
end

pro spp_swp_swem_events_tplot,prefix=prefix,blocks=blocks,ptp=ptp

  common spp_swp_swem_events_apdat_com, event_str
  if keyword_set(ptp) then prefix='spp_swem_event_log_'
  if ~keyword_set(prefix) then prefix='psp_swp_swem_event_log_L1_'
  get_data,prefix+'CODE',eventt,eventcode
  if ~keyword_set(eventt) then return
  ;codeuniq=eventcode[UNIQ(eventcode, SORT(eventcode))]
  if n_elements(event_str) eq 0 then event_str=(strtrim(spp_swp_swem_events_strings(),2))
  if keyword_set(blocks) then wstring=where(event_str.contains('BLOCK',/fold_case),/null,nstring) else begin
    nstring=n_elements(event_str)
    wstring=indgen(nstring)
  endelse
  event_str2=string(wstring,format='0x%03Z_')+event_str.substring(0,-2)
  eventcode2=eventcode
  eventcode2[*]=-1
  labels=event_str
  c=0
  for i=0,nstring-1 do begin
    w=where(eventcode eq wstring[i],/null,nw)
    if nw gt 0 then begin
      eventcode2[w]=c
      labels[c]=event_str2[wstring[i]]
      c++
    endif
  endfor
  if c eq 0 then message,'no known code found!'
  if ~keyword_set(blocks) then begin
    w=where(eventcode ge nstring,/null,nw)
    if nw gt 0 then message,'unknown code!'
  endif
  labels=labels[0:c-1]
  ytickinterval=1+c/59 ;idl direct graphics does not handle more than 59 major ytick marks!
  store_data,prefix+'CODE2',eventt,eventcode2,dlim={labels:labels,ytickinterval:ytickinterval,yrange:[-1,c],psym:2,yticklen:1,ygridstyle:1,$
    ystyle:3,yminor:1,panel_size:c/7.,tplot_routine:'spp_swp_swem_events_tplot_labels'}

end