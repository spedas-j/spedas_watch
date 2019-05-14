;+
; NAME:
;    ELF_MAP_STATE_T96_INTERVALS
;
; PURPOSE:
;    map ELFIN spacecraft to their magnetic footprints in the north
;
; CATEGORY:
;    None
;
; CALLING SEQUENCE:
;    elf_map_state_t96_intervals,'2018-11-10/00:00:00'
;
; INPUTS:
;    tstart start time for the map
;
; OPTIONAL INPUTS:
;    None
;
; KEYWORD PARAMETERS:
;    gifout   generate a gif image at output
;    noview   do not open window for display
;    move     move file to summary plot directory
;    model    specify Tsyganenko model like 't89' or 't01', default is 't96'
;    quick    plot only every minute to speed up
;    dir_move directory name to move plots to 
;
; OUTPUTS:
;    None
;
; OPTIONAL OUTPUTS:
;    GIF images
;
; COMMON BLOCKS:
;    None
;
; SIDE EFFECTS:
;    Needs subroutines mpause_2 
;
; RESTRICTIONS:
;    None
;
; EXAMPLE:
;    elf_map_state_t96_intervals,'2018-11-10/00:00:00'
;
; MODIFICATION HISTORY:
;    Written by: Harald Frey  some time 2007
;                Version 2.0 August, 25, 2011, fixed:
;     - T96
;
; VERSION:
;   $LastChangedBy:
;   $LastChangedDate:
;   $LastChangedRevision:
;   $URL:
;
;-

pro elf_map_state_t96_intervals, tstart, gifout=gifout, noview=noview,$
  move=move, model=model, quick=quick, dir_move=dir_move, $
  insert_stop=insert_stop

  if (time_double(tstart) lt time_double('2018-09-16')) then begin
    print,'Time before ELFIN launch'
    return
  endif

  ; some setup
  if keyword_set(dir_move) then begin
    dir_products=dir_move
  endif
  if ~keyword_set(quick) then quick=1

  ; annotate constants
  xann=10
  yann=485

  elf_init

