
FUNCTION esc_esatm_reader::esc_raw_header_struct,ptphdr


   raw_size = swap_endian(uint(ptphdr,0) ,/swap_if_little_endian )
   ptp_code = ptphdr[2]
   ptp_scid = swap_endian(/swap_if_little_endian, uint(ptphdr,3))

   days  = swap_endian(/swap_if_little_endian, uint(ptphdr,5))
   ms    = swap_endian(/swap_if_little_endian, ulong(ptphdr,7))
   us    = swap_endian(/swap_if_little_endian, uint(ptphdr,11))
   utime = (days-4383L) * 86400L + ms/1000d

   ;; Correct for error in pre 2015-3-1 files
   IF utime LT 1425168000 then utime += us/1d4
   ;; if keyword_set(time) then dt = utime-time  else dt = 0
   source = ptphdr[13]
   spare  = ptphdr[14]
   path   = swap_endian(/swap_if_little_endian, uint(ptphdr,15))
   ptp_header ={ptp_size:ptp_size, ptp_code:ptp_code, ptp_scid: ptp_scid, ptp_time:utime, ptp_source:source, ptp_spare:spare, ptp_path:path }
   return,ptp_header

END


function esc_esatm_reader::esc_data_select, buff, loc, n
   return, swfo_data_select(buff, loc, n)
end



pro esc_esatm_reader::read, buffer, source_dict=parent_dict ; this routine needs a lot of work - but it will work for common block files

   if n_elements(buffer) eq 206 then begin   
      if 0 then begin
         esc_raw_pkt_handler, buffer, source_dict=parent_dict
      endif else begin
         dprint,dwait = 5,dlevel=3,verbose=self.verbose,n_elements(buffer)
      endelse
   endif else begin
      ;dprint,'Wrong size', n_elements(buffer),dwait=10.
      ;return
   endelse
   
   self.decom_esctm,buffer,source_dict=parent_dict
end





