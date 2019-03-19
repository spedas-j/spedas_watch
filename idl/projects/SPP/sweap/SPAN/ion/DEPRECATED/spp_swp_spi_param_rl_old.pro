;+
;
; SPP_SWP_SPI_PARAM
;
; Purpose:
;
; SVN Properties
; --------------
; $LastChangedRevision: 26832 $
; $LastChangedDate: 2019-03-17 20:19:01 -0700 (Sun, 17 Mar 2019) $
; $LastChangedBy: rlivi2 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/DEPRECATED/spp_swp_spi_param_rl_old.pro $
;
;-


;;---------------------------------------------------------------------
;;                           COPIED FROM
;; LastChangedBy: davin-mac
;; LastChangedDate: 2018-12-07 14:27:21 -0800 (Fri, 07 Dec 2018) 
;; LastChangedRevision: 26274
;; URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu:36867/repos/...
;; spdsoft/trunk/projects/SPP/sweap/SPAN/electron/spp_swp_spe_param.pro 
;;---------------------------------------------------------------------
FUNCTION spp_swp_spi_param_rl_old, detname=detname, $
                                   emode=emode, $
                                   pmode=pmode,$
                                   reset=reset

   ;; COMMON BLOCK
   COMMON spp_swp_spi_param_com, spi_param_dict ;, etables, cal, a,b


   ;;###############################################
   ;;###                  RESET                  ###
   ;;###############################################
   IF keyword_set(reset) THEN BEGIN
      IF isa(spi_param_dict,'OBJREF') THEN $
       obj_destroy,spi_param_dict
      spi_param_dict = !null
   ENDIF

   ;; Now make a dictionary out of it
   IF ~isa(spi_param_dict,'dictionary')  THEN BEGIN
      spi_param_dict = dictionary()
   ENDIF

   
   ;;###############################################
   ;;###                  EMODE                  ###
   ;;###############################################
   retval = dictionary()
   IF isa(emode) THEN BEGIN
      IF ~spi_param_dict.haskey('ETABLES') THEN $
       spi_param_dict.etables = orderedhash()
      etables = spi_param_dict.etables
      IF ~etables.haskey(emode) THEN BEGIN
         ratios = [1.,.3,.1,.1,.001]
         dprint,dlevel=2, 'Generating Energy table - emode: ' + $
                strtrim(fix(emode),2)
         CASE emode OF
            1:  etables[1] = spp_swp_spanx_sweep_tables($
                             [ 500.,10000.],spfac=ratios[2],$
                             emode=emode, _extra=spani_params)
            2:  etables[2] = spp_swp_spanx_sweep_tables($
                             [ 500., 2000.],spfac=ratios[2],$
                             emode=emode, _extra=spani_params)
            3:  etables[3] = spp_swp_spanx_sweep_tables($
                             [ 250., 1000.],spfac=ratios[2],$
                             emode=emode,_extra=spani_params)
            4:  etables[4] = spp_swp_spanx_sweep_tables($
                             [1000., 4000.],spfac=ratios[2],$
                             emode=emode, _extra=spani_params)
            5:  etables[5] = spp_swp_spanx_sweep_tables($
                             [ 125.,20000.],spfac=ratios[2],$
                             emode=emode, _extra=spani_params)
            6:  etables[6] = spp_swp_spanx_sweep_tables($
                             [4000.,40000.],spfac=ratios[2],$
                             emode=emode,_extra=spani_params)
            ELSE:BEGIN
               etables[emode] = 'Invalid'
               printdat,'Unknown etable encountered'
            END
         ENDCASE    
      ENDIF
      retval.etable = etables[emode]
    
      ;;def5coeff = [-1396.73,$
      ;;               539.083,$
      ;;                 0.802293,$
      ;;                -0.0462400,$
      ;;                -0.000163369,$
      ;;                 0.00000319759]

   ENDIF



   
   ;;##############################################
   ;;###            SPAN-I DETNAME              ###
   ;;##############################################
   IF isa(detname) THEN BEGIN
      IF ~spi_param_dict.haskey('CALS') THEN $
       spi_param_dict.cals  = dictionary()
      cals = spi_param_dict.cals
      IF ~cals.haskey(strupcase(detname)) THEN BEGIN
         dprint,dlevel=2,'Generating cal structure for ',detname
         dphi = [1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2]*11.25
         ;; This number needs fixing!
         phi = total(dphi,/cumulative) + 10. + dphi/2 
         n_anodes = 16
         eff = replicate(1.,n_anodes)
         cal = { $
               name:detname,$
               n_anodes:n_anodes,$
               phi:phi,$
               dphi:dphi,$
               eff:eff,$
               ;; Conversion from dac to angle
               ;; This is not quite appropriate - works for now
               defl_scale: .0028d,$ 
               hem_scale:1000.d,$
               spoil_scale:80./2.^16,$   ;; Needs correction
               k_anal:replicate(16.7,n_anodes),$
               k_defl:replicate(1.,n_anodes) $
               }
         cals[strupcase(detname)] = cal
      ENDIF
      retval.cal = cals[strupcase(detname)]
   ENDIF
   
   ;;#################################################
   ;;###                  PMODE                    ###
   ;;#################################################
   IF isa(pmode) THEN BEGIN
      IF ~spi_param_dict.haskey('ptables') THEN $
       spi_param_dict.ptables = orderedhash()
      ptables = spi_param_dict.ptables
      IF ~ptables.haskey(pmode) THEN BEGIN
         dprint, 'Generating new product table ',$
                 pmode,dlevel=2
         CASE pmode OF
            '32Ex16M':BEGIN
               ;; 32 sample energy spectra
               ;; 8,32,16
               ;; 4096 samples; full resolution
               binmap = reform(replicate(1,16*8) # $
                               indgen(32),16,8,32) 
            END
            '8Dx32Ex8A':BEGIN
               ;; 2048 samples; full resolution
               binmap = indgen(8,32,8)
            END
            ;;'16Ax8D':binmap = indgen() ;  128 sample
            ;; 32 sample energy spectra
            ;;'32E':binmap = reform(replicate(1,16*8) # $
            ;;                      indgen(32),16,8,32)
            ;; 16 sample anode spectra
            ;;'16A':binmap = reform(indgen(16) # $
            ;;                      replicate(1,8*32),16,8,32)
            ELSE: binmap = !null
         ENDCASE
         ptable = dictionary()
         ptable.pmode = pmode
         IF isa(binmap) THEN BEGIN
            hist = histogram(binmap,locations=loc,omin=omin,$
                             omax=omax,reverse_ind=ri)
            ptable.hist = hist
            ptable.binmap = binmap
            ptable.reverse_ind = ri
         ENDIF ELSE dprint,dlevel=1,'Unknown pmode: "',pmode,'"'
         ptables[pmode] = ptable
      ENDIF
      retval.ptable  = ptables[pmode]
   ENDIF

   IF n_elements(retval) EQ 0 THEN retval = spi_param_dict

   return,retval

END




;;###################
;;###     MAIN    ###
;;###################
PRO spp_swp_spi_param

   ;; COMMON BLOCK
   COMMON spi_param, param, dict

   ;; Compile Functions
   spp_swp_spi_flight_par

   
END











;; OLD COMMENTS

;  counts = counts(phi,theta,energy)
;  rate = counts / delt
;  eflux = counts / (geom # delt)
;  flux  = counts / (geom # delt) / energy
;  df    = counts / (geom # delt) / energy^2 * (m^2 /2)



; Usage:
; spe = spp_swp_spe_param(detname = 'SPA',emode = 21,pmode='ENERGY_32')
; fswp = spp_swp_span_sweeps(param = spe)


;function spp_swp_spe_deflector, defangle   ; this is a temporary location for this function - It should be put in a calibration file
;   common spp_swp_spe_deflector_com, par
;   
;   if ~keyword_set(par) then begin
;      par = polycurve2(order=5)
;      par.a[0] = -1396.73d
;      par.a[1] = 539.083d
;      par.a[2] = 0.802293d
;      par.a[3] = -0.04624d
;      par.a[4] = -0.000163369d
;      par.a[5] = 0.00000319759d
;   endif
;   return, func(defangle,par)
;
;end