;  thm_init,/no_color_setup
  aacgmidl
  loadct,39
  thm_init
  set_plot,'z'
  device,set_resolution=[750,500]
  tvlct,r,g,b,/get

  ; colors and symbols, closest numbers for loadct,39
  symbols=[4, 5]  ;[5,2,1,4,6]
  probes=['a','b'] 
  index=[253,254]  ;,252,253,254]

  ; color=253 will be dark blue for ELFIN A
  ;P4 dark blue  [0,0,255],    57 IDL symbol 4
  r[index[0]]=0   & g[index[0]]=0   & b[index[0]]=255
  ; color=254 will be green for ELFIN B
  ;P5 purple     [0,255,0],   30 IDL symbol 6
  r[index[1]]=255 & g[index[1]]=0   & b[index[1]]=0
  tvlct,r,g,b

  ; time input
  timespan,tstart,1,/day
  tend=time_string(time_double(tstart)+86400.0d0)
  sphere=1
  lim=2
  earth=findgen(361)
  print, 'Time input done'

  ; circle of the field of view of the all-sky imagers
  ; solve the spherical triangle to show the circle with z-radius
  ; formula from Taff, Celestial mechanics
  azi=findgen(361)
  a=6378.d    ; Earth radius in km
  z=120.d     ; altitude of emission in km
  zeta=80.d   ; zenith angle
  theta=(180.d0/!dpi)*asin(a/(a+z)*sin(zeta*!dpi/180.d0)) ; second angle of triangle
  alpha=zeta-theta        ; angle at Earth center

  ; average solar wind conditions
  dst=-10.
  dynp=2.
  bswx=2.
  bswy=-2.
  bswz=-1.
  swv=400.  ; default
  bp = sqrt(bswy^2 + bswz^2)/40.
  hb = (bp^2)/(1.+bp)
  bs = abs(bswz<0)
  th = atan(bswy,bswz)
  g1 = swv*hb*sin(th/2.)^3
  g2 = 0.005 * swv*bs
  if keyword_set(model) then tsyg_mod=model else tsyg_mod='t96'

  ; now loop through spacecraft
  for sc=0,1 do begin

    ; load spacecraft data
    elf_load_state,probe=probes[sc]

    ; prepare arrays for Tsyganenko
    comm="get_data,'el"+probes[sc]+"_pos_gei',data=dats"  ; position in GEI
    res=execute(comm)
    comm="cotrans, 'el"+probes[sc]+"_pos_gei', 'el"+probes[sc]+"_pos_gse', /gei2gse"
    res=execute(comm)
    comm="cotrans, 'el"+probes[sc]+"_pos_gse', 'el"+probes[sc]+"_pos_gsm', /gse2gsm"
    res=execute(comm)
    comm="get_data,'el"+probes[sc]+"_pos_gsm',data=dats"  ; position in GSM
    res=execute(comm)
    
    count=n_elements(dats.x)
    num=n_elements(dats.x)-1
    ;if keyword_set(quick) then begin
    ;  short_arr=lindgen(1441)*60
    ;  ; handle gse data
    ;  comm="get_data,'el"+probes[sc]+"_pos_gse',data=datgse" ; position in GSE
    ;  res=execute(comm)
    ;  new_data={x:datgse.x[short_arr],y:datgse.y[short_arr,*],v:datgse.v}
    ;  comm="store_data,'el"+probes[sc]+"_pos_gse',data=new_data" ; position in GSE
    ;  res=execute(comm)
    ;  ; then gsm
    ;  new_data={x:dats.x[short_arr],y:dats.y[short_arr,*],v:dats.v}
    ;  comm="store_data,'el"+probes[sc]+"_pos_gsm',data=new_data" ; position in GSM
    ;  res=execute(comm)
    ;  comm="get_data,'el"+probes[sc]+"_pos_gsm',data=dats" ; position in GSM
    ;  res=execute(comm)
    ;  count=n_elements(dats.x)
    ;  num=n_elements(dats.x)-1
    ;endif

    ; prepare parameter for input into Tsyganenko models
    case 1 of
      (tsyg_mod eq 't89'): tsyg_parameter=2.0d
      (tsyg_mod eq 't96'): tsyg_parameter=[[replicate(dynp,count)],[replicate(dst,count)],$
        [replicate(bswy,count)],[replicate(bswz,count)],$
        [replicate(0.,count)],[replicate(0.,count)],[replicate(0.,count)],$
        [replicate(0.,count)],[replicate(0.,count)],[replicate(0.,count)]]
      (tsyg_mod eq 't01'): tsyg_parameter=[[replicate(dynp,count)],[replicate(dst,count)],$
        [replicate(bswy,count)],[replicate(bswz,count)],$
        [replicate(g1,count)],[replicate(g2,count)],[replicate(0.,count)],$
        [replicate(0.,count)],[replicate(0.,count)],[replicate(0.,count)]]
      ELSE: begin
        print,'Unknown Tsyganenko model'
        return
      endcase
    endcase
;  
;  goto, skip_calc
    ; mapping with Tsyganenko-96, new way
    comm="ttrace2iono,'el"+probes[sc]+"_pos_gsm',newname='el"+probes[sc]+$
      "_ifoot_geo',external_model=tsyg_mod,par=tsyg_parameter,/km,in_coord='gsm',out_coord='geo'"
    res=execute(comm)
