;+
; PROCEDURE:
;       mvn_swe_lpw_scpot
; PURPOSE:
;
;       Empirically derives spacecraft potentials using SWEA/STA and LPW.
;       Inflection points in LPW I-V curves are tuned to positive and negative
;       spacecraft potentials estimated from SWEA/STA energy spectra
;       (mvn_swe_sc_pot, mvn_swe_sc_negpot, mvn_sta_scpot_load).
;
; CALLING SEQUENCE:
;       timespan,'16-01-01',14   ;- make sure to set a long time range
;       mvn_swe_lpw_scpot
; OUTPUT TPLOT VARIABLES:
;       mvn_swe_lpw_scpot
; KEYWORDS:
;       trange: time range
;       norbwin: odd number of orbits used for Vswe-Vinfl fitting (Def. 37)
;       minndata: minimum number of data points for Vswe-Vinfl fitting
;                 (Def. 1e4)
;       maxgap: maximum time gap allowed for interpolation (Def. 257)
;       plot: if set, plot the time series and fitting
;       vrinfl: voltage range for searching the inflection point
;               (Def. [-15,18])
;       ntsmo: time smooth width (Def. 3)
; NOTES:
;       1) The data quality is not good before 2015-01-24.
;       2) Potential values between 0 and +3 V are interpolated
;          - they cannot be verified by SWEA measurements
;       3) Does not work in shadow. All data in wake are masked.
; CREATED BY:
;       Yuki Harada on 2016-02-29
;       Major update on 2017-07-24 - incl. negative pot
;       Major update on 2026-11-26 - finalize this data product after the end of mission
;                                    improve V_infl determination procedure
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2026-11-27 02:56:34 -0800 (Fri, 27 Nov 2026) $
; $LastChangedRevision: 35071 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_lpw_scpot.pro $
;-

pro mvn_swe_lpw_scpot, trange=trange, norbwin=norbwin, minndata=minndata, maxgap=maxgap, plot=plot, noload=noload, vrinfl=vrinfl, ntsmo=ntsmo, icur_thld=icur_thld, figdir=figdir, scatdir=scatdir, alt_swepos=alt_swepos, alt_sweneg=alt_sweneg, alt_sta=alt_sta


if size(figdir,/type) eq 0 then begin
   figdir = '/disks/maja/home/haraday/fig/maven/mvn_swe_lpw_scpot/'
   if ~file_test(figdir,/directory) then figdir = 0
endif


;;; set default parameters
if ~keyword_set(norbwin) then norbwin = 37 ;- odd number
if ~keyword_set(minndata) then minNdata = 1e4
if ~keyword_set(maxgap) then maxgap = 257.
if ~keyword_set(vrinfl) then vrinfl = [-15,18] ;- inflection point V range
if ~keyword_set(ntsmo) then ntsmo = 3          ;- odd number, smooth IV curves in time
if ~keyword_set(icur_thld) then icur_thld = -0.5 ;- 10^icur_thld drop from median -> invalid
if ~keyword_set(alt_swepos) then alt_swepos = [400,1e4] ;- alt range for SWE+
if ~keyword_set(alt_sta) then alt_sta = [170,400]       ;- alt range for STA
if ~keyword_set(alt_sweneg) then alt_sweneg = [0,170]   ;- alt range for SWE-

tr = timerange(trange)

orbdata = mvn_orbit_num()
worb = where( orbdata.peri_time gt tr[0] $
              and orbdata.peri_time+4.6*3600d lt tr[1] , nworb )
orbnums = orbdata[worb].num
tperi0 = orbdata[worb].peri_time
tperi1 = orbdata[worb+1].peri_time

if nworb lt norbwin then begin
   dprint,'Time range is too short: minimum Norb = '+string(norbwin,f='(i0)')
   return
endif

;;; L2 lpiv usable after 2015-12-09/07:30, set l2iv=-1 to force to use L0
time_l2ok = time_double('2015-12-09/07:30')
if size(l2iv,/type) eq 0 then if tr[0] gt time_l2ok then l2iv = 1 else l2iv = 0


