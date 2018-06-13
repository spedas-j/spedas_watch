;+
; PROCEDURE:
;       kgy_ima_emspec
; PURPOSE:
;       Plots an energy-TOF profile
; CALLING SEQUENCE:
;       kgy_ima_emspec
; KEYWORDS:
;       trange: time range
; CREATED BY:
;       Yuki Harada on 2018-07-12
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-06-12 02:51:56 -0700 (Tue, 12 Jun 2018) $
; $LastChangedRevision: 25349 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_ima_emspec.pro $
;-

pro kgy_ima_emspec,trange=trange,window=window,erange=erange,tofrange=tofrange,limits=lim2,conv256=conv256

tr = timerange(trange)
if size(conv256,/type) eq 0 then conv256 = 1

@kgy_pace_com

dat = ima_type40_arr            ;- cnt: [4,32,1024]
info = ima_info_str
header = ima_header_arr
times = time_double( string(header.yyyymmdd,format='(i8.8)') $
                     +string(header.hhmmss,format='(i6.6)'), $
                     tformat='YYYYMMDDhhmmss' ) ;- start time
wt = where( times gt tr[0] and times lt tr[1] $
            and header.mode eq 17 , nwt )
if nwt eq 0 then begin
   dprint,'No valid times'
   return
endif
ind = header[wt].index
nind = nwt

datind = value_locate( dat.index, ind )
cnt = dat[datind].cnt ;- pol, ene, tof, time
w = where( cnt eq uint(-1) , nw )
if nw gt 0 then cnt[w] = !values.f_nan
totalcnt = total( total( cnt,4,/nan ) , 1,/nan ) ;- ene, tof
totalcnt[*,1022:1023] = 0.      ;- throw away mass bin 1022,1023

ene = average(reform(info.ene_4x16[0,*,*,4]),2)*1e3


tofbin = (findgen(1024)+.5)/1024.*1000. ;- Saito et al. (2010), Fig 17 caption

isort = sort(ene)
enesort = ene[isort]
cntsort = totalcnt[isort,*]

if keyword_set(conv256) then begin
   ii = indgen(256)
   cntnew = make_array(value=!values.f_nan,32,256)
   cntnew[*,ii] = cntsort[*,ii*4] + cntsort[*,ii*4+1] $
                   + cntsort[*,ii*4+2] + cntsort[*,ii*4+3]
   cntsort = cntnew
   tofbin = (findgen(256)+.5)/256.*1000.
endif


if n_elements(erange) eq 2 then er = minmax(erange) else er = minmax(ene)
if n_elements(tofrange) eq 2 then tofr = minmax(tofrange) else tofr = [0,1000]

wene = where( enesort ge er[0] and enesort le er[1] , nwene )
if nwene eq 0 then begin
   dprint,'No valid energy steps in ',er
   return
endif
wtof = where( tofbin ge tofr[0] and tofbin le tofr[1] , nwtof )
if nwtof eq 0 then begin
   dprint,'No valid TOF bins in ',tofr
   return
endif

xp = tofbin[wtof]
yp = enesort[wene]
zp = transpose(cntsort[wene,*])
zp = zp[wtof,*]

;;; plot
if keyword_set(window) then wset,window
lim = {xtitle:'TOF [ns]',xrange:tofr,xstyle:1, $
       ytitle:'Energy [eV/q]',ylog:1,yrange:er,ystyle:1, $
       xticklen:-.01,yticklen:-.01, $
       ztitle:'Counts',zlog:1, $
       no_interp:1,title:trange_str(tr),position:[.15,.55,.85,.95]}
if size(lim2,/type) eq 8 then extract_tags,lim,lim2
specplot,xp,yp,zp,lim=lim

xp = xp
yp = total(zp,2)
plot,xp,yp, $
     xtitle='TOF [ns]',xrange=tofr,xstyle=1, $
     ytitle='Counts',ylog=1,yrange=[1,max(yp,/nan)], $
     position=[.15,.1,.85,.45],/noerase

end
