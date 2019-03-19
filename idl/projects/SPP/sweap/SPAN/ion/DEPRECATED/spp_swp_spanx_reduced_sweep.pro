; $LastChangedBy: rlivi2 $
; $LastChangedDate: 2019-03-17 20:19:01 -0700 (Sun, 17 Mar 2019) $
; $LastChangedRevision: 26832 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/DEPRECATED/spp_swp_spanx_reduced_sweep.pro $
;



;; ************************************************************
;; *************************** MAIN ***************************
;; ************************************************************


;usage:
; rswp = spp_swp_span_reduced_sweep(fullsweep=fswp,  ptable=spe.ptable)

function spp_swp_spanx_reduced_sweep,fullsweep=fswp,ptable=ptable

rswp = dictionary()

average_quants = ['energy','theta','phi','time','geom']
total_quants = ['delt','geomdt']

quantnames = [average_quants,total_quants]
normalize = [average_quants eq average_quants, total_quants eq '']

hist = ptable.hist
ri  = ptable.reverse_ind
substep_dim = 2


for q=0,n_elements(quantnames)-1  do begin
  qname = quantnames[q]
  if ~fswp.haskey(qname) then continue
  quant = fswp[qname]
  norm  = normalize[q] 
  if substep_dim ne 0 then begin
    qmin  = min(quant, dimen = substep_dim)
    qmax  = max(quant, dimen = substep_dim)
    qval = total(quant,substep_dim)
    if norm then  qval /= 4
  endif else begin
    qmin = quant
    qmax = quant
    qval = quant
  endelse
  rqarray = replicate(!values.f_nan,n_elements(hist) )
  for i = 0,n_elements(hist)-1 do begin
    if hist[i] eq 0 then continue
    ind0 = ri[i] 
    ind1 = ri[i+1]-1
    ind =  ri[ ind0 :ind1 ]
    rqval = total( qval[ ind ] ) 
    if norm then   rqval = rqval / hist[i] 
    rqarray[i] =rqval
  endfor
  rswp[qname] = rqarray
endfor

return,rswp
end



;  counts = counts(phi,theta,energy)
;  rate = counts / delt
;  eflux = counts / (geom # delt)
;  flux  = counts / (geom # delt) / energy
;  df    = counts / (geom # delt) / energy^2 * (m^2 /2)