pro esc_esatm_reader::decom_esctm, buffer, source_dict=parent_dict
   
   
   if isa(parent_dict,'dictionary') && parent_dict.haskey('cmbhdr') then begin
     cmbhdr = parent_dict.cmbhdr
     time   = cmbhdr.time 
     ;;size = cmbhdr.size  
   endif else time=0d
   

   dat = {  $
         time:     0d, $
         sync:     0u, $
         index :   0u, $
         tbd:      0b, $
         boardid:  0b, $
         fasthkp:  0b, $
         ion_diag: 0u, $
         size:     0u, $
         eanode:     uintarr(16), $
         ianode0:    uintarr(16), $
         ianode1:    uintarr(16), $
         ianode2:    uintarr(16), $
         ianode3:    uintarr(16), $
         ianode:     uintarr(16), $
         icnts:      long(0),     $
         mass_hist:  uintarr(16), $
         tof_hist:   uintarr(8),  $
         raw_events: uintarr(8),  $
         fast_rates: uintarr(9),  $
         ahkp:    0, $
         dhkp:    0, $
         user1:   0, $
         user2:   0, $
         gap:     0}
   
   

   index = self.esc_data_select(buffer,16+7, 9)

       
   ;; Kludge until time is decommed
   if index eq 0 then begin
      time0 = time              
      self.source_dict.time0 = time
   endif 
   
   if ~self.source_dict.haskey('TIME0') then begin
      ;self.source_dict.time0 = time
      return
   endif else begin
      time0 = self.source_dict.time0
   endelse

   time = time0 + index * 8.d/512

   dat.time     = time  ;; source_dict.time
   dat.sync     = self.esc_data_select(buffer,0,16)
   dat.tbd      = self.esc_data_select(buffer,16,   2)
   dat.boardid  = self.esc_data_select(buffer,16+2, 2)
   dat.fasthkp  = self.esc_data_select(buffer,16+4, 1)
   dat.ion_diag = self.esc_data_select(buffer,16+5, 2) 
   dat.index    = index
   dat.size     = self.esc_data_select(buffer,32, 16)
      
   if dat.size ne cmbhdr.size then dprint,'Size error: ',dat.size

   data2 = uint(buffer,6,(dat.size-6)/2 )
   byteorder,data2,/swap_if_little_endian
   dat.eanode    = data2[ 0:15]
   dat.ianode0   = data2[16:31]
   dat.ianode1   = data2[32:47]
   dat.ianode2   = data2[48:63]
   dat.ianode3   = data2[64:79]
   dat.ianode    = dat.ianode0 + $
                   dat.ianode1 + $
                   dat.ianode2 + $
                   dat.ianode3
   dat.icnts     = total(dat.ianode)
   dat.mass_hist = data2[80:95]
   dat.ahkp      = fix(data2[96])
   dat.dhkp      = data2[97]
   dat.user1     = data2[98]
   dat.user2     = data2[99]

   ;; Diagnostic Words (TOF/RAW/RATES)
   case dat.ion_diag of
     1:dat.fast_rates = data[100:108]
     2:dat.tof_hist   = data[100:107]
     3:dat.raw_events = data[100:107]
     else: break
   endcase 


   source_dict = self.source_dict


   ;; ------------------------------------------- ;;
   ;; ---------------- Full Message ------------- ;;
   ;; ------------------------------------------- ;;
   self.dat_da.append,  dat
    
    
    
   ;; ------------------------------------------- ;;
   ;; ---------- Electron Spectrogram ----------- ;;
   ;; ------------------------------------------- ;;
   n_espec = 512
   if source_dict.haskey('dat_espec') then begin
     dat_espec = source_dict.dat_espec
   endif else begin
     dat_espec = { $
       time: 0.d, $
       espec_raw:uintarr(16,n_espec), $
       gap:0 }
   endelse
   
   dat_espec.espec_raw[*,index] = dat.eanode
   source_dict.dat_espec = dat_espec
   
   ;; Append Electron Spectrograms
   if index eq 511 then begin
     espec = self.decom_espec(dat_espec.espec_raw)
     espec.time = time
     self.espec_da.append, espec
   endif



   ;; ------------------------------------------- ;;
   ;; ------------- Ion Spectrogram ------------- ;;
   ;; ------------------------------------------- ;;
   n_ispec = 512
   if source_dict.haskey('dat_ispec') then begin
     dat_ispec = source_dict.dat_ispec
   endif else begin
     dat_ispec = { $
       time: 0.d, $
       ispec_raw0:uintarr(16,n_ispec), $
       ispec_raw1:uintarr(16,n_ispec), $
       ispec_raw2:uintarr(16,n_ispec), $
       ispec_raw3:uintarr(16,n_ispec), $
       gap:0 }
   endelse

   dat_ispec.ispec_raw0[*,index] = dat.ianode0
   dat_ispec.ispec_raw1[*,index] = dat.ianode1
   dat_ispec.ispec_raw2[*,index] = dat.ianode2
   dat_ispec.ispec_raw3[*,index] = dat.ianode3

   source_dict.dat_ispec = dat_ispec

   ;; Append Ion Spectrograms
   if index eq 511 then begin
     ispec = self.decom_ispec(dat_ispec)
     ispec.time = time
     self.ispec_da.append, ispec
   endif



   ;; ------------------------------------------- ;;
   ;; -------------- Fast Housekeeping ---------- ;;
   ;; ------------------------------------------- ;;
   n_fhkp = 512
   if source_dict.haskey('dat_fhkp') then begin
     dat_fhkp = source_dict.dat_fhkp
   endif else begin
     dat_fhkp = { $
       time: 0.d, $
       fhkp_raw:uintarr(n_fhkp), $
       gap:0 }
   endelse
   
   ;; Fill temporary variable if FHKP is enabled
   if dat.fasthkp eq 1 then begin
     dat_fhkp.fhkp_raw[index] = dat.ahkp
     source_dict.dat_fhkp = dat_fhkp
     
     ;; Append FHKP
     if index mod 511 eq 0 then BEGIN
       dat_fhkp = self.decom_fhkp(dat_fhkp.fhkp_raw)
       dat_fhkp.time = time
       self.fhkp_da.append,  dat_fhkp
     endif
   endif



   ;; ------------------------------------------- ;;
   ;; ------------- Analog Housekeeping --------- ;;
   ;; ------------------------------------------- ;;   
   n_ahkp = 32
   if source_dict.haskey('dat_ahkp') then begin
      dat_ahkp=source_dict.dat_ahkp 
   endif else begin
      dat_ahkp = { $
                 time: 0d, $
                 ahkp_raw: replicate(!values.f_nan,n_ahkp), $
                 gap: 0  }  
      
   endelse
   
   ;; Fill temporary variable if AHKP is enabled
   if dat.fasthkp eq 0 then begin

     dat_ahkp.ahkp_raw[index mod n_ahkp] = dat.ahkp
     source_dict.dat_ahkp = dat_ahkp
   
     ;; Append AHKP 
     if (index mod n_ahkp) eq n_ahkp-1 then BEGIN
       ahkp = self.decom_ahkp(dat_ahkp.ahkp_raw)
       ahkp.time = time
       self.ahkp_da.append,  ahkp
     endif
   
   endif



   ;; ------------------------------------------- ;;
   ;; ------------ Digital Housekeeping --------- ;;
   ;; ------------------------------------------- ;;
   n_dhkp = 512
   if source_dict.haskey('dat_dhkp') then begin
      dat_dhkp=source_dict.dat_dhkp
   endif else begin
      dat_dhkp = { $
                 time: 0d, $
                 dhkp_raw: uintarr(n_dhkp), $
                 gap: 0  }

   endelse

   dat_dhkp.dhkp_raw[index mod n_dhkp] = dat.dhkp
   source_dict.dat_dhkp = dat_dhkp
   if (index mod n_dhkp) eq n_dhkp-1 then BEGIN 
      dhkp = self.decom_dhkp(dat_dhkp.dhkp_raw)
      dhkp.time = time
      self.dhkp_da.append,  dhkp
   endif



   ;; ------------------------------------------- ;;
   ;; --------------- Mass Histogram ------------ ;;
   ;; ------------------------------------------- ;;
   if source_dict.haskey('dat_mhist') then begin
     dat_mhist = source_dict.dat_mhist
   endif else begin
     dat_mhist = { $
       time: 0d, $
       mhist_raw: uintarr(16,512), $
       gap: 0  }
   endelse


   dat_mhist.mhist_raw[*,index] = dat.mass_hist
   source_dict.dat_mhist = dat_mhist

   ;; Append Mass Histogram
   if index eq 3 then BEGIN

     mhist = self.decom_mhist(dat_mhist.mhist_raw)
     mhist.time = time
     self.mhist_da.append,  mhist

   endif
   


   ;; ------------------------------------------- ;;
   ;; --------- Diagnostic: Fast Rates ---------- ;;
   ;; ------------------------------------------- ;;
   if dat.ion_diag eq 1 then begin 

     if source_dict.haskey('dat_frates') then begin
       dat_frates = source_dict.dat_frates
     endif else begin
       dat_frates = { $
         time: 0d, $
         frates_raw: uintarr(9,512), $
         gap: 0  }
     endelse

   
     dat_frates.frates_raw[*,index] = dat.fast_rates
     source_dict.dat_frates = dat_frates

     ;; Append Fast Rates Diagnostic Product
     if index eq 511 then BEGIN

       frates = self.decom_mhist(dat_frates.frates_raw)
       frates.time = time
       ;;self.frates_da.append,  frates

     endif
     
   endif
   
      
   ;; ------------------------------------------- ;;
   ;; ------- Diagnostic: TOF Histogram --------- ;;
   ;; ------------------------------------------- ;;
   if dat.ion_diag eq 2 then begin

     if source_dict.haskey('dat_tof_hist') then begin
       dat_tof_hist = source_dict.dat_tof_hist
     endif else begin
       dat_tof_hist = { $
         time: 0d, $
         tof_hist_raw: uintarr(8,32), $
         gap: 0  }
     endelse
  
  
     dat_tof_hist.tof_hist_raw[*,index] = dat.tof_hist
     ;;source_dict.dat_tof_hist = dat_tof_hist
  
     ;; Append Fast Rates Diagnostic Product
     if index eq 31  and dat.ion_diag eq 2 then BEGIN
  
       thist = self.decom_thist(dat_tof_hist.tof_hist_raw)
       thist.time = time
       ;;self.tof_hist_da.append,  thist
  
     endif   
   
   endif   

   ;; ------------------------------------------- ;;
   ;; --------- Diagnostic: Raw Events ---------- ;;
   ;; ------------------------------------------- ;;
   if dat.ion_diag eq 3 then begin

     if source_dict.haskey('dat_raw_events') then begin
       dat_raw_events = source_dict.dat_raw_events
     endif else begin
       dat_raw_events = { $
         time: 0d, $
         raw_events_raw: uintarr(8,512), $
         gap: 0  }
     endelse
  
  
     dat_raw_events.raw_events_raw[*,index] = dat.raw_events
     ;;source_dict.dat_raw_events = dat_raw_events
  
     ;; Append Fast Rates Diagnostic Product
     if index eq 511  and dat.ion_diag eq 3 then BEGIN
  
       raw_events = self.decom_mhist(dat_raw_events.raw_events_raw)
       raw_events.time = time
       ;;self.raw_events_da.append,  raw_events
  
     endif
   
   endif

   if debug(3,self.verbose) && dat.index eq 23 then begin
      printdat,source_dict
      printdat,dat
      hexprint,buffer
      ;;printdat,source_dict
      dprint
      ;;store_data,'esc_raw_',data=dat,/append,tagnames='*',time_tag='time',verbose=2
      ;; printdat,source_dict.time
   endif
   
   if debug(4,self.verbose) then begin
      hexprint,buffer
   endif

