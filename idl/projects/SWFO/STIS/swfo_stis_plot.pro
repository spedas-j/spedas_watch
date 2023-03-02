;+
; This routine can be used for interactive plotting.
; Run using:
; ctime,routine_name='swfo_stis_plot',/silent
;
; $LastChangedBy: davin-mac $
; $LastChangedDate: 2023-02-24 16:27:51 -0800 (Fri, 24 Feb 2023) $
; $LastChangedRevision: 31520 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/spdsoft/trunk/projects/SWFO/STIS/swfo_stis_crib.pro $
; $ID: $
;-


; sample plotting procedure





pro  swfo_stis_plot,var,t,param=param,trange=trange,nsamples=nsamples,lim=lim    ; This is very simple sample routine to demonstrate how to plot recently collecte spectra

  range = struct_value(param,'range',default=[-.5,.5]*30)
  lim   = struct_value(param,'lim',default=lim)
  wind  = struct_value(param,'window',default=1)
  if isa(t) then begin
    trange = t + range
  endif
  sci = swfo_apdat('stis_sci')
  da = sci.data    ; the dynamic array that contains all the data collected  (it gets bigger with time)
  size= da.size    ;  Current size of the data  (it gets bigger with time)

 ; hkp = swfo_apdat('stis_hkp2')
 ; hkp_data   = hkp.data


  if keyword_set(trange) then begin
    samples=da.sample(range=trange,tagname='time')
    nsamples = n_elements(samples)
    ;tmid = average(trange)
    ;hkp_samples = hkp_data.sample(range=tmid,nearest=tmid,tagname='time')
  endif else begin
    if ~keyword_set(nsamples) then nsamples = 20
    index = [size-nsamples:size-1]    ; get indices of last N samples
    samples=da.slice(index)           ; extract the last N samples
    ;hkp_samples= hkp.data.slice(/last)
  endelse

  if ~keyword_set(lim) then begin
    xlim,lim,5,10000,1
    ylim,lim,.00001,1e5,1
  endif
  
  ymin = min( struct_value(lim,'yrange',default=0.))
  
  names='SPEC_' + ['O1','O2','O3','F1','F2','F3']
  format = {name:'',color:0,linestye:0,psym:-4,linethick:2,geomfactor:1.}
  channels = replicate(format,n_elements(names))
  channels.name = names
  channels.color = [2,4,6,1,3,0]

  if isa(samples) then begin
    wi,wind
   
    l1a = swfo_stis_sci_level_1a(samples)
    h= [l1a.hash,0]   ; get the uniq segments
    up =   uniq(u)       
    u0= [0,up]
    u = h.uniq(/no_sort)
    box,lim
    for i=0,n_elements(u)-1 do begin
      w = where(l1a.hash eq u[i],/null,nw)
      datw=l1a[w]
      dat = average(datw)
      nc = n_elements(channels)
      for c = 0,nc-1 do begin
        ch = channels[c]
        str_element,dat,ch.name,y
        str_element,dat,ch.name+'_nrg',x
        oplot,x,y > ymin/10.,color=ch.color,psym=ch.psym
      endfor
    endfor
        
  endif
  ;  store_data,'mem',systime(1),memory(/cur)/(2.^6),/append
end
