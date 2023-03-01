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
  if isa(t) then begin
    trange = t + range
  endif
  sci = swfo_apdat('stis_sci')
  da = sci.data    ; the dynamic array that contains all the data collected  (it gets bigger with time)
  size= da.size    ;  Current size of the data  (it gets bigger with time)

  hkp = swfo_apdat('stis_hkp2')
  hkp_data   = hkp.data


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



  if isa(samples) then begin

    l1adat = swfo_stis_sci_level_1a(samples)
    
    da = dynamicarray(l1adat,name='swfo_stis_spec')
    store_data,'stis',data = da,tagnames = 'SPEC_??',val_tag='_NRG'
    
    


    if 0 then begin

      store_data,'spec_o1',l1adat.time,transpose(l1adat.spec_o1),transpose(l1adat.nrg_o1)
      store_data,'spec_o2',l1adat.time,transpose(l1adat.spec_o2),transpose(l1adat.nrg_o2)
      store_data,'spec_o3',l1adat.time,transpose(l1adat.spec_o3),transpose(l1adat.nrg_o3)
      store_data,'spec_f1',l1adat.time,transpose(l1adat.spec_f1),transpose(l1adat.nrg_f1)
      store_data,'spec_f2',l1adat.time,transpose(l1adat.spec_f2),transpose(l1adat.nrg_f2)
      store_data,'spec_f3',l1adat.time,transpose(l1adat.spec_f3),transpose(l1adat.nrg_f3)

      w2= where((samples.ptcu_bits and 1) eq 0,/null)         ; non lookup table
      if keyword_set(w2) then begin       ; non lookup table
        counts = total(samples[w2].counts,2)    ;  get the total over slice
        integ_time = total(samples[w2].duration)

        times = samples[w2].time
        hkp_samples = hkp_data.sample(nearest=times,tagname='time')
        cfg_unstable = hkp_samples[0].CMDS_EXECUTED NE HKP_SAMPLES[-1].CMDS_EXECUTED
        if cfg_unstable THEN begin   ; Status is changing
          msg = 'Configuration is changing!'
          dprint,dlevel=3,msg
        endif
      endif




    endif
  endif
  ;  store_data,'mem',systime(1),memory(/cur)/(2.^6),/append
end