skip_calc:
    comm="get_data,'el"+probes[sc]+"_ifoot_geo',data=d"
    res=execute(comm)
    Case sc of
      0: begin
        lon = !radeg * atan(d.y[*,1],d.y[*,0])
        lat = !radeg * atan(d.y[*,2],sqrt(d.y[*,0]^2+d.y[*,1]^2))
        time_dummy=time_string(d.x)
        ; clean up data that's out of scope
        junk=where(lat lt 45.,count2)
        if (count2 gt 0) then begin
          lat[junk]=!values.f_nan
          lon[junk]=!values.f_nan
        endif
      end
      1: begin
        lon2 = !radeg * atan(d.y[*,1],d.y[*,0])
        lat2 = !radeg * atan(d.y[*,2],sqrt(d.y[*,0]^2+d.y[*,1]^2))
        time_dummy2=time_string(d.x)
        junk=where(lat2 lt 45.,count2)
        if (count2 gt 0) then begin
          lat2[junk]=!values.f_nan
          lon2[junk]=!values.f_nan
        endif
      end
    Endcase

    ; time markers
    if (sc eq 0) then begin
      posa_00={time:time_dummy[0]         ,ft_geo:[lon[0],lat[0]]}
      posa_06={time:time_dummy[count/4l]  ,ft_geo:[lon[count/4l],lat[count/4l]]}
      posa_12={time:time_dummy[count/2l]  ,ft_geo:[lon[count/2l],lat[count/2l]]}
      posa_18={time:time_dummy[count*3l/4],ft_geo:[lon[count*3l/4],lat[count*3l/4]]}
      ;posa_24={time:time_dummy[count-1]   ,ft_geo:[lon[count-1],lat[count-1]]}
    endif
    if (sc eq 1) then begin
      posb_00={time:time_dummy2[0]         ,ft_geo:[lon2[0],lat2[0]]}
      posb_06={time:time_dummy2[count/4l]  ,ft_geo:[lon2[count/4l],lat2[count/4l]]}
      posb_12={time:time_dummy2[count/2l]  ,ft_geo:[lon2[count/2l],lat2[count/2l]]}
      posb_18={time:time_dummy2[count*3l/4],ft_geo:[lon2[count*3l/4],lat2[count*3l/4]]}
      ;posb_24={time:time_dummy2[count-1]   ,ft_geo:[lon2[count-1],lat2[count-1]]}
    endif

    print,'Done '+tsyg_mod+' ',probes[sc]

  endfor  ; end of sc loop

  ; get positions for orbit plots
  get_data,'ela_pos_gse',data=ela_state_pos_gse
  get_data,'elb_pos_gse',data=elb_state_pos_gse

  ; setup for orbits
  ; 1 24 hour plot, 4 6 hr plots, 12 2 hr plots
  hr_st = indgen(25)   ;[0, 6*indgen(4), 2*indgen(12)]
  hr_en = hr_st + 1.5
  
  ; Stings for labels, filenames
  hr_ststr = string(hr_st, format='(i2.2)')
  plot_lbl=strarr(24)
  for m=0,23 do plot_lbl[m] = ' ' + hr_ststr[m] + ':00 to ' + hr_ststr[m+1] + ':30'  ;+'-'+hr_enstr
  plot_lbl[23] = ' ' + hr_ststr[23] + ':00 to ' + hr_ststr[24] + ':00'
  file_lbl = '_'+hr_ststr   ;+hr_enstr

  ;the data has 1 minute time resolution
  if keyword_set(quick) then res=60 else res=1
  min_st = hr_st*3600.    ;*60.  ;*3600.   ;*res
  idx=where(min_st LT 86400., ncnt) 
  min_st = min_st[idx]
  min_en = min_st + 90.*60
  idx=where(min_en GT 86044., ncnt)
  if ncnt GT 0 then min_en[idx]=86399. 
  nplots = n_elements(min_st)

  ;----------------------------------
  ; Start Plots
  ;----------------------------------
  for k=0,nplots-1 do begin

    !p.multi=0