;;; load data
if ~keyword_set(noload) then begin
   maven_orbit_tplot, /loadonly

   if l2iv gt 0 then begin
   ;;; load LPW L2 I-V data
      mvn_lpw_load_l2,'lpiv',/notplot
   endif else begin
      ;;; load LPW L0 data
      atrtname = 'mvn_lpw_atr_swp'
      tf = ['mvn_lpw_swp1_IV','mvn_lpw_swp1_mode',atrtname] ;- wanted tplot variables
      f = mvn_pfp_file_retrieve(/l0,trange=tr)
      if getenv('ROOT_DATA_DIR') eq '' then setenv,'ROOT_DATA_DIR='+root_data_dir() ;- for LPW loader
      for ifile=0,n_elements(f)-1 do begin
         l0pref = 'mvn_pfp_all_l0_'
         idx = strpos(f[ifile],l0pref)
         today = time_double(strmid(f[ifile],idx+strlen(l0pref),8),tf='YYYYMMDD')
         YYYY_MM_DD = time_string(today,tf='YYYY-MM-DD')
         packet = 'nohsbm'
         s = execute( 'mvn_lpw_load, YYYY_MM_DD,/notatlasp,/noserver,/leavespice,packet=packet' )
         if ~s then s = execute( 'mvn_lpw_load, YYYY_MM_DD,/notatlasp,/noserver,/leavespice,packet=packet,/nospice' ) ;- try /nospice
         for itf=0,n_elements(tf)-1 do begin
            get_data,tf[itf],dtype=dtype
            if dtype eq 1 then tplot_rename,tf[itf],time_string(today,tf='YYYYMMDD_')+tf[itf]
         endfor
         store_data,'mvn_lpw_*',/del
         mvn_spc_clear_spice_kernels
         timespan,tr
      endfor
      ;;; concat and sort
      for itf=0,n_elements(tf)-1 do begin
         tn = tnames('????????_'+tf[itf],ntn)
         if ntn gt 0 then begin
            for itn=0,ntn-1 do begin
               get_data,tn[itn],data=d,dlim=dlim
               if itn eq 0 then begin
                  newx = d.x
                  newy = d.y
                  if tag_exist(d,'V') then newv = d.v
               endif else begin
                  newx = [newx,d.x]
                  newy = [newy,d.y]
                  if tag_exist(d,'V') then begin
                     if size(d.v,/n_dim) eq 2 then newv = [newv,d.v]
                  endif
               endelse
            endfor
            if tag_exist(d,'V') then $
               store_data,tf[itf],data={x:newx,y:newy,v:newv},dlim=dlim $
            else store_data,tf[itf],data={x:newx,y:newy},dlim=dlim
            tplot_sort,tf[itf]
            store_data,tn,/del
         endif
      endfor
      if l2iv ge 0 and tr[1] gt time_l2ok then begin ;- override L0 by L2 after time_l2ok
         mvn_lpw_load_l2,'lpiv',/notplot
         get_data,'mvn_lpw_swp1_IV',data=div,dtype=divtype
         get_data,'mvn_lpw_lp_iv_l2',data=d,dtype=dtype
         if dtype*divtype ne 0 then begin
            w0 = where( div.x lt time_l2ok , nw0 )
            w1 = where( d.x gt time_l2ok , nw1 )
            if nw0 gt 0 and nw1 gt 0 then begin
               tplot_rename,'mvn_lpw_swp1_IV','mvn_lpw_swp1_IV_old'
               dnew = { x:[div.x[w0],d.x[w1]], $
                        y:[div.y[w0,*],d.y[w1,*]], $
                        v:[div.v[w0,*],d.v[w1,*]] }
               store_data,'mvn_lpw_swp1_IV',data=dnew
            endif
         endif
      endif
      tplot_rename,'mvn_lpw_swp1_IV','mvn_lpw_lp_iv_l2'
   endelse

   ;;; load scpots (pregenerated and compiled)
   mvn_scpot_restore,/tplot

   ;;; load data for summary plots
   if keyword_set(plot) then begin
      mvn_sta_l2_load,sta_apid='c0'
      mvn_sta_l2_tplot
      mvn_swe_load_l2,apid=['a4']
      mvn_swe_etspec,units='eflux'
   endif

   noload = 1
