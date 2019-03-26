;+
;
; spp_swp_spi_tables
;
; :Params:
;    table : in, required, type=structure
;       PSP SWEAP SPAN-Ai Flight energy and telemetry mode configurations.
;    modeid : in, optional, type=integer
;       
; $LastChangedBy: rlivi2 $
; $LastChangedDate: 2019-03-25 11:17:57 -0700 (Mon, 25 Mar 2019) $
; $LastChangedRevision: 26889 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/tables/spp_swp_spi_tables.pro $
;-

PRO spp_swp_spi_tables, table, modeid=modeid, verbose=verbose

   ;; Parse MODE ID
   IF ~keyword_set(modeid) THEN BEGIN
      print, 'MODEID not defined. Using default 0x0015'
      modeid = '15'x
   ENDIF 

   energy_id = (ishft(modeid,-4) and 15)
   tmode_id  = (ishft(modeid,-8) and 15)

   ;; SPAN-Ai Instrument Parameters
   k       = 16.7
   nen     = 128.
   emin    = 5.
   emax    = 4000.
   rmax    = 11.
   vmax    = 4000.
   spfac   = 0.
   maxspen = 5000.
   hvgain  = 1000.
   spgain  = 20.12
   fixgain = 13.
   version = 2

   ;; Select Energy Table
   CASE energy_id OF
      ;; Science Tables 0x01
      '01'x: BEGIN
         IF keyword_set(verbose) THEN $
          print, 'Science Tables 0x01'
         ;; Launch
         emin  = 500.
         emax  = 10000.
         spfac_a = 0.10
         spfac_b = 0.25
         ;; 1st orbit (only ping side changed)
         emin  = 500.
         emax  = 10000.
         spfac_a = 0.10
         spfac_b = 0.25
      END
      ;; Science Tables 0x02
      '02'x: BEGIN
         IF keyword_set(verbose) THEN $
          print, 'Science Tables 0x02'
         emin  = 500.
         emax  = 2000.
         spfac_a = 0.10
         spfac_b = 0.25
      END
      ;; Science Tables 0x03
      '03'x: BEGIN
         IF keyword_set(verbose) THEN $
          print, 'Science Tables 0x03'
         emin  = 1500.
         emax  = 20000.
         spfac_a = 0.10
         spfac_b = 0.25
      END
      ;; Science Tables 0x04
      '04'x: BEGIN
         IF keyword_set(verbose) THEN $
          print, 'Science Tables 0x04'
         emin  = 1000.
         emax  = 4000.
         spfac_a = 0.10
         spfac_b = 0.25
         ;; Science Tables 0x05
      END 
      '05'x: BEGIN
         IF keyword_set(verbose) THEN $
          print, 'Science Tables 0x05'
         emin  = 125.
         emax  = 20000.
         spfac_a = 0.10
         spfac_b = 0.25
      END 
      ;; Science Tables 0x06
      '06'x: BEGIN
         IF keyword_set(verbose) THEN $
          print, 'Science Tables 0x06'
         emin  = 4000.
         emax  = 40000.
         spfac_a = 0.10
         spfac_b = 0.25
      END
   ENDCASE


   erange = [emin,emax]

   ;; Get Tables
   table = spp_swp_spanx_sweep_tables($
           erange,$
           spfac  = spfac_a,$
           emode  = emode,$
           _extra = spani_param)

END