;    !p.background=-1
    if keyword_set(gifout) then begin
      set_plot,'z'
      device,set_resolution=[800,600]
      charsize=1
    endif else begin
      set_plot,'win'   ;'x'
      window,xsize=800,ysize=600
      charsize=1.5
    endelse

    ;   set_plot,'z'
    ;   device,set_resolution=[800,600]
    ;   charsize=1
    

    ; set up map
    title='Final footprints '+strmid(tstart,0,10)+plot_lbl[k]
    ;    title='Final footprints '+tstart+' - '+tend
    map_set,90.,-90.,/stereo,/isotropic,/conti,limit=[45.,-180.,90.,180.],$
      title=title,position=[0.005,0.005,600./800.*0.96,0.96]
    map_grid,latdel=5.,londel=45.

    this_time=time_dummy[min_st[k]:min_en[k]]
    this_lon=lon[min_st[k]:min_en[k]]
    this_lat=lat[min_st[k]:min_en[k]]
    this_lon2=lon2[min_st[k]:min_en[k]]
    this_lat2=lat2[min_st[k]:min_en[k]]

    plots, this_lon, this_lat, psym=2, symsize=.1, color=253   ; thick=3
    plots, this_lon2, this_lat2, psym=2, symsize=.1, color=254    ; thick=3

    ; plot symbols at each hour
    hour=fix(strmid(this_time,11,2))
    dummy=hour-shift(hour,1)
    idx=where(dummy ne 0)

    ;plots,lon,lat,thick=3,color=250
    plots,this_lon[idx],this_lat[idx],psym=5,color=253,symsize=1.
    plots,this_lon2[idx],this_lat2[idx],psym=2,color=254,symsize=1.

    ; annotate
    xyouts,xann,yann+18*4,'ELFIN (A)',/device,charsize=charsize,color=253
    xyouts,xann,yann+18*3,'ELFIN (B)',/device,charsize=charsize,color=254
    case 1 of
      tsyg_mod eq 't89': xyouts,6,6,'Tsyganenko-1989',/device,charsize=1,color=255
      tsyg_mod eq 't96': xyouts,6,6,'Tsyganenko-1996',/device,charsize=1,color=255
      tsyg_mod eq 't01': xyouts,6,6,'Tsyganenko-2001',/device,charsize=1,color=255
    endcase

    ; mark times for A
    year=fix(strmid(tstart,0,4))
    month=fix(strmid(tstart,5,2))
    if (hr_st[k] EQ 0) && (posa_00.ft_geo[1] ge 45.) then xyouts,posa_00.ft_geo[0],posa_00.ft_geo[1],$
      strmid(posa_00.time,11,5),color=253,/data,charsize=charsize+0.5
    if (hr_st[k] LE 6 AND hr_en[k] GE 6) && (posa_06.ft_geo[1] ge 45.) then xyouts,posa_06.ft_geo[0],posa_06.ft_geo[1],$
      strmid(posa_06.time,11,5),color=253,/data,charsize=charsize+0.5
    if (hr_st[k] LE 12 AND hr_en[k] GE 12) && (posa_12.ft_geo[1] ge 45.) then xyouts,posa_12.ft_geo[0],posa_12.ft_geo[1],$
      strmid(posa_12.time,11,5),color=253,/data,charsize=charsize+0.5
    if (hr_st[k] LE 18 AND hr_en[k] GE 18) &&(posa_18.ft_geo[1] ge 45.) then xyouts,posa_18.ft_geo[0],posa_18.ft_geo[1],$
      strmid(posa_18.time,11,5),color=253,/data,charsize=charsize+0.5
;    if (hr_st[k] LE 24 AND hr_en[k] GE 24) && (posa_24.ft_geo[1] ge 45.) then xyouts,posa_24.ft_geo[0],posa_24.ft_geo[1],$
;      strmid(posa_24.time,11,5),color=253,/data,charsize=charsize+0.5

    ; mark times for B
    year=fix(strmid(tstart,0,4))
    month=fix(strmid(tstart,5,2))
    if (hr_st[k] EQ 0) && (posb_00.ft_geo[1] ge 45.) then xyouts,posb_00.ft_geo[0],posb_00.ft_geo[1],$
      strmid(posb_00.time,11,5),color=254,/data,charsize=charsize+0.5
    if (hr_st[k] LE 6 AND hr_en[k] GE 6) && (posb_06.ft_geo[1] ge 45.) then xyouts,posb_06.ft_geo[0],posb_06.ft_geo[1],$
      strmid(posb_06.time,11,5),color=254,/data,charsize=charsize+0.5
    if (hr_st[k] LE 12 AND hr_en[k] GE 12) && (posb_12.ft_geo[1] ge 45.) then xyouts,posb_12.ft_geo[0],posb_12.ft_geo[1],$
      strmid(posb_12.time,11,5),color=254,/data,charsize=charsize+0.5
    if (hr_st[k] LE 18 AND hr_en[k] GE 18) &&(posb_18.ft_geo[1] ge 45.) then xyouts,posb_18.ft_geo[0],posb_18.ft_geo[1],$
      strmid(posb_18.time,11,5),color=254,/data,charsize=charsize+0.5