endif                           ;- noload


;;; get LPW IV curves
get_data,'mvn_lpw_lp_iv_l2',data=div,dtype=divtype
if divtype eq 0 then begin
   dprint,'No valid tplot variables for lpw iv'
   return
endif



;;; get S/C pot and other data
tscpot_all = [!values.d_nan]
scpot_all = [!values.f_nan]
get_data,'alt',data=dalt,dtype=dalttype
get_data,'pot_swepos_full',data=dvswe,dtype=dvswetype
if dvswetype*dalttype ne 0 then begin
   alt = interp(dalt.y,dalt.x,dvswe.x,/no_ex,interp=600)
   w = where(finite(dvswe.y) and alt gt alt_swepos[0] and alt lt alt_swepos[1],nw)
   if nw gt 0 then begin
      tscpot_all = dvswe.x[w]
      scpot_all = dvswe.y[w]
   endif
endif
get_data,'pot_sweneg_full',data=dvsweneg,dtype=dvswenegtype
if dvswenegtype*dalttype ne 0 then begin
   alt = interp(dalt.y,dalt.x,dvsweneg.x,/no_ex,interp=600)
   w = where(finite(dvsweneg.y) and (alt gt alt_sweneg[0] and alt lt alt_sweneg[1]) $
             or dvsweneg.y lt -10 ,nw) ;- trust if V < -10 V
   if nw gt 0 then begin
      tscpot_all = [ tscpot_all, dvsweneg.x[w] ]
      scpot_all = [ scpot_all, dvsweneg.y[w] ]
   endif
endif
get_data,'pot_staneg_full',data=dvsta,dtype=dvstatype
if dvstatype*dalttype ne 0 then begin
   alt = interp(dalt.y,dalt.x,dvsta.x,/no_ex,interp=600)
   w = where(dvsta.y lt 0 and alt gt alt_sta[0] and alt lt alt_sta[1] ,nw)
   if nw gt 0 then begin
      tscpot_all = [ tscpot_all, dvsta.x[w] ]
      scpot_all = [ scpot_all, dvsta.y[w] ]
   endif
   store_data,'pot_staneg_full_abs',data={x:dvsta.x,y:-dvsta.y}
endif
scpot_all = scpot_all[sort(tscpot_all)]
tscpot_all = tscpot_all[sort(tscpot_all)]
if total(finite(scpot_all)) eq 0 then begin
   dprint,'No valid scpot data'
   return
endif

store_data,'scpot0_all',data={x:tscpot_all,y:scpot_all},dlim={colors:1}



;;; if plot, set up tplot options
if keyword_set(plot) then begin
   options,'mvn_swe_et_spec_svy',zrange=[1.e5,1.e9],minzlog=1.e-30,yticklen=-.01,datagap=maxgap
   options,'pot_swepos_full',psym=3,constant=[3],yrange=[0,20]
   store_data,'swe_comb',data=['mvn_swe_et_spec_svy','pot_swepos_full'], $
              dlim={yrange:[3,4627.5],ystyle:1}
   options,'mvn_lpw_lp_iv_l2',spec=1,zrange=[-1.e-7,1.e-7],yrange=[-45,45],ystyle=1, $
           yticklen=-.01,no_interp=1,ytitle='LPW!cI-V',datagap=maxgap
   options,'alt2',panel_size=.5,ytitle='Alt!c[km]',ylog=1,yrange=[100,1e4], $
           constant=[alt_swepos,alt_sta,alt_sweneg]
   options,'pot_staneg_full_abs',colors=6
   store_data,'sta_comb',data=['mvn_sta_c0_E','pot_staneg_full_abs'], $
              dlim={ytitle:'STA c0!cEnergy!c[eV]',yticklen:-.01,yrange:[0.164,30e3],minzlog:1e-30}
   options,'pot_staneg_full',colors=6,psym=1,symsize=.1
   tplot_options,'xmargin',[14,12]
