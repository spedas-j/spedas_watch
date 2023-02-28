; $LastChangedBy: rlivi04 $
; $LastChangedDate: 2023-02-27 13:07:51 -0800 (Mon, 27 Feb 2023) $
; $LastChangedRevision: 31560 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/escapade/esa/common/esc_raw_pkt__define.pro $

;; Analog Housekeeping
PRO esc_raw_pkt::ahkp_decom, index, word

   ;; Find digital housekeeping value
   index1 = index MOD 32

   ;; Get polynomial based off of index
   pol = self.ahkp_poly[index1,*]

   ;; Apply polynomial to Analog Housekeeping
   word = double(word)
   IF index1 EQ 30 OR index1 EQ 28 OR index1 EQ 26 OR index1 EQ 24 THEN $
    val = pol[0] + word * pol[1] + word^2 *pol[2] + word^3*pol[3] + word^4*pol[4] + word^5*pol[5] $
   ELSE IF index1 EQ 19 OR index1 EQ 23 OR index1 EQ 27 OR index1 EQ 31 THEN $
    val = pol[0] + word * pol[1] $
   ELSE val = word * pol[1]

   ;; Insert into structure
   (*self.ahkp_last).(index1) = val 

END

;; Digital Housekeeping
PRO esc_raw_pkt::dhkp_decom, index, word

   ;; Decommutate Word
   CASE index OF
      1: BEGIN
         (*self.dhkp_last).(1) = isfht(word,-8)
         (*self.dhkp_last).(2) = word AND 'ff'x       
      END
      4: BEGIN
         (*self.dhkp_last).(5) = isfht(word, -4) AND 'f'x
         (*self.dhkp_last).(6) = ishft(word, -8) AND 'f'x
         (*self.dhkp_last).(7) = ishft(word,-14) AND '1'x
         (*self.dhkp_last).(8) = ishft(word,-15) AND '1'x
      END
      32: BEGIN
         (*self.dhkp_last).(36) = isfht(word, -5) AND '1'x
         (*self.dhkp_last).(37) = ishft(word, -6) AND '1'x
         (*self.dhkp_last).(38) = ishft(word, -7) AND '1'x
         (*self.dhkp_last).(39) = ishft(word, -8) AND '1'x
         (*self.dhkp_last).(40) = ishft(word, -9) AND '1'x
         (*self.dhkp_last).(41) = ishft(word,-10) AND '2'x
         (*self.dhkp_last).(42) = ishft(word,-12) AND '3'x
      END
      33: BEGIN
         (*self.dhkp_last).(5) = isfht(word,  0) AND 'f'x
         (*self.dhkp_last).(6) = ishft(word, -4) AND 'f'x
         (*self.dhkp_last).(7) = ishft(word, -8) AND 'f'x
         (*self.dhkp_last).(8) = ishft(word,-12) AND 'f'x
      END
      35: BEGIN
         (*self.dhkp_last).(5) = isfht(word, -12) AND '1'x
         (*self.dhkp_last).(6) = ishft(word, -13) AND '1'x
         (*self.dhkp_last).(7) = ishft(word, -14) AND '1'x
         (*self.dhkp_last).(8) = ishft(word, -15) AND '1'x
      END
      36: BEGIN
         (*self.dhkp_last).(6) = ishft(word,  -1) AND '3'x
         (*self.dhkp_last).(7) = ishft(word,  -4) AND 'f'x
         (*self.dhkp_last).(8) = ishft(word, -12) AND '4'x
      END
      58: BEGIN
         (*self.dhkp_last).(6) = ishft(word, -10) AND '1'x
         (*self.dhkp_last).(7) = ishft(word, -11) AND '1'x
         (*self.dhkp_last).(8) = ishft(word, -12) AND '4'x
      END
      62: BEGIN
         (*self.dhkp_last).(5) = isfht(word,  -2) AND '1'x
         (*self.dhkp_last).(5) = isfht(word,  -3) AND '1'x
         (*self.dhkp_last).(6) = ishft(word,  -4) AND '4'x
         (*self.dhkp_last).(7) = ishft(word,  -8) AND '4'x
         (*self.dhkp_last).(8) = ishft(word, -12) AND '4'x
      END
      63: BEGIN
         (*self.dhkp_last).(7) = ishft(word, -10) AND '1'x
         (*self.dhkp_last).(8) = ishft(word, -11) AND '5'x
      END
      166: BEGIN
         (*self.dhkp_last).(6) = ishft(word,   0) AND '4'x
         (*self.dhkp_last).(6) = ishft(word,  -4) AND '4'x
         (*self.dhkp_last).(7) = ishft(word,  -8) AND '4'x
         (*self.dhkp_last).(8) = ishft(word, -12) AND '4'x
      END
      217: BEGIN
         (*self.dhkp_last).(245) = ishft(word,   0) AND '8'x
         (*self.dhkp_last).(246) = ishft(word,  -8) AND '8'x
      END
      220: BEGIN
         (*self.dhkp_last).(249) = ishft(word,   0) AND '4'x
         (*self.dhkp_last).(250) = ishft(word,  -4) AND '4'x
         (*self.dhkp_last).(251) = ishft(word,  -8) AND '4'x
         (*self.dhkp_last).(252) = ishft(word, -12) AND '4'x
      END
      221: BEGIN
         (*self.dhkp_last).(253) = ishft(word,   0) AND '4'x
         (*self.dhkp_last).(254) = ishft(word,  -4) AND '4'x
         (*self.dhkp_last).(255) = ishft(word,  -8) AND '4'x
         (*self.dhkp_last).(256) = ishft(word, -12) AND '4'x
      END
      222: BEGIN
         (*self.dhkp_last).(257) = ishft(word,  -4) AND '4'x
         (*self.dhkp_last).(258) = ishft(word,  -8) AND '4'x
         (*self.dhkp_last).(259) = ishft(word, -12) AND '4'x
      END
      223: BEGIN
         (*self.dhkp_last).(260) = ishft(word,   0) AND '4'x
         (*self.dhkp_last).(261) = ishft(word,  -4) AND '4'x
         (*self.dhkp_last).(262) = ishft(word,  -8) AND '4'x
         (*self.dhkp_last).(263) = ishft(word, -12) AND '4'x
      END
      224: BEGIN
         (*self.dhkp_last).(264) = ishft(word,  -8) AND '4'x
         (*self.dhkp_last).(265) = ishft(word, -12) AND '4'x
      END
      ELSE: (*self.dhkp_last).(index) = word
   ENDCASE
   
   ;; Insert into structure
   ;;(*self.dhkp_last).(index1) = val 