;    if (hr_st[k] LE 24 AND hr_en[k] GE 24) && (posb_24.ft_geo[1] ge 45.) then xyouts,posb_24.ft_geo[0],posb_24.ft_geo[1],$
;      strmid(posb_24.time,11,5),color=254,/data,charsize=charsize+0.5

    xcenter=median([median(ela_state_pos_gse.y[*,0]),median(elb_state_pos_gse.y[*,0])])/6378.
    ycenter=median([median(ela_state_pos_gse.y[*,1]),median(elb_state_pos_gse.y[*,1])])/6378.
    zcenter=median([median(ela_state_pos_gse.y[*,2]),median(elb_state_pos_gse.y[*,2])])/6378.

    ; GSE X-Z
    plot,findgen(10),xrange=[-2,2],yrange=[-2,2],$
            xstyle=5,ystyle=5,/nodata,/noerase,xtickname=replicate(' ',30),ytickname=replicate(' ',30),$
            position=[600./800.,0.005+0.96*2./3.,0.985,0.96*3./3.],$
            title='GSE orbit'

    for i=0.,1.,0.05 do oplot,i*cos(earth*!dtor),i*sin(earth*!dtor)

    ; plot long axes
    oplot,fltarr(100),findgen(100),line=1
    oplot,fltarr(100),-findgen(100),line=1
    oplot,-findgen(100),fltarr(100),line=1
    oplot,findgen(100),fltarr(100),line=1
    xyouts,-1.95, .05,'-X'
    xyouts,1.75,.05,'X'   
    xyouts,.05,-1.85,'-Z'
    xyouts,.05,1.7,'Z'

    for dd=-30,30,10 do oplot,[dd,dd],[-0.5,0.5]
    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]
    ;plot orbit
    for sc=1,2 do res=execute("oplot,el"+probes[sc-1]+"_state_pos_gse.y[min_st[k]:min_en[k],0]/6378."+$
      ",el"+probes[sc-1]+"_state_pos_gse.y[min_st[k]:min_en[k],2]/6378.,color=252+sc")
    for sc=1,2 do res=execute("plots,el"+probes[sc-1]+"_state_pos_gse.y[0,0]/6378."+$
      ",el"+probes[sc-1]+"_state_pos_gse.y[0,2]/6378.,color=252+sc,psym=symbols[sc-1],symsize=0.5")
    ; plot lines to separate plots 
    plots,[600./800.*0.96,1.],[0.005+0.96*3./3.,0.005+0.96*3./3.]-0.007,/normal
    plots,[600./800.*0.96,1.],[0.005+0.96*2./3.,0.005+0.96*2./3.]-0.005,/normal

    ; GSE X-Y
    plot,findgen(10),xrange=[-2,2],yrange=[-2,2],$
      xstyle=5,ystyle=5,/nodata,/noerase,xtickname=replicate(' ',30),ytickname=replicate(' ',30),$
      position=[600./800.,0.005+0.96*1./3.,0.985,0.96*2./3.]
    for i=0.,1.,0.05 do oplot,i*cos(earth*!dtor),i*sin(earth*!dtor)
    oplot,fltarr(100),findgen(100),line=1
    oplot,fltarr(100),-findgen(100),line=1
    oplot,-findgen(100),fltarr(100),line=1
    oplot,findgen(100),fltarr(100),line=1
    xyouts,-1.95, .05,'-X'
    xyouts,1.75,.05,'X'
    xyouts,.05,-1.85,'-Y'
    xyouts,.05,1.7,'Y'

    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]