endif                           ;- plot



;;; generate iv inflection voltages
if ~keyword_set(novinfl) then begin
;;; set up data containers
ders = fltarr(n_elements(div.x),128)*!values.f_nan
vols = transpose(rebin( (findgen(128)+.5)/128.* 40.-20. , $
                        128, n_elements(div.x)))
vinfl = replicate(!values.f_nan,n_elements(div.x))
vfloat = replicate(!values.f_nan,n_elements(div.x))
cursmo = div.y*!values.f_nan


;;; check valid IV curves
validiv = replicate(1b,n_elements(div.x))
icur = reform(div.y[*,0])
icur_med = icur*!values.f_nan
;;; filter out positive/small Ii at V0 on an orbit-by-orbit basis
for iperi=0,n_elements(tperi0)-1 do begin
   ww = where( div.x ge tperi0[iperi] and div.x lt tperi1[iperi] $
               and finite(icur), nww )
   if nww eq 0 then continue
   medtmp = median( icur[ww] )
   icur_med[ww] = medtmp
   thld_now = medtmp * 10.^icur_thld < 0.
   ww = where( div.x ge tperi0[iperi] and div.x lt tperi1[iperi] $
               and icur gt thld_now, nww )
   if nww eq 0 then continue
   validiv[ww] = 0b
endfor
;;; filter out high-altitude I-V curves with spurious peaks
alt_iv = interp(dalt.y,dalt.x,div.x,/no_ex,interp=600)
for it=0,n_elements(div.x)-1 do begin
   if alt_iv[it] lt 2000 then continue                     ;- high alt.
   w = where( div.y[it,1:(-1)] gt 2e-7 $                   ;- too high positive currents
              and div.y[it,1:(-1)]/div.y[it,0:(-2)] gt 2 $ ;- too large jump
              , nw )
   if nw gt 0 then validiv[it] = 0
endfor