end



function esc_esatm_reader::decom_ispec, str

  m1  = reform(str.ispec_raw0,16,8,64)
  m2  = reform(str.ispec_raw1,16,8,64)
  m3  = reform(str.ispec_raw2,16,8,64)
  m4  = reform(str.ispec_raw3,16,8,64)
  tot = m1+m2+m3+m4
  
  ispec = { $
           
           ;; Mass 1
           ANO_M1_SPEC:total(total(m1,2),2), $
           NRG_M1_SPEC:total(total(m1,1),1), $
           DEF_M1_SPEC:total(total(m1,1),2), $
           
           ;; Mass 2
           ANO_M2_SPEC:total(total(m2,2),2), $
           NRG_M2_SPEC:total(total(m2,1),1), $
           DEF_M2_SPEC:total(total(m2,1),2), $
           
           ;; Mass 3
           ANO_M3_SPEC:total(total(m3,2),2), $
           NRG_M3_SPEC:total(total(m3,1),1), $
           DEF_M3_SPEC:total(total(m3,1),2), $
           
           ;; Mass 4
           ANO_M4_SPEC:total(total(m4,2),2), $
           NRG_M4_SPEC:total(total(m4,1),1), $
           DEF_M4_SPEC:total(total(m4,1),2), $
           
           ;; Summed Masses
           ANO_SPEC:total(total(tot,2),2), $
           NRG_SPEC:total(total(tot,1),1), $
           DEF_SPEC:total(total(tot,1),2), $
           
           time:0.D, gap:0}

  return, ispec

end



function esc_esatm_reader::decom_espec, arr

   arr = reform(arr,16,8,64)
   espec = {ANO_SPEC:total(total(arr,2),2), $
            NRG_SPEC:total(total(arr,1),1), $
            DEF_SPEC:total(total(arr,1),2), $
            time:0.D, gap:0}
      
   return, espec