;    oplot,xmp,ymp,line=2
    for sc=1,2 do res=execute("oplot,el"+probes[sc-1]+"_state_pos_gse.y[min_st[k]:min_en[k],0]/6378."+$
      ",el"+probes[sc-1]+"_state_pos_gse.y[min_st[k]:min_en[k],1]/6378.,color=252+sc,thick=1.5")
    for sc=1,2 do res=execute("plots,el"+probes[sc-1]+"_state_pos_gse.y[0,0]/6378."+$
      ",el"+probes[sc-1]+"_state_pos_gse.y[0,1]/6378.,color=252+sc,psym=symbols[sc-1],symsize=0.5")
    plots,[600./800.*0.96,1.],[0.005+0.96*1./3.,0.005+0.96*1./3.]-0.0025,/normal

    ; GSE Y-Z
    plot,findgen(10),xrange=[-2,2],yrange=[-2,2],$
      xstyle=5,ystyle=5,/nodata,/noerase,xtickname=replicate(' ',30),ytickname=replicate(' ',30),$
      position=[600./800.,0.005+0.96*0./3.,0.985,0.96*1./3.]
    for i=0.,1.,0.05 do oplot,i*cos(earth*!dtor),i*sin(earth*!dtor)
    oplot,fltarr(100),findgen(100),line=1
    oplot,fltarr(100),-findgen(100),line=1
    oplot,-findgen(100),fltarr(100),line=1
    oplot,findgen(100),fltarr(100),line=1
    xyouts,-1.95, .05,'-Y'
    xyouts,1.75,.05,'Y'
    xyouts,.05,-1.85,'-Z'
    xyouts,.05,1.7,'Z'

    for dd=-30,30,10 do oplot,[dd,dd],[-0.5,0.5]
    for dd=-30,30,10 do oplot,[-0.5,0.5],[dd,dd]
    for sc=1,2 do res=execute("oplot,el"+probes[sc-1]+"_state_pos_gse.y[min_st[k]:min_en[k],1]/6378."+$
      ",el"+probes[sc-1]+"_state_pos_gse.y[min_st[k]:min_en[k],2]/6378.,color=252+sc")
    for sc=1,2 do res=execute("plots,el"+probes[sc-1]+"_state_pos_gse.y[0,1]/6378."+$
      ",el"+probes[sc-1]+"_state_pos_gse.y[0,2]/6378.,color=252+sc,psym=symbols[sc-1],symsize=0.5")
    plots,[600./800.*0.96,1.],[0.005+0.96*0./3.,0.005+0.96*0./3.],/normal

    ; gif-output
    date=strmid(tstart,0,10)
    if keyword_set(gifout) then begin
      image=tvrd()
      device,/close
;      if !d.name EQ 'WIN' then set_plot,'win' else set_plot,'x'
      image[where(image eq 255)]=1
      image[where(image eq 0)]=255
      if not keyword_set(noview) then window,3,xsize=800,ysize=600
      if not keyword_set(noview) then tv,image
      dir_products = !elf.local_data_dir + 'gtrackplots/'+ strmid(date,0,4)+'/'+strmid(date,5,2)+'/' 
      file_mkdir, dir_products 
      filedate=file_dailynames(trange=tr, /unique, times=times)
      if keyword_set(move) then gif_name=dir_products+'/'+'elf_l2_northtrack_'+filedate+file_lbl[k] else $
        gif_name='elf_l2_northtrack_'+filedate+file_lbl[k]
      write_gif,gif_name+'.gif',image,r,g,b
      print,'Output in ',gif_name+'.gif'
    endif

    ;if keyword_set(insert_stop) then stop

  endfor ; end of plotting loop

end