;;; loop through time steps
syst0 = systime(/sec)
secnow = 0.
for it=(ntsmo-1)/2,n_elements(div.x)-(ntsmo-1)/2-1 do begin
   if systime(/sec)-syst0 gt secnow+1 then begin
      secnow = secnow + 1
      dprint,'Calc Vinfl: ' $
             +string(100.*it/(n_elements(div.x)-1),f='(f8.4)') $
             +' %, '+time_string(div.x[it])
   endif

   if ~validiv[it] then continue

   vol = reform(div.v[it,*])

   ;;; smooth in time
   cur = reform(div.y[it,*]) * 0.
   nsum = 0.
   for itsmo=-(ntsmo-1)/2,(ntsmo-1)/2 do begin
      vdif0 = total(abs(div.v[it+itsmo,*]-div.v[it,*]))
      if vdif0 eq 0 and validiv[it+itsmo] then begin ;- only same V steps
         cur = cur + reform(div.y[it+itsmo,*])
         nsum = nsum + 1.
      endif
   endfor
   cur = cur / nsum
   cursmo[it,*] = cur


   ;;; compute the derivative from unique data points
   cur = cur[sort(vol)]
   vol = vol[sort(vol)]
   uni1 = uniq(vol)
   uni0 = [ 0, uni1[0:n_elements(uni1)-2]+1 ]
   uvol = vol[uni1]
   ucur = uvol*!values.f_nan
   for i=0,n_elements(uni1)-1 do ucur[i] = mean(cur[uni0[i]:uni1[i]])
   vol = uvol
   cur = ucur
   if n_elements(vol) lt 5 then continue
   
   vol0 = vol
   cur0 = cur

   ;;; oversample into regular bins at the minimum resolution
   dvol = min(vol0[1:(-1)]-vol0[0:(-2)])
   vol = dgen(range=minmax(vol0),res=dvol)
   cur = interp(cur0,vol0,vol,/no_ex)
   
   ;;; apply a Savitzky-Golay smoothing filter, 3-degree smoothing polynomial
   ;;; choose the sliding window width - this is an important parameter to decide (Bernatskiy et al., 2024)
   nsg = 16                                            ;- dV = +/- nsg*dvol
   if max(vol0,/nan) gt 40 $                           ;- wide vol. range
      or (max(vol0,/nan) gt 20 and cur0[-1] lt 1e-7) $ ;- low current
   then nsg = 24                                       ;- wider window for noisy data

   sg1 = savgol(nsg,nsg,1,3)*(factorial(1)/(.1^1)) ;- 1st order, 1st derivative
   der = convol(cur,sg1,/edge_truncate)
   sg2 = savgol(nsg,nsg,2,3)*(factorial(2)/(.1^2)) ;- 2nd order, 2nd derivative
   der2 = convol(cur,sg2,/edge_truncate)
   sg = savgol(nsg,nsg,0,3)            ;- 0th order, smoothing
   cur = convol(cur,sg,/edge_truncate) ;- overwirte cur
   
   ;;; get the floating potential
   w = where( vol gt -30 and vol lt 30 )
   mincur = min(abs(cur[w]),imin)
   maxcur = max(abs(cur[w]))
   if alog10(maxcur)-alog10(mincur) gt .5 then vfloat[it] = vol[w[imin]] $
   else continue                ;- flat curve -> skip

   ;;; discard V >~ Vfloat, assuming Vinfl <~ Vfloat
   vbuffer = 4.
   w = where( vol gt vfloat[it]+vbuffer and finite(der) , nw)
   if nw gt 0 then begin
      der[w] = !values.f_nan
      der2[w] = !values.f_nan
   endif

   ;;; discard high-V region at high alt.
   if alt_iv[it] gt 1000 then begin
      w = where( vol gt 7. , nw )
      if nw gt 0 then begin
         der[w] = !values.f_nan
         der2[w] = !values.f_nan
      endif
   endif

   ;;; normalize dI/dV
   der = der / max(der,/nan)

   ;;; record data
   vols[it,*] = dgen(128,range=minmax(vol))
   ders[it,*] = interp(der,vol,vols[it,*],/no_ex)

   ;;; grab the first significant dI/dV peak
   thld_peak = .4               ;- threshold for normalized dI/dV peak, another important empirical choice
   w = where( der gt thld_peak , nw )
   ;;; selects the first zero-crossing of 2nd derivative
   ww = where(der2[w] lt 0 , nww)
   if nww eq 0 or der2[w[0]] lt 0 then continue ;- skip if no proper peak is detected
   vpeak = interp(vol[w[0]:w[ww[0]]],der2[w[0]:w[ww[0]]],0,/no_ex)

   ;;; record data
   if vpeak gt vrinfl[0] and vpeak lt vrinfl[1] then vinfl[it] = vpeak
endfor                          ;- it loop

;;; store tplot variables
store_data,'mvn_lpw_lp_iv_l2_log', $
           data={x:div.x,y:alog10(abs(div.y)),v:div.v}, $
           dlim={zrange:[-9,-5],yrange:[-20,20],yticklen:-.01, $
                 ytitle:'LPW!cI-V!c[V]',datagap:maxgap,spec:1,no_interp:1, $
                 ztitle:'log!d10!n(|I|)!c(corrected)'}
store_data,'icur',data={x:div.x,y:alog10(abs(icur<0))}, $
           dlim={yrange:[-10,-7],ystyle:1, $
                 labels:['I!dV0!n'],labflag:1,ytitle:'log(-I)', $
                 datagap:maxgap,psym:0,constant:findgen(7)/2.-9.5}
store_data,'icur_med',data={x:div.x,y:alog10(abs(icur_med<0))}, $
           dlim={yrange:[-10,-7],ystyle:1,linestyle:2,colors:[2]}
