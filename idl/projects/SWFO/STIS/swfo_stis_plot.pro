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


pro  swfo_stis_oplot_err,x,y,dx=dx,dy=dy,color=color,psym=psym
  if isa(psym) then oplot,color=color,psym=psym,x,y
  for i= 0, n_elements(x)-1 do begin
    if isa(dx)  then oplot,x[i]+[-dx[i],dx[i]],[y[i],y[i]],color=color
    if isa(dy)  then oplot,[x[i],x[i]]  , y[i]+ [-dy[i],dy[i]], color=color
    
  endfor
end





pro  swfo_stis_plot,var,t,param=param,trange=trange,nsamples=nsamples,lim=lim    ; This is very simple sample routine to demonstrate how to plot recently collecte spectra

  range = struct_value(param,'range',default=[-.5,.5]*30)
  lim   = struct_value(param,'lim',default=lim)
  xval  = struct_value(param,'xval',default= 'NRG')
  wind  = struct_value(param,'window',default=1)
  nsamples  = struct_value(param,'nsamples',default=5)
  units = struct_value(param,'units',default='Eflux')
  read_object = struct_value(param,'read_object')
  
  
  
  if isa(read_object,'socket_reader') then begin
    trec = systime(1)
    if trec gt read_object.getattr('time_received') +10 then begin
      dprint,dlevel = 2, "Forced timed socket read. Don't forget to exit ctime!"
      read_object.timed_event
    endif
  endif
  
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
    ;if ~keyword_set(nsamples) then nsamples = 20
    index = [size-nsamples:size-1]    ; get indices of last N samples
    samples=da.slice(index)           ; extract the last N samples
    ;hkp_samples= hkp.data.slice(/last)
  endelse

  if ~keyword_set(lim) then begin
    xlim,lim,5,20000.,1
    ylim,lim,.0001,1e4,1
    options,lim,units=units,ytitle=units,xtitle='Energy (keV)'
  endif
  
  ymin = min( struct_value(lim,'yrange',default=0.))
  
  names='SPEC_' + ['O1','O2','O3','F1','F2','F3']
  format = {name:'',color:0,linestye:0,psym:-4,linethick:2,geomfactor:1.}
  channels = replicate(format,n_elements(names))
  channels.name = names
  channels.color = [2,4,6,1,3,0]

  old_window = !d.window
  if isa(samples) then begin
    wi,wind
   
    l1a = swfo_stis_sci_level_1a(samples)
    ;h= [l1a.hash,0]   ; get the uniq segments
    ;up =   uniq(h)       
    ;u0= [0,up]
    
    h = l1a.hash
    h[-1] = 0    ; ignore the last one
    dh = h - shift(h,-1)   ; ignore any spectrum in which the following hkp changes
         
    u = h.uniq()
    
    box,lim
    if 1 then begin
      xv = dgen()
      flux_min = 2.48e2 * xv ^ (-1.6) 
      flux_max = 1.01e7 * xv ^ (-1.6)
      if strupcase(units) eq 'EFLUX' then  scale = xv /1000 else scale = 1
      oplot, xv, flux_min * scale
      oplot, xv, flux_max * scale
    endif
    
    for i=0,n_elements(u)-1 do begin
      w = where(h eq u[i] and dh eq 0,/null,nw)
      if nw eq 0 then continue
      datw=l1a[w]
      dat = average(datw)
      nc = n_elements(channels)
      for c = 0,nc-1 do begin
        ch = channels[c]
        str_element,dat,ch.name,y
        str_element,dat,ch.name+'_err',dy
        str_element,dat,ch.name+'_nrg',x
        str_element,dat,ch.name+'_dnrg',dx
        ;str_element,dat,ch.name+'_adc',x
        if strupcase(units) eq 'EFLUX' then  scale = x /1000 else scale = 1
        y = y * scale
        y = y > ymin/10.
        ;swfo_stis_oplot_err,x,y,color=ch.color,psym=ch.psym
        oplot,x,y ,color=ch.color,psym=ch.psym
      endfor
    endfor
        
  endif
  
  if isa(param,'dictionary') then begin
    if ~param.haskey('lim') then param.lim=dictionary(lim)
    if ~param.haskey('routine_name') then param.routine_name = 'swfo_stis_plot'
    if ~param.haskey('window') then param.window= wind
    if ~param.haskey('range') then param.range = range
  endif



  
  
  ;  store_data,'mem',systime(1),memory(/cur)/(2.^6),/append
end
