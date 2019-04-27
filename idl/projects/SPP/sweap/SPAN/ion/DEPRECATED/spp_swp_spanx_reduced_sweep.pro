; $LastChangedBy: davin-mac $
; $LastChangedDate: 2019-04-26 15:38:42 -0700 (Fri, 26 Apr 2019) $
; $LastChangedRevision: 27104 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/DEPRECATED/spp_swp_spanx_reduced_sweep.pro $
;

function spp_swp_multi_sort,var1,var2,var3
  svar = 0
  n = n_elements(var1)
  threshold_res = 1e-3
  
  range = minmax(var1)
  drange = double(range[1] - range[0])
  if drange ne 0 then svar += (var1-range[0]+drange/10)/drange/1.2
  if keyword_set(var2) then begin
    if n_elements(var2) ne n then message,'Arrays must be the same size'
    range = minmax(var2)
    drange = double(range[1] - range[0])
    svar /= threshold_res
    if drange ne 0 then svar += (var2-range[0]+drange/10)/drange/1.2
  endif
  if keyword_set(var3) then begin
    if n_elements(var3) ne n then message,'Arrays must be the same size'
    range = minmax(var3)
    drange = double(range[1] - range[0])
    svar /= threshold_res
    if drange ne 0 then svar += (var3-range[0]+drange/10)/drange/1.2
  endif
  svar /= threshold_res
  svar += (dindgen(n)+.5)/(n+1)
  return,sort(svar)
end


;; ************************************************************
;; *************************** MAIN ***************************
;; ************************************************************


;usage:
; rswp = spp_swp_span_reduced_sweep(fullsweep=fswp,  ptable=spe.ptable)

function spp_swp_spanx_reduced_sweep,fullsweep=fswp,ptable=ptable,zero_nan=zero_nan

rswp = dictionary()

average_quants = ['energy','theta','theta_new','phi','rtime','geom','dE','dphi']
total_quants = ['delt','geomdt','dtheta']

quantnames = [average_quants,total_quants]
normalize = [average_quants eq average_quants, total_quants eq '']

hist = ptable.hist
ri  = ptable.reverse_ind
substep_dim = 1    ; should be 1 for ions ; 2 for electrons ; 0 for targeted?


for q=0,n_elements(quantnames)-1  do begin
  qname = quantnames[q]
  if ~fswp.haskey(qname) then continue
  quant = fswp[qname]
  norm  = normalize[q] 
  if substep_dim ne 0 then begin
    qmin  = min(quant, dimen = substep_dim)
    qmax  = max(quant, dimen = substep_dim)
    qval = total(quant,substep_dim)                ; Average over the micro steps
    if norm then  qval /= 4
  endif else begin
    qmin = quant
    qmax = quant
    qval = quant
  endelse
 ; w = where(hist gt 0,nc)
  rqarray = replicate(!values.f_nan,n_elements(hist) )
;  whist = hist[w]
;  j=0
  for i = 0,n_elements(hist)-1 do begin
    if hist[i] eq 0 then continue
    ind0 = ri[i] 
    ind1 = ri[i+1]-1
    ind =  ri[ ind0 :ind1 ]
    rqval = total( qval[ ind ] ) 
    if norm then   rqval = rqval / float( hist[i] )
;    rqarray[j++] = rqval
    rqarray[i] = rqval
  endfor
  rswp[qname] = rqarray
endfor


timesort =spp_swp_multi_sort(rswp['rtime'])


;timesort = 


return,rswp
end



;  counts = counts(phi,theta,energy)
;  rate = counts / delt
;  eflux = counts / (geom # delt)
;  flux  = counts / (geom # delt) / energy
;  df    = counts / (geom # delt) / energy^2 * (m^2 /2)


