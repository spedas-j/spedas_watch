;+
; Ali 20190601
; $LastChangedBy: ali $
; $LastChangedDate: 2019-06-20 18:24:51 -0700 (Thu, 20 Jun 2019) $
; $LastChangedRevision: 27362 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_snap.pro $
;-

pro spp_swp_spi_snap,level=level,types=types,trange=trange,load=load,all=all,maxcalc=maxcalc,nmaxcalc=nmaxcalc,rate=rate,accum=accum,snap=snap,spectra=spectra,mode=mode

  if ~keyword_set(types) then types=['sf00','sf01','sf10','sf11','sf20','sf21','sf22','sf23']
  if keyword_set(all) then begin
    types=[]
    foreach type0,['s','a'] do foreach type1,['f','t'] do foreach type2,['0','1','2'] do foreach type3,['0','1','2','3'] do types=[types,type0+type1+type2+type3]
  endif
  if ~keyword_set(level) then level='L1'

  if level eq 'L1' then begin
    dir='spi/'+level+'/YYYY/MM/spi_TYP/'
    fileformat=dir+'spp_swp_spi_TYP_'+level+'*_YYYYMMDD_v??.cdf'
    fileprefix='psp/data/sci/sweap/'
    datdimen0=[8,32,8];sf0x: DxExA: deflection(theta),energy,anode(phi)
    datdimen1=[8,32]  ;sf1x: DxE: deflection,energy
    datdimen2=[32,16] ;sf2x: ExM: energy,mass
    tr=timerange(trange)

    while 1 do begin

      if keyword_set(snap) then begin
        ctime,t,np=1,/silent
        if ~keyword_set(t) then return

        windowname='spp_swp_spi_snap'
        p=getwindows(windowname)
        if keyword_set(p) then p.setcurrent else p=window(name=windowname,dimensions=[800,800])
        p.erase
        axis_style=2
        min=0
        max=3
      endif

      foreach type,types do begin

        prefix='psp_swp_spi_'+type+'_'+level+'_' ;tplot_prefix
        if keyword_set(load) then begin
          filetype=str_sub(fileformat,'TYP',type)
          files=spp_file_retrieve(filetype,trange=tr,/daily_names,/valid_only,prefix=fileprefix,verbose=verbose)
          vardata = !null
          novardata = !null
          loadcdfstr,filenames=files,vardata,novardata
          obj=spp_data_product_hash('spi_'+type,vardata)
        endif else vardata=(spp_data_product_hash('spi_'+type)).data

        if ~keyword_set(vardata) then continue

        data=vardata.data
        times=vardata.time
        totaccum=vardata.tot_accum_period
        dim=size(/dimen,data)
        nt=dim[1]
        if keyword_set(accum) then store_data,prefix+'tot_accum_period',times,totaccum,dlim={ylog:1,ystyle:3}
        if keyword_set(maxcalc) then begin
          maxcounts=max(data,dim=1)
          store_data,prefix+'maxcounts',times,maxcounts,dlim={ylog:1,yrange:[1,1e5],ystyle:3,constant:[1,2.^16]}
        endif
        if keyword_set(nmaxcalc) then begin
          maxcounts[where(maxcounts eq 0,/null)]=-1
          nmax=total(transpose(data) eq rebin(maxcounts,nt,dim[0]),2)
          store_data,prefix+'maxbins',times,nmax,dlim={ylog:1,ystyle:3}
        endif
        if keyword_set(mode) then begin
          mode2=vardata.mode2
          tmode=mode2 and 0xf
          emode=(mode2 and 0xf0)/16
          pmode=(mode2 and 0xf00)/16^2
          mmode=(mode2 and 0xf000)/16^3
          store_data,prefix+'mode',times,[[tmode],[emode],[pmode],[mmode]],dlim={ystyle:3,colors:'rbgk',labels:['t','e','p','m'],labflag:-1}
        endif
        if keyword_set(rate) then begin
          data/=transpose(rebin(totaccum,[nt,dim[0]]))
          countrate='Rate'
          min=-2
          max=2
        endif else countrate='Counts'
        prefix=prefix+countrate+'_'

        if keyword_set(snap) then begin
          tmin=min(abs(times-t),tminsub,/nan)
          data=data[*,tminsub]
          nt=1
        endif

        mbin=where(type.charat(3) eq ['0','1','2','3'])
        case type.charat(2) of
          '0':datdimen=datdimen0
          '1':datdimen=datdimen1
          '2':datdimen=datdimen2
        endcase
        data=reform(reform(data,[datdimen,nt],/overwrite))

        case type.charat(2) of
          '0':begin
            if keyword_set(snap) then begin
              data_theta=total(data,1)
              data_energy=total(data,2)
              data_phi=total(data,3,/nan)
              p=image(transpose(alog10(data_theta)),-.5+findgen(8),.5+findgen(32),rgb=colortable(33),min=min,max=max,axis_style=axis_style,$
                title=type,xtitle='Anode #',ytitle='Energy bin',xrange=[-1,8],yrange=[33,0],/current,layout=[5,2,6-5*mbin])
              p=image(alog10(data_phi),.5+findgen(8),.5+findgen(32),rgb=colortable(33),min=min,max=max,axis_style=axis_style,$
                title=type,xtitle='Deflection bin',ytitle='Energy bin',xrange=[0,9],yrange=[33,0],/current,layout=[5,2,7-5*mbin])
              p=image(transpose(alog10(data_energy)),.5+findgen(8),-.5+findgen(8),rgb=colortable(33),min=min,max=max,axis_style=axis_style,$
                ytitle='Deflection bin',xtitle='Anode #',yrange=[-1,8],xrange=[0,8],/current,layout=[5,6,9-5*mbin])
              p=text(/relative,target=p,1.1,0,[type,time_string(times[tminsub],tformat='YYYY-MM-DD'),time_string(times[tminsub],tformat='hh:mm:ss.fff'),'accum='+strtrim(totaccum[tminsub],2)])
            endif
            if keyword_set(spectra) then begin
              data_vs_theta=total(total(data,2),2,/nan)
              data_vs_energy=total(total(data,1),2,/nan)
              data_vs_phi=total(total(data,1),1)
              store_data,prefix+'deflection',times,transpose(data_vs_theta),dlim={zlog:1,spec:1,ystyle:3}
              store_data,prefix+'energy',times,transpose(data_vs_energy),dlim={zlog:1,spec:1,yrange:[32,0],ystyle:3}
              store_data,prefix+'anode',times,transpose(data_vs_phi),dlim={zlog:1,spec:1,yrange:[7,0],ystyle:3}
            endif
          end
          '1':begin
            if keyword_set(snap) then begin
              p=image(alog10(data),.5+findgen(8),.5+findgen(32),rgb=colortable(33),min=min,max=max,axis_style=axis_style,$
                title='',xtitle='Deflection bin',ytitle='Energy bin',xrange=[0,9],yrange=[33,0],/current,layout=[5,2,8-5*mbin])
              p=text(/relative,target=p,0,0,[type,time_string(times[tminsub],tformat='YYYY-MM-DD'),time_string(times[tminsub],tformat='hh:mm:ss.fff'),'accum='+strtrim(totaccum[tminsub],2)])
            endif
            if keyword_set(spectra) then begin
              data_vs_theta=total(data,2)
              data_vs_energy=total(data,1)
              store_data,prefix+'deflection',times,transpose(data_vs_theta),dlim={zlog:1,spec:1,ystyle:3}
              store_data,prefix+'energy',times,transpose(data_vs_energy),dlim={zlog:1,spec:1,yrange:[32,0],ystyle:3}
            endif
          end
          '2':begin
            if keyword_set(snap) then begin
              p=image(alog10(data),.5+findgen(32),.5+findgen(16),rgb=colortable(33),min=min,max=max,axis_style=axis_style,$
                xtitle='Energy bin',ytitle='Mass bin',xrange=[33,0],yrange=[0,17],/current,layout=[2,6,12-2*mbin])
              p=text(/relative,target=p,-.1,0,[type,time_string(times[tminsub],tformat='YYYY-MM-DD'),time_string(times[tminsub],tformat='hh:mm:ss.fff'),'accum='+strtrim(totaccum[tminsub],2)])
            endif
            if keyword_set(spectra) then begin
              data_vs_energy=total(data,2)
              data_vs_mass=total(data,1)
              store_data,prefix+'energy',times,transpose(data_vs_energy),dlim={zlog:1,spec:1,yrange:[32,0],ystyle:3}
              store_data,prefix+'mass',times,transpose(data_vs_mass),dlim={zlog:1,spec:1,ystyle:3}
            endif
          end
        endcase
      endforeach

      if keyword_set(snap) then begin
        p=colorbar(title='Log10 '+countrate,/orientation,position=[.95,.7,.98,.95])
        ;    p=text(.2,.95,prefix+time_string(times[tminsub]))
      endif else return
    endwhile
  endif

  if level eq 'L2' then begin
    if keyword_set(load) then begin
      spp_swp_spi_load ;loads L3 files and cleates tplot variables
      spp_swp_spi_load,/save,types=types,level=level,/no_load
    endif

    obj=spp_data_product_hash('spi_'+types)
    dat=obj.data

    if ~tag_exist(dat,'EFLUX') then message,'EFLUX not loaded'
    eflux=dat.eflux
    energy=dat.energy
    theta=dat.theta
    phi=dat.phi
    times=dat.time

    dim=size(/dimen,eflux)
    nt=dim[1]
    datdimen=[8,32,8] ;theta,energy,phi
    newdim=[datdimen,nt]

    eflux=reform(eflux,newdim,/overwrite)
    theta=reform(theta,newdim,/overwrite)
    phi=reform(phi,newdim,/overwrite)
    energy=reform(energy,newdim,/overwrite)

    if types eq 'sf00' then minmax=[7,11]
    if types eq 'sf01' then minmax=[6,10]

    axis_style=2

    while 1 do begin
      ctime,t,np=1,/silent
      if ~keyword_set(t) then return
      tmin=min(abs(times-t),tminsub,/nan)

      eflux2=eflux[*,*,*,tminsub]
      theta2=theta[*,*,*,tminsub]
      phi2=phi[*,*,*,tminsub]
      energy2=energy[*,*,*,tminsub]

      eflux_theta=total(eflux2,1) ;sum over theta (deflection angle)
      eflux_energy=total(eflux2,2) ;sum over energy
      eflux_phi=total(eflux2,3,/nan) ;sum over phi (anode)

      theta_vals=mean(mean(theta2,dim=2),dim=2,/nan)
      energy_vals=mean(mean(energy2,dim=1),dim=2,/nan)
      phi_vals=mean(mean(phi2,dim=1),dim=1)

      wphi=where(finite(phi_vals),/null)

      windowname='spp_swp_spi_snap'
      p=getwindows(windowname)
      if keyword_set(p) then p.setcurrent else p=window(name=windowname,dimensions=[500,500])
      p.erase

      p=text(.35,.97,time_string(times[tminsub]))
      p=image(transpose(alog10(eflux_theta[*,wphi])),.5+findgen(7),.5+findgen(32),/current,rgb=colortable(33),min=minmax[0],max=minmax[1],axis_style=axis_style,$
        xtitle='anode #',ytitle='energy bin',xrange=[0,8],yrange=[33,0],position=[.1,.1,.4,.9])
      p=image(alog10(eflux_phi),.5+findgen(8),.5+findgen(32),/current,rgb=colortable(33),min=minmax[0],max=minmax[1],axis_style=axis_style,$
        xtitle='deflection bin',ytitle='energy bin',xrange=[0,9],yrange=[33,0],position=[.4,.1,.7,.9])
      p=image(transpose(alog10(eflux_energy[*,wphi])),0.5+findgen(7),0.5+findgen(8),/current,rgb=colortable(33),min=minmax[0],max=minmax[1],axis_style=axis_style,$
        ytitle='deflection bin',xtitle='anode #',yrange=[0,9],xrange=[0,8],position=[.75,.1,.95,.3])
      p=colorbar(title='Log10 (Eflux)',/orientation,position=[.85,.5,.9,.9])

    endwhile

  endif

end