end



function esc_esatm_reader::decom_mhist, arr

  arr = total(reform(reform(arr,16,4,128),64,64,2),3)
  mhist = {M_SPEC:total(arr,2), $
           E_SPEC:total(arr,1), $
           time:0.D, gap:0}

  return, mhist

end



FUNCTION esc_esatm_reader::decom_fhkp, arr

   str_fhkp = {fhkp:arr, time:0.D, gap:0}
  
   return, str_fhkp

end


FUNCTION esc_esatm_reader::decom_ahkp, arr
   
   ;; Create Words from ByteArray
   wd = float(arr)
   
   ;; Check that int_arr is the correct size
   IF n_elements(arr) NE 32 THEN stop, 'Wrong ahkp packet size.' 
   
   ;; Polynomial Constants
   
   ;; Temperature 6 polynomial constants
   pc = [137.01, -0.15828, 0.00011978, -5.4877e-8, 1.2712e-11, -1.179e-15]
   
   ;; Analog Housekeeping
   str_ahkp = {imcpv:wd[0]      * 4*1000./(0.787+0.392)/4095.,  $
               idef1v:wd[1]     * 4*1001./4095.,                $
               emcpv:wd[2]      * 4*1001.33/1.33/4095.,         $
               edef1v:wd[3]     * 4*1001./4095.,                $ 
               imcpi:wd[4]      * 4/4095./0.0492,               $
               idef2v:wd[5]     * 4*1001./4095.,                $
               emcpi:wd[6]      * 4/4095.*25.,                  $
               edef2v:wd[7]     * 4*1001./4095.,                $
               irawv:wd[8]      * 4*1000.787/0.787/4095,        $
               ispoilerv:wd[9]  * 4*1052.3/52.3/4095,           $
               erawv:wd[10]     * 4*1000.787/0.787/4095,        $
               espoilerv:wd[11] * 4*1052.3/52.3/4095.,          $
               irawi:wd[12]     * 4/4095.*25,                   $      
               ihemiv:wd[13]    * 4*1001./4095,                 $
               erawi:wd[14]     * 4/4095.*25.,                  $
               ehemiv:wd[15]    * 4*500/4095.,                  $
               iaccelv:wd[16]   * 4*10000./(1.3+1.37)/4095.,    $
               p8v:wd[17]       * 4*3./4095.,                   $
               p1_5v:wd[18]     * 4/4095.,                      $ 
               p5vi:wd[19]      * 4/(4096*0.00801)+(-3.72/8.01),$
               iacceli:wd[20]   * 4./4095./0.13,                $
               p5v:wd[21]       * 4*2/4095.,                    $
               p1_5vi:wd[22]    * 4/(4095*0.001),               $
               n5vi:wd[23]      * 4/(4096*0.00801)+(-3.72/8.01),$
               ianalt: pc[0] + $
                       pc[1] * wd[24]   + pc[2] * wd[24]^2 +  $
                       pc[3] * wd[24]^3 + pc[4] * wd[24]^4 +  $
                       pc[5] * wd[24]^5,                      $
               n5v:wd[25]       * 4*2/4095.,                  $
               digitalt:pc[0] + $
                        pc[1] * wd[26]   + pc[2] * wd[26]^2 + $
                        pc[3] * wd[26]^3 + pc[4] * wd[26]^4 + $
                        pc[5] * wd[26]^5,                     $
               p8vi:wd[27]      * 4/(4095*0.005),             $
               eanalt:pc[0] + $
                      pc[1] * wd[28]   + pc[2] * wd[28]^2 +   $
                      pc[3] * wd[28]^3 + pc[4] * wd[28]^4 +   $
                      pc[5] * wd[28]^5,                       $
               n8v:wd[29]       * (4*20/6.8)/4095,            $
               eanodet:pc[0] + $
                       pc[1] * wd[30]   + pc[2] * wd[30]^2 +  $
                       pc[3] * wd[30]^3 + pc[4] * wd[30]^4 +  $
                       pc[5] * wd[30]^5,                      $
               n8vi:wd[31]      * 1.221,                      $ 
               time:0.D,$
               gap:0}

   return, str_ahkp

END