END




;; RAW EESA Packet
FUNCTION esc_raw_pkt::decom, raw_buf, source_dict=source_dict

   ;; Header Words (3 x 16bits)
   hw = swap_endian(uint(raw_buf,0,3),/swap_if_little_endian)   

   ;; Check Packet Size
   ;; Can Have the following size:
   ;;     1. 202 Bytes
   ;;     2. 218 Bytes
   ;;     3. 218 Bytes
   IF hw[2] NE 202 AND hw[2] NE 216 AND hw[2] NE 218 THEN stop, 'Wrong ESC RAW Packet size.'

   IF hw[2] NE 202 THEN stop

   ;; Data Words (102 x 16bits)
   dw = swap_endian(uint(raw_buf,0,hw[2]/2.),/swap_if_little_endian)
   
   ;; Variable Length Packet Fix - Largest Packet is 218 Bytes
   ;; If packet is 202 Bytes then padding will occur
   ;;IF hw[2] EQ 202 THEN dw = [dw,replicate(0,9)]
   ;;IF hw[2] EQ 218 THEN dw = [dw,replicate(0,1)]

   ;; Calculate time
   jj = source_dict.jj
   h_index = dw[1] AND '1ff'x
   time = source_dict.date + h_index/512D*8D + jj*8D 

   ;; Pass index to source
   source_dict.index = h_index
   
   ;; Insert Data into structure
   strct = { $
           time:time, $
           h_sync:dw[0],  $
           h_index:h_index, $
           h_tr:ishft(dw[1],-9) AND '3'x,$
           h_fh:ishft(dw[1], -11) AND '1'x,$
           h_bytsize:dw[2],$
           eAnode:dw[3:18],$
           iAnode_m1:dw[19:34],$
           iAnode_m2:dw[35:50],$
           iAnode_m3:dw[51:66],$
           iAnode_m4:dw[67:82],$
           mhist:dw[83:98],$
           ahkp:dw[99],$
           dhkp:dw[100]};;,$
           ;;idiag:dw[101]}
   ;;idiag:dw[101:109]}

   self.ahkp_decom, h_index, dw[99]

   return, strct

END 


PRO esc_raw_pkt__define

   void = {esc_raw_pkt, $
           inherits esc_gen_rawdat, $
           flag: 0  $
          }

END
