;;
;; SPP_SWP_SPI_PARAM
;;
;; PUPORSE:
;;
;; EXAMPLE:
;;
;; $LastChangedBy: davin-mac $
;; $LastChangedDate: 2019-03-25 13:41:53 -0700 (Mon, 25 Mar 2019) $
;; $LastChangedRevision: 26895 $
;; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/ion/spp_swp_spi_param.pro $


FUNCTION spp_swp_spi_param, detname = detname,$
                            tmode = tmode,$
                            emode = emode,$
                            pmode = pmode,$
                            mmode = mmode,$
                            reset = reset


   
   ;; ##############################
   ;; ###   Load Common Blocks   ###
   ;; ##############################   
   ;; Original Common Block
   COMMON spp_swp_spi_param_com, spi_param_dict
   ;; Load SPAN-I Common Block
   COMMON spi_param, param, dict 
   IF ~isa(param) THEN spp_swp_spi_flight_par


   
   ;; ##############################
   ;; ###         RESET          ###
   ;; ##############################
   IF keyword_set(reset) THEN BEGIN
      IF isa(spi_param_dict,'OBJREF') THEN $
       obj_destroy,spi_param_dict
      spi_param_dict = !null
   ENDIF
   ;; Load Dictionary
   IF ~isa(spi_param_dict,'dictionary') THEN $
    spi_param_dict = dictionary()
   ;; Set Dictionary
   retval = dictionary()


   
   ;; ##############################
   ;; ###      Energy Mode       ###
   ;; ##############################
   IF isa(emode) THEN BEGIN
      IF ~spi_param_dict.haskey('ETABLES') THEN $
       spi_param_dict.etables =orderedhash()
      etables = spi_param_dict.etables
      IF ~etables.haskey(emode) THEN BEGIN
;         ratios = [1.,.3,.1,.1,.001]
;
;         ;; SPAN-Ai Instrument Parameters
;         spani_params = {$
;                        k:        16.7,$
;                        nen:     128.0,$
;                        emin:      5.0,$
;                        emax:   4000.0,$
;                        rmax:     11.0,$
;                        vmax:   4000.0,$
;                        spfac:     0.0,$
;                        maxspen:5000.0,$
;                        hvgain: 1000.0,$
;                        spgain:   20.12,$
;                        fixgain:  13.0}

         ;; Debug Printing
         dprint,dlevel=2,'Generating Energy table - emode: '+$
                strtrim(fix(emode),2)
         CASE emode OF
            1:etables[1] = param.tbl.tbl1
            2:etables[2] = param.tbl.tbl2 
            3:etables[3] = param.tbl.tbl3 
            4:etables[4] = param.tbl.tbl4 
            5:etables[5] = param.tbl.tbl5 
            6:etables[6] = param.tbl.tbl6 
            ELSE:BEGIN
               etables[emode] = 'Invalid'
               printdat,'Unknown etable encountered'
            END
         ENDCASE    
      ENDIF
      retval.etable = etables[emode]
   ENDIF
   

   
   ;; ##############################
   ;; ###  Instrument Parameters ###
   ;; ##############################   
   IF isa(detname) THEN BEGIN
      IF ~spi_param_dict.haskey('CALS') THEN $
       spi_param_dict.cals = dictionary()
      cals = spi_param_dict.cals
      IF ~cals.haskey(strupcase(detname)) THEN BEGIN
         dprint,dlevel=2,'Generating cal structure for ',detname
         dphi = [11.25,11.25,11.25,11.25,11.25,$
                 11.25,11.25,11.25,11.25,11.25,$
                 22.5,22.5,22.5,22.5,22.5,22.5]
         ;; This number needs fixing!
         phi = total(dphi,/cumulative)+10.+dphi/2 
         n_anodes  = 16
         eff = replicate(1.,n_anodes)
         cal  = {$
                name:detname,$
                n_anodes:n_anodes,$
                phi:phi,$
                dphi:dphi,$
                eff:eff,$

                ;; Conversion from dac to angle
                ;; This is not quite appropriate - works for now
                defl_scale:0.0028d,$ 

                hem_scale:1000.d,$

                ;; Needs correction
                spoil_scale:80./2.^16,$ 
                k_anal:replicate(16.7,n_anodes),$
                k_defl:replicate(1.,n_anodes)$
                }
         cals[strupcase(detname)] = cal
      ENDIF
      retval.cal = cals[strupcase(detname)]
   ENDIF


   
   ;; ##############################
   ;; ###      Product Mode      ###
   ;; ##############################   
   IF isa(pmode) THEN BEGIN
      IF ~spi_param_dict.haskey('ptables') THEN $
       spi_param_dict.ptables = orderedhash()
      ptables = spi_param_dict.ptables
      IF ~ptables.haskey(pmode) THEN BEGIN
         dprint, 'Generating new product table ',pmode,dlevel=2
         CASE pmode OF
            '8Dx32Ex8A':spp_swp_spi_flight_get_prod_08Dx32Ex08A, binmap
            '8Dx32E':spp_swp_spi_flight_get_prod_08Dx32E, binmap
            '8Dx16A':spp_swp_spi_flight_get_prod_08Dx16A, binmap
            '32Ex16A':spp_swp_spi_flight_get_prod_32Ex16A, binmap
            '32Ex16M':spp_swp_spi_flight_get_prod_32Ex16M, binmap
            '16Ax8D':spp_swp_spi_flight_get_prod_16Ax08D, binmap
            '32E':spp_swp_spi_flight_get_prod_32E, binmap 
            '16A':spp_swp_spi_flight_get_prod_16A, binmap
            '8D':spp_swp_spi_flight_get_prod_08D, binmap
            ELSE:binmap = !null
         ENDCASE
         ptable = dictionary()
         ptable.pmode = pmode
         IF isa(binmap) THEN BEGIN
            hist = histogram(binmap,locations=loc,min=0,$
                             omin=omin,omax=omax,reverse_ind=ri)
            ptable.binmap = binmap
            ptable.hist = hist
            ptable.reverse_ind = ri
         ENDIF ELSE dprint,dlevel=1,'Unknown pmode: "',pmode,'"'
         ptables[pmode] = ptable
      ENDIF
      retval.ptable  = ptables[pmode]
   ENDIF


   
   ;; ##############################
   ;; ###    Telemetry Mode      ###
   ;; ##############################   
   IF isa(tmode) THEN BEGIN
      IF ~spi_param_dict.haskey('ptables') THEN $
       spi_param_dict.ttables = orderedhash()
      ptables = spi_param_dict.ttables
      IF ~ptables.haskey(tmode) THEN BEGIN
         dprint, 'Generating new product table ',pmode,dlevel=2
         CASE tmode OF
            '01'x:tcnf = param.tbl.cnf1
            '02'x:tcnf = param.tbl.cnf2
            '03'x:tcnf = param.tbl.cnf3
            '04'x:tcnf = param.tbl.cnf4
            '05'x:tcnf = param.tbl.cnf5
            '06'x:tcnf = param.tbl.cnf6
            '07'x:tcnf = param.tbl.cnf7
            '08'x:tcnf = param.tbl.cnf8
            ELSE:binmap = !null
         ENDCASE
         ttable = dictionary()
         ttable.tmode = tmode
         ttable.tcnf  = tcnf
      ENDIF
   ENDIF
   

   
   ;; ##############################
   ;; ###        Mass Mode       ###
   ;; ##############################   
   IF isa(mmode) THEN BEGIN
      retval.mtable = param.mas.mt1
   ENDIF
   
   
   
   IF n_elements(retval) EQ 0 THEN retval = spi_param_dict
   
   return,retval
   
END