FUNCTION esc_esatm_reader::decom_dhkp, arr

   ;; Check that arr is the correct size
   IF n_elements(arr) NE 512 AND n_elements(arr) NE 1024 THEN $
    stop, 'Wrong dhkp packet size.'   

   ;; If there are 1024 elements then it's a byte array
   IF n_elements(arr) EQ 1024 THEN BEGIN
      ;; Word Array
      wd = uint(swap_endian(arr, /swap_IF_little_endian), 0, 512)
      ;; Byte Array
      bt = arr
   ENDIF 

   ;; If there are 512 elements then it is a word array
   IF n_elements(arr) EQ 512 THEN BEGIN
      ;; Word Array
      wd = arr
      ;; Byte Array
      bt = byte(swap_endian(arr,/swap_IF_little_endian),0,1024)
   ENDIF 
   

   ;; Digital Housekeeping
   str_dhkp = {cmds_received:  wd[0], $
               cmd_errors:     bt[2], $
               cmd_unknown:    bt[3], $
               fgpa_rev:       wd[2], $
               mode_id:        wd[3], $
               i_hv_mode:      self.esc_data_select(bt[8],4,4),   $
               e_hv_mode:      self.esc_data_select(bt[8],0,4),   $
               hv_key_enabled: self.esc_data_select(bt[9],7,1),   $
               hv_enabled:     self.esc_data_select(bt[9],6,1),   $
               board_id:       wd[5], $

               reset_cnt:wd[6],        ihemi_cdi:wd[7],       ispoiler_cdi:wd[8], $
               idef1_cdi:wd[9],        idef2_cdi:wd[10],       imcp:wd[11], $
               iraw_hv:wd[12],          iaccel:wd[13],          ehemi_cdi:wd[14],$
               espoiler_cdi:wd[15],     edef1_cdi:wd[16],       edef2_cdi:wd[17], $
               emcp:wd[18],             eraw_hv:wd[19],         ihemi_addr:wd[20],$
               ispoiler_addr:wd[21],    idef1_addr:wd[22],      idef2_addr:wd[23], $
               ehemi_addr:wd[24],       espoiler_addr:wd[25],   edef1_addr:wd[26], $
               edef2_addr:wd[27],       mlut_addr:wd[28],       mlimit_addr:wd[29], $
               dump_addr:wd[30],        cmd_check_addr:wd[31],  $

               ;itp_step_mode:  self.esc_data_select(bt[64],0,1),$
               ;tof_tp_mode:    self.esc_data_select(bt[64],1,1),$
               ;;test_pulser_ena:self.esc_data_select(bt[64],2,1),$
               ;dll_pulser_mode:self.esc_data_select(bt[64],3,1),$
               ;ext_pulser_mode:self.esc_data_select(bt[64],4,1),$
               ;dll1_select:    self.esc_data_select(bt[64],5,2),$
               ;dll2_select:    ishft(self.esc_data_select(bt[64],7,1),2) AND $
               ;                      self.esc_data_select(bt[65],0,2),$
               ;dll_stop_ena:   self.esc_data_select(bt[66],0,4), $
               ;dll_start_ena:  self.esc_data_select(bt[66],4,8), $
               ;dll_start_tp:   self.esc_data_select(bt[66],0,4), $
               ;dll_stop_tp:    self.esc_data_select(bt[66],4,8), $

               easic_dout:wd[34],$

               act_open_stat:  self.esc_data_select(bt[70],3,1),$
               act_close_stat: self.esc_data_select(bt[70],7,1),$
               ecover_stat:    self.esc_data_select(bt[71],3,1),$
               icover_stat:    self.esc_data_select(bt[71],7,1),$
               last_actuation: self.esc_data_select(bt[71],5,3),$
               act_err:        ishft(self.esc_data_select(bt[71],3,5),5) AND $
                                     self.esc_data_select(bt[72],0,3),$
               act_override:   self.esc_data_select(bt[72],3,4),$

               act_timeout_cvr:wd[37],  act_timeout_atn:wd[38], actuation_time:wd[39], $
               active_time:wd[40],      act_cooltime:wd[41], $
               
               ch_offset_0:wd[42], ch_offset_1:wd[43], ch_offset_2:wd[44], ch_offset_3:wd[45],  $
               ch_offset_4:wd[46], ch_offset_5:wd[47], ch_offset_6:wd[48], ch_offset_7:wd[49],  $
               ch_offset_8:wd[50], ch_offset_9:wd[51], ch_offset_10:wd[52],ch_offset_11:wd[53], $
               ch_offset_12:wd[54],ch_offset_13:wd[55],ch_offset_14:wd[56],ch_offset_15:wd[57], $
               
               ;raw_events_ena: self.esc_data_select(bt[116],0,1),$
               ;raw_events_mode:self.esc_data_select(bt[116],1,1),$
               ;raw_events_chan:self.esc_data_select(bt[116],2,4),$
               
               raw_channel_mask:wd[59], raw_min_tof_val:wd[60], mhist_chan_mask:wd[61], $

               ;tof_hist_ena:   self.esc_data_select(bt[124],0,1),$
               ;accum_rates_ena:self.esc_data_select(bt[124],1,1),$
               ;accum_rates1:   self.esc_data_select(bt[124],2,4),$
               ;accum_rates2:   ishft(self.esc_data_select(bt[124],6,2),2) AND $
               ;                      self.esc_data_select(bt[125],0,2), $
               ;accum_rates3:   self.esc_data_select(bt[125],2,4),$
               ;fast_hkp_ena:   self.esc_data_select(bt[126],0,1),$
               ;fast_hkp_chan:  self.esc_data_select(bt[126],1,5),$
               
               valids:wd[64:79],$
               valids_hz:wd[64:79]/8.,$
                
               ;valid_0:wd[64], valid_1:wd[65], valid_2:wd[66], valid_3:wd[67],$
               ;valid_4:wd[68], valid_5:wd[69], valid_6:wd[70], valid_7:wd[71],$
               ;valid_8:wd[72], valid_9:wd[73], valid_10:wd[74],valid_11:wd[75],$
               ;valid_12:wd[76],valid_13:wd[77],valid_14:wd[78],valid_15:wd[79],$

               non_valids:wd[80:95],$
               non_valids_hz:wd[80:95]/8.,$
               ;non_valid_0:wd[80], non_valid_1:wd[81], non_valid_2:wd[82], non_valid_3:wd[83],$
               ;non_valid_4:wd[84], non_valid_5:wd[85], non_valid_6:wd[86], non_valid_7:wd[87],$
               ;non_valid_8:wd[88], non_valid_9:wd[89], non_valid_10:wd[90],non_valid_11:wd[91],$
               ;non_valid_12:wd[92],non_valid_13:wd[93],non_valid_14:wd[94],non_valid_15:wd[95],$
               
               start_no_stops:wd[[96,96,97,97,98,98,99,99,100,100,[101:106]]], $
               start_no_stops_hz:wd[[96,96,97,97,98,98,99,99,100,100,[101:106]]]/8.,$ 
                
               ;start_no_stop_0_1:wd[96], start_no_stop_2_3:wd[97], start_no_stop_4_5:wd[98], start_no_stop_6_7:wd[99],$
               ;start_no_stop_8_9:wd[100], start_no_stop_10:wd[101],start_no_stop_11:wd[102],$
               ;start_no_stop_12:wd[103],  start_no_stop_13:wd[104],start_no_stop_14:wd[105],start_no_stop_15:wd[106],$
               
               emptyrate1:wd[107], $
               
               stop_no_starts:wd[108:123],$
               stop_no_starts_hz:wd[108:123]/8.,$ 
                
               ;stop_no_start_0:wd[108], stop_no_start_1:wd[109], stop_no_start_2:wd[110], stop_no_start_3:wd[111],$
               ;stop_no_start_4:wd[112], stop_no_start_5:wd[113], stop_no_start_6:wd[114], stop_no_start_7:wd[115],$
               ;stop_no_start_8:wd[116], stop_no_start_9:wd[117], stop_no_start_10:wd[118],stop_no_start_11:wd[119],$
               ;stop_no_start_12:wd[120],stop_no_start_13:wd[121],stop_no_start_14:wd[122],stop_no_start_15:wd[123],$
               
               starts:wd[[124,124,125,125,126,126,127,127,128,128,[129:134]]], $
               starts_hz:wd[[124,124,125,125,126,126,127,127,128,128,[129:134]]]/8., $
                
               ;start_0_1:wd[124], start_2_3:wd[125], start_4_5:wd[126], start_6_7:wd[127],$
               ;start_8_9:wd[128], start_10:wd[129],  start_11:wd[130],$
               ;start_12:wd[131],  start_13:wd[132],  start_14:wd[133],start_15:wd[134],$
               
               stops:wd[135:150],$
               stops_hz:wd[135:150]/8.,$ 
                
               ;stop_0:wd[135], stop_1:wd[136], stop_2:wd[137], stop_3:wd[138],$
               ;stop_4:wd[139], stop_5:wd[140], stop_6:wd[141], stop_7:wd[142],$
               ;stop_8:wd[143], stop_9:wd[144], stop_10:wd[145],stop_11:wd[146],$
               ;stop_12:wd[147],stop_13:wd[148],stop_14:wd[149],stop_15:wd[150],$
               
               emptyrate2:wd[151], $
               
               ihemi_checksum:wd[152],   ispoiler_checksum:wd[153], idef1_checksum:wd[154], $
               idef2_checksum:wd[155],   ehemi_checksum:wd[156],  espoiler_checksum:wd[157], $
               edef1_checksum:wd[158],   edef2_checksum:wd[159],  mlut_checksum:wd[160], $
               mlimit_checksum:wd[161],  cmded_checksum:wd[162],  thist_chan_mask:wd[163], $
               thist_stepmin:wd[164],    thist_stepmax:wd[165],   $
                                     
               ;cal_disable:self.esc_data_select(bt[232],0,4),    $
               ;read_nonVE:self.esc_data_select(bt[232],4,4),     $
               ;cal_clk_period:self.esc_data_select(bt[233],0,4), $
               ;compress_tof:self.esc_data_select(bt[233],4,4),   $
               
               cal_clk_pause:wd[167], mram_write_addr_hi:wd[168], mram_write_addr_lo:wd[169], $
               sweep_count:wd[170], pps_count:wd[171],        last_command:wd[172],    last_command_data:wd[173], $
               sweep_utc_hi:wd[174], sweep_utc_lo:wd[175], $

               cfd_setting_0:wd[176], cfd_setting_1:wd[177], cfd_setting_2:wd[178], cfd_setting_3:wd[179],$
               cfd_setting_4:wd[180], cfd_setting_5:wd[181], cfd_setting_6:wd[182], cfd_setting_7:wd[183],$
               cfd_setting_8:wd[184], cfd_setting_9:wd[185], cfd_setting_10:wd[186],cfd_setting_11:wd[187],$
               cfd_setting_12:wd[188],cfd_setting_13:wd[189],cfd_setting_14:wd[190],cfd_setting_15:wd[191],$
               cfd_setting_16:wd[192], cfd_setting_17:wd[193], cfd_setting_18:wd[194], cfd_setting_19:wd[195],$
               cfd_setting_20:wd[196], cfd_setting_21:wd[197], cfd_setting_22:wd[198], cfd_setting_23:wd[199],$
               cfd_setting_24:wd[200], cfd_setting_25:wd[201], cfd_setting_26:wd[202],$
               
               easic_ch_0:wd[203], easic_ch_1:wd[204], easic_ch_2:wd[205], easic_ch_3:wd[206],$
               easic_ch_4:wd[207], easic_ch_5:wd[208], easic_ch_6:wd[209], easic_ch_7:wd[210],$
               easic_ch_8:wd[211], easic_ch_9:wd[212], easic_ch_10:wd[213],easic_ch_11:wd[214],$
               easic_ch_12:wd[215],easic_ch_13:wd[216],easic_ch_14:wd[217],easic_ch_15:wd[218],$
               
               ehemi_delta:bt[438],$
               ehemi_deadtime:bt[439],$

               easic_stim:wd[220],   iesa_tp_hv_step:wd[221], $

               ;eidpu_fsm_err:self.esc_data_select(bt[444], 0,4),$
               ;mram_fsm_err: self.esc_data_select(bt[444], 4,4),$
               ;tof_fsm_err:  self.esc_data_select(bt[445], 0,4),$
               ;tlm_fsm_err:  self.esc_data_select(bt[445], 4,4),$
               
               ;hv_fsm_err:      self.esc_data_select(bt[446], 0,4),$
               ;actuator_fsm_err:self.esc_data_select(bt[446], 4,4),$
               ;rates_fsm_err:   self.esc_data_select(bt[447], 0,4),$
               ;raw_fsm_err:     self.esc_data_select(bt[447], 4,4),$
               
               ;adc_fsm_err:  self.esc_data_select(bt[448], 0,4),$
               ;cfd_fsm_err:  self.esc_data_select(bt[448], 4,4),$
               ;ions_fsm_err: self.esc_data_select(bt[449], 0,4),$
               
               ;tof_mem_err:      self.esc_data_select(bt[450], 0,4),$
               ;icounters_mem_err:self.esc_data_select(bt[450], 4,4),$
               ;mlut_mem_err:     self.esc_data_select(bt[451], 0,4),$
               ;rates_mem_err:    self.esc_data_select(bt[451], 4,4),$
               
               ;raw_mem_err:      self.esc_data_select(bt[452], 0,4),$
               ;mhist_mem_err:    self.esc_data_select(bt[452], 4,4),$
               eesa_retrace_timeout:wd[227], $
               tof_offset:wd[228],$
               iesa_test_val:wd[229],$
               eesa_test_val:wd[230],$
               
               mram_write_addr:0.D, time:0.d, gap:0}

   return, str_dhkp