store_data,'validiv',data={x:div.x,y:validiv}, $
           dlim={panel_size:.2,yrange:[-1,2],ystyle:1,psym:3, $
                 labels:'valid',labflag:1, $
                 ytitle:' ',yticks:1,yminor:1,ytickname:[' ',' ']}
store_data,'mvn_lpw_lp_iv_l2_log_smo', $
           data={x:div.x,y:alog10(abs(cursmo)),v:div.v}, $
           dlim={zrange:[-9,-5],yrange:[-20,20],yticklen:-.01, $
                 ytitle:'LPW!ctntsmo '+string(ntsmo,f='(i0)')+'!cI-V!c[V]', $
                 datagap:maxgap,spec:1,no_interp:1, $
                 ztitle:'log!d10!n(|I|)!c(corrected)'}
store_data,'mvn_lpw_lp_iv_dIV_smo',data={x:div.x,y:ders,v:vols}, $
           dlim={yrange:[-20,20],zrange:[0,1],spec:1,yticklen:-.01, $
                 ytitle:'LPW!cI-V!c[V]',ztitle:'Norm.!cdI/dV', $
                 constant:0,datagap:maxgap,no_interp:1}
store_data,'mvn_lpw_lp_iv_l2_vfloat',data={x:div.x,y:vfloat}, $
           dlim={colors:[5],datagap:maxgap}
store_data,'mvn_lpw_lp_iv_l2_vinfl',data={x:div.x,y:vinfl}, $
           dlim={colors:[3],datagap:maxgap}
store_data,'IV_log_smo_comb', $
           data=['mvn_lpw_lp_iv_l2_log_smo','mvn_lpw_lp_iv_l2_vfloat'], $
           dlim={yrange:[-20,20]}
store_data,'dIV_smo_comb', $
           data=['mvn_lpw_lp_iv_dIV_smo','mvn_lpw_lp_iv_l2_vinfl'], $
           dlim={yrange:[-20,20]}
endif                           ;- novinfl



