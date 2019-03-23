;+
;
; SPP_SWP_SPI_REDUCED_SWEEP
;
; PUPORSE:
;
; EXAMPLE:
;
;   rswp = spp_swp_span_reduced_sweep(fullsweep=fswp,ptable=spe.ptable)
;
; $LastChangedBy: rlivi2 $
; $LastChangedDate: 2019-03-22 10:30:13 -0700 (Fri, 22 Mar 2019) $
; $LastChangedRevision: 26880 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_reduced_sweep.pro $
;
; -

FUNCTION spp_swp_spi_reduced_sweep, fullsweep=fswp, ptable=ptable

   rswp = dictionary()
   average_quants = ['energy','theta','phi','time','geom']
   total_quants = ['delt','geomdt']
   quantnames = [average_quants,total_quants]
   normalize = [average_quants EQ average_quants, total_quants EQ '']
   hist = ptable.hist
   ri = ptable.reverse_ind
   substep_dim = 2

   FOR q=0,n_elements(quantnames)-1 DO BEGIN
      qname = quantnames[q]
      IF ~fswp.haskey(qname) THEN CONTINUE
      quant = fswp[qname]
      norm  = normalize[q] 
      IF substep_dim NE 0 THEN BEGIN
         qmin  = min(quant, dimen = substep_dim)
         qmax  = max(quant, dimen = substep_dim)
         qval = total(quant,substep_dim)
         IF norm THEN qval /= 4
      ENDIF ELSE BEGIN
         qmin = quant
         qmax = quant
         qval = quant
      ENDELSE
      rqarray = replicate(!values.f_nan,n_elements(hist) )
      FOR i = 0,n_elements(hist)-1 DO BEGIN
         IF hist[i] EQ 0 THEN CONTINUE
         ind0 = ri[i] 
         ind1 = ri[i+1]-1
         ind =  ri[ ind0 :ind1 ]
         rqval = total( qval[ ind ] ) 
         IF norm THEN rqval = rqval / hist[i] 
         rqarray[i] =rqval
      ENDFOR
      rswp[qname] = rqarray
   ENDFOR

   return,rswp

END



;  counts = counts(phi,theta,energy)
;  rate = counts / delt
;  eflux = counts / (geom # delt)
;  flux  = counts / (geom # delt) / energy
;  df    = counts / (geom # delt) / energy^2 * (m^2 /2)