END



function esc_esatm_reader::decom_tof_hist, arr

  thist = {TOF_HIST:arr, $
           time:0.D, gap:0}

  return, thist

end



PRO esc_esatm_reader::esc_raw_lun_read, buffer, source_dict=source_dict

   ;; Size of RAW EESA_FRAMES
   header_size = 6

   ;; Initial buffer to search for SYNC
   buf = bytarr(header_size)

   ;;dwait = 10.
   ;;printdat,info
;  IF isa(source_dict,'DICTIONARY') EQ 0 THEN begin
;    dprint,dlevel=3,'Creating source_dict'
;    ;printdat,info
;    source_dict = dictionary()
;  ENDIF

   on_ioerror, nextfile
   time = systime(1)
   info.time_received = time
   msg = time_string(info.time_received,tformat='hh:mm:ss -',local=localtime)
   ;;in_lun = info.hfp
   out_lun = info.dfp
   remainder = !null
   nbytes = 0UL
   run_proc = struct_value(info,'run_proc',default=1)
   fst = fstat(in_lun)
   ;; esc_apdat_info,current_filename= fst.name
   source_dict.source_info = info

   WHILE file_poll_input(in_lun,timeout=0) && ~eof(in_lun) DO BEGIN

      readu,in_lun,buf,transfer_count=nb
      nbytes += nb
      raw_buf = [remainder,buf]

      ;; Lost Sync
      ;; Read one byte at a time
      IF (raw_buf[0] NE '54'x) || (raw_buf[1] NE '4D'x) THEN BEGIN
         remainder = raw_buf[1:*]
         dprint, 'sync error',dlevel=2,dwait = 5.
         CONTINUE
      ENDIF


      ;; Message ID Contents
      index = self.esc_data_select(raw_buf,16+7, 9)
      tr    = self.esc_data_select(raw_buf,16+25, 2) ; probably not correct
      fh    = self.esc_data_select(raw_buf,16+27, 1) ; probably not correct
      dprint,index,tr,fh,dlevel = 3

                                ; print,index

      ;; Packet Size
      size  = self.esc_data_select(raw_buf,32,16)

      ;; Raw Header Structure
      raw_header = {index:index, tr:tr, fh:fh, size:size}
      source_dict.raw_header = raw_header

      ;; Read in Data
      dat_buf = bytarr(size - header_size)
      readu, in_lun, dat_buf,transfer_count=nb
      nbytes += nb

      ;; Original version
      ;;esc_raw_data_decom, [raw_buf, dat_buf], source_dict=source_dict

      ;; Kludged new version
      stop
      esc_raw_pkt_handler, [raw_buf, dat_buf]

      ;; Debugging
      ;; fst = fstat(in_lun)
      ;; IF debug(2) && fst.cur_ptr NE 0 && fst.size NE 0 then begin
      ;;    dprint,dwait=dwait,dlevel=2,fst.compress ? '(Compressed) ' : '','File percentage: ' ,$
      ;;           (fst.cur_ptr*100.)/fst.size
      ;; ENDIF

      ;; Check whether binary block was read correctly
      IF nb NE size-header_size THEN BEGIN
         fst = fstat(in_lun)
         dprint,'File read error. Aborting @ ',fst.cur_ptr,' bytes'
         BREAK
      ENDIF

      ;; Debugging
      ;; IF debug(5) THEN BEGIN
      ;;    hexprint,dlevel=3,ccsds_buf,nbytes=32
      ;; ENDIF

      ;; Load packet into apdat object
                                ;esc_raw_pkt_handler, dat_buf, source_dict=source_dict
                                ;printdat,source_dict

                                ;hexprint,dat_buf


      ;; Reset buffer to header size
      buf = bytarr(header_size)
      remainder=!null

   ENDWHILE

   flush,out_lun

   if 1 then begin
      
      if nbytes ne 0 then msg += string(/print,nbytes,([raw_buf])[0:(nbytes < n_elements(raw_buf))-1],format='(i6 ," bytes: ", 128(" ",Z02))')  $
      else msg+= ' No data available'

      dprint,dlevel=3,msg
      info.msg = msg
   endif

   dprint,info,dlevel=3,phelp=2

   IF 0 THEN BEGIN
      nextfile:
      dprint,!error_state.msg
      dprint,'Skipping file'
   ENDIF

   ;;IF ~keyword_set(no_sum) THEN BEGIN
   ;;   if keyword_set(info.last_time) then begin
   ;;      dt = time - info.last_time
   ;;      info.total_bytes += nbytes
   ;;      if dt gt .1 then begin
   ;;         rate = info.total_bytes/dt
   ;;         store_data,'PTP_DATA_RATE',append=1,time, rate,dlimit={psym:-4}
   ;;         info.total_bytes =0
   ;;         info.last_time = time
   ;;      endif
   ;;   endif else begin
   ;;      info.last_time = time
   ;;      info.total_bytes = 0
   ;;   endelse
   ;;endif


   ;;if nbytes ne 0 then msg += string(/print,nbytes,([ptp_buf,ccsds_buf])[0:(nbytes < 32)-1],format='(i6 ," bytes: ", 128(" ",Z02))')  $
   ;;else msg+= ' No data available'

   ;;dprint,dlevel=5,msg
   ;;info.msg = msg

   ;;dprint,dlevel=2,'Compression: ',float(fp)/fi.size