;;; loop through orbits
get_data,'mvn_lpw_lp_iv_l2_vinfl',data=dvinfl
iorb0 = (norbwin-1)/2
iorb1 = nworb-1 - (norbwin-1)/2
for iorb=iorb0,iorb1 do begin
   orbstr = string(orbnums[iorb],f='(i5.5)')
   trorb = [ tperi0[iorb] , tperi1[iorb] ]
   trfit = [ tperi0[iorb-(norbwin-1)/2] , tperi1[iorb+(norbwin-1)/2] ]

   w = where(finite(scpot_all) and tscpot_all gt trfit[0] and tscpot_all lt trfit[1] , nw )
   times = tscpot_all[w]
   Vswe = scpot_all[w]

   a = [!values.d_nan,!values.d_nan]
   corr = !values.d_nan
   apol = [!values.d_nan,!values.d_nan,!values.d_nan]
   Nscat = 0l

   ;;; LPW IV Vinfl v Vswe
   w = where( div.x gt trfit[0] and div.x lt trfit[1], nw )
   if nw gt minNdata then begin
      vinfl2 = interp(dvinfl.y,dvinfl.x,times,/no_ex,interp=maxgap)
      w = where( finite(vinfl2) ,nw )
      if nw gt minNdata then begin
         x = Vswe[w]
         y = -vinfl2[w]
         t = times[w]

         apol0 = [ -2.4, .76, -0.010 ]    ;- nominal parameters
         thld_out = 1.8

         ;;; filter out outliers and fit
         w = where( abs(apol0[0]+apol0[1]*x+apol0[2]*x^2 - y) lt thld_out , nw )
         Nscat = nw
         if nw gt minNdata then begin
            x2 = x[w]
            y2 = y[w]
            t2 = t[w]
            a = ladfit(x2,y2)   ;- linear fit
            corr = correlate(x2,y2)
            apol = poly_fit(x2,y2,2) ;- polynomial fit
            if keyword_set(scatdir) then begin
               file_mkdir,scatdir
               w2 = where(t2 gt trorb[0] and t2 lt trorb[1], nw2)
               if nw2 gt 0 then begin
                  scat = {t:t2[w2],vswe:x2[w2],vinfl:-y2[w2]}
                  save,scat,filename=scatdir+orbstr+'.sav',/compress
               endif
            endif
         endif

         w = where( dvinfl.x gt trorb[0] and dvinfl.x lt trorb[1] , nw )
         tvinfl = dvinfl.x[w]
         scpot_lin = ( (-dvinfl.y[w]) - a[0] ) / a[1]
         scpot_pol = ( -apol[1] + sqrt(apol[1]^2 - 4.*(apol[0]+dvinfl.y[w])*apol[2]) ) / (2.*apol[2])

         w = where( ~finite(scpot_lin) , nw )
         if nw gt 0 then scpot_pol[w] = !values.f_nan

         ;;; Filter out shadow regions
         get_data, 'wake', data=dwake, dtype=dtype
         if dtype ne 0 then begin
            shadow = interp(float(finite(dwake.y)), dwake.x, tvinfl, /no_ex)
            w = where(shadow gt 0., nw)
            if nw gt 0 then scpot_lin[w] = !values.f_nan
            if nw gt 0 then scpot_pol[w] = !values.f_nan
         endif

         ;;; store the results
         store_data,orbstr+'_mvn_swe_lpw_scpot_lin', $
                    data={x:tvinfl,y:scpot_lin}, $
                    dlim={colors:2,datagap:maxgap, $
                          ytitle:'linear fit!cscpot!c[V]'}
         store_data,orbstr+'_mvn_swe_lpw_scpot_pol', $
                    data={x:tvinfl,y:scpot_pol}, $
                    dlim={datagap:maxgap, $
                          ytitle:'poly fit!cscpot!c[V]'}
         store_data,orbstr+'_mvn_swe_lpw_scpot_lin_para', $
                    data={x:mean(trorb),y:[[a[0]],[a[1]],[corr]]}, $
                    dlim={psym:1,datagap:maxgap,labflag:1, $
                          labels:['offset','slope','corr'],colors:[2,6,0]}
         store_data,orbstr+'_mvn_swe_lpw_scpot_pol_para', $
                    data={x:mean(trorb),y:[[apol[0]],[apol[1]],[apol[2]]]}, $
                    dlim={psym:1,datagap:maxgap,labflag:1, $
                          labels:['a0','a1','a2'],colors:[2,6,0]}
         store_data,orbstr+'_mvn_swe_lpw_scpot_Ndata', $
                    data={x:mean(trorb),y:Nscat}, $
                    dlim={psym:1,datagap:maxgap}


         ;;; scat plot
         if keyword_set(plot) then begin
            bin2d,x,y,y,binsize=[.25,.25],xcent=xcent,ycent=ycent,flagnodata=!values.f_nan,binhist=binhist,xrange=[-20,20],yrange=[-20,20]
            w = where(xcent gt 10 ,nw)
            for iw=0,nw-1,2 do begin
               binhist[w[iw],*] = binhist[w[iw],*]+binhist[w[iw]+1,*]
               binhist[w[iw]+1,*] = binhist[w[iw],*]
            endfor
            specplot,xcent,ycent,binhist, $
                     limits={xrange:[-20,20],xstyle:1,yrange:[-20,20],ystyle:1, $
                             xtitle:'Vswe,sta [V]',ytitle:'-Vinfl [V]', $
                             xmargin:[10,8],isotropic:1, $
                             title:time_string(trfit[0])+' -> ' $
                             +time_string(trfit[1]), $
                             no_interp:1,zlog:1, $
                             ztitle:'Ndata'}

            for il=-25,25,5 do oplot,[-100,100],[il,il],linestyle=1
            for il=-25,25,5 do oplot,[il,il],[-100,100],linestyle=1

            xplot = findgen(601)/10.-30.
            oplot,xplot,a[0]+a[1]*xplot,color=2
            oplot,xplot,apol[0]+apol[1]*xplot+apol[2]*xplot^2,color=1
            oplot,xplot,apol0[0]+apol0[1]*xplot+apol0[2]*xplot^2+thld_out,linestyle=2
            oplot,xplot,apol0[0]+apol0[1]*xplot+apol0[2]*xplot^2-thld_out,linestyle=2
            xyouts,/norm,color=2,.15,.97,'linear fit!c' + $
                   'y = '+string(a[0],f='(f5.2)') $
                   +string(a[1],f='(f+5.2)')+'x' $
                   +'!cCorr. = '+string(corr,f='(f5.2)') $
                   +'!cNdata = '+string(Nscat,f='(i0)')
            xyouts,/norm,color=1,.55,.97,'poly fit!c' + $
                   'y = '+string(apol[0],f='(f6.2)') $
                   +string(apol[1],f='(f+6.2)')+'x' $
                   +string(apol[2],f='(f+8.4)')+'x^2'
            if keyword_set(figdir) then begin
               file_mkdir,figdir+time_string(mean(trorb),tf='scat/YYYY/MM/')
               makepng,figdir+time_string(mean(trorb),tf='scat/YYYY/MM/YYYYMMDD_')+orbstr
            endif
         endif

      endif                     ;- interp Vinfl to times -> minNdata
   endif                        ;- LPW Vinfl v Vswe


   store_data,'scpots', $
              data=[orbstr+'_mvn_swe_lpw_scpot_pol','pot_swepos_full','pot_sweneg_full','pot_staneg_full'], $
              dlim={labels:['swe/lpw','swe+','swe-','sta'], $
                    colors:[0,2,6,4],labflag:1,datagap:maxgap,yrange:[-20,20], $
                    constant:[0],panel_size:1.5}

   ;;; tplot
   if keyword_set(plot) then begin
      tplot,[ $
            'sta_comb', $
            'swe_comb', $
            'icur', $
            'mvn_lpw_lp_iv_l2', $
            'IV_log_smo_comb', $
            'dIV_smo_comb', $
            'validiv', $
            'scpots', $
            'alt2' $
            ],trange=trorb,title='orbit #'+orbstr
      tplot_panel,var='icur',oplot='icur_med'
      tplot_panel,var='scpots',oplot=orbstr+'_mvn_swe_lpw_scpot_pol'
      if keyword_set(figdir) then begin
         file_mkdir,figdir+time_string(mean(trorb),tf='times/YYYY/MM/')
         makepng,figdir+time_string(mean(trorb),tf='times/YYYY/MM/YYYYMMDD_')+orbstr
      endif
   endif                        ;- plot