END



function esc_esatm_reader::init,_extra=ex,tplot_tagnames=tplot_tagnames
   void = self.socket_reader::init(_extra=ex)
   if ~isa(tplot_tagnames,'string') then tplot_tagnames='*'
   self.dat_da   = dynamicarray(name='esc_dat',tplot_tagnames=tplot_tagnames)
   self.ahkp_da   = dynamicarray(name='esc_ahkp',tplot_tagnames=tplot_tagnames)
   self.dhkp_da   = dynamicarray(name='esc_dhkp',tplot_tagnames=tplot_tagnames)
   self.fhkp_da   = dynamicarray(name='esc_fhkp',tplot_tagnames=tplot_tagnames)
   self.espec_da  = dynamicarray(name='esc_espec',tplot_tagnames=tplot_tagnames)
   self.ispec_da  = dynamicarray(name='esc_ispec',tplot_tagnames=tplot_tagnames)
   self.mhist_da  = dynamicarray(name='esc_mhist',tplot_tagnames=tplot_tagnames)
   self.thspec_da = dynamicarray(name='esc_thspec',tplot_tagnames=tplot_tagnames)
   return,1
end



pro esc_esatm_reader__define
   void = {esc_esatm_reader, $
           inherits socket_reader, $  ; superclass
           dat_da: obj_new(),    $    ; EESA Raw Message Header
           ahkp_da: obj_new(),   $    ; dynamicarray for analog HKP
           dhkp_da: obj_new(),   $    ; dynamicarray for digital HKP
           fhkp_da: obj_new(),   $    ; dynamicarray for fast HKP
           espec_da:  obj_new(), $
           ispec_da:  obj_new(), $
           mhist_da:  obj_new(), $
           thspec_da: obj_new(), $
           flag: 0  $
          }
end








;; old code
;;nsamples = 64
;;dat_accum = { $
;;            time: 0d,  $
;;            eanode:    uintarr(16,nsamples), $
;;            ianode0:   uintarr(16,nsamples), $
;;            ianode1:   uintarr(16,nsamples), $
;;            ianode2:   uintarr(16,nsamples), $
;;            ianode3:   uintarr(16,nsamples), $
;;            mass_hist: uintarr(16,nsamples), $
;;            ahkp:      uintarr(nsamples), $
;;            dhkp:      uintarr(nsamples),  $
;;            fhkp:      uintarr(nsamples),  $
;;            rates :    uintarr(18,nsamples), $
;;            gap: 0  }
;;if isa(self.dyndata,'dynamicarray') then self.dyndata.append, dat