endfor                          ;- iorb



;;; concat and sort
tf = ['mvn_swe_lpw_scpot_lin','mvn_swe_lpw_scpot_pol', $
      'mvn_swe_lpw_scpot_lin_para','mvn_swe_lpw_scpot_pol_para', $
      'mvn_swe_lpw_scpot_Ndata' ]
for itf=0,n_elements(tf)-1 do begin
   tn = tnames('?????_'+tf[itf],ntn)
   if ntn gt 0 then begin
      for itn=0,ntn-1 do begin
         get_data,tn[itn],data=d,dlim=dlim
         if itn eq 0 then begin
            newx = d.x
            newy = d.y
            if tag_exist(d,'V') then newv = d.v
         endif else begin
            newx = [newx,d.x]
            newy = [newy,d.y]
            if tag_exist(d,'V') then begin
               if size(d.v,/n_dim) eq 2 then newv = [newv,d.v]
            endif
         endelse
      endfor
      if tag_exist(d,'V') then $
         store_data,tf[itf],data={x:newx,y:newy,v:newv},dlim=dlim $
      else store_data,tf[itf],data={x:newx,y:newy},dlim=dlim
      tplot_sort,tf[itf]
      store_data,tn,/del
   endif
endfor


def_scpot = 'mvn_swe_lpw_scpot_pol'
get_data,def_scpot,data=d
store_data,'mvn_swe_lpw_scpot',data=d, $
           dlim={datagap:maxgap,ytitle:'SWEA-LPW!cscpot!c[V]'}


end



