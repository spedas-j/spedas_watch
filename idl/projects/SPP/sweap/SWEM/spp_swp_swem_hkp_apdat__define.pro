

function spp_swp_swem_hkp_apdat::decom,ccsds, source_dict=source_dict  ; header,ptp_header=ptp_header


if n_params() eq 0 then begin
  dprint,'Not working yet.'
  return,!null
endif


ccsds_data = spp_swp_ccsds_data(ccsds)

if ccsds.pkt_size lt 42 then begin
  if debug(2) then begin
    dprint,'error',ccsds.pkt_size,dlevel=2
    hexprint,ccsds_data
    return,0    
  endif
endif


;values = swap_endian(ulong(ccsds_data,10,11) )

temp_par = spp_swp_therm_temp()
temp_par_10bit      = temp_par
temp_par_10bit.xmax = 1023


;str = {time:   ccsds.time  ,$
;     seqn: ccsds.seqn, $
;     mon_3p3_c:    ( swap_endian(uint(ccsds_data, 192/8)) and '3ff'x ) * .997  , $
;     mon_3p3_v:    ( swap_endian(uint(ccsds_data, 144/8)) and '3ff'x ) * .0035  , $
;     gap:  ccsds.gap }
;
   str2 = {time:   ccsds.time  ,$
     met: ccsds.met , $
     seqn: ccsds.seqn, $
     dcb_temp:   func( (swap_endian(uint(ccsds_data, 86/8)) and '3ff'x  ) * 1.,param = temp_par_10bit)   ,  $
     lvps_temp:  func( ( swap_endian(uint(ccsds_data, 102/8)) and '3ff'x ) * 1.,param = temp_par_10bit)   , $
     swem_22_V:  ( swap_endian(uint(ccsds_data, 118/8)) and '3ff'x ) *.0235, $
     swem_3p6_V:  ( swap_endian(uint(ccsds_data, 134/8)) and '3ff'x ) *  .00942, $
     swem_3p3_V:  ( swap_endian(uint(ccsds_data, 150/8)) and '3ff'x ) *  .00411 , $
     swem_1p5_V:  ( swap_endian(uint(ccsds_data, 166/8)) and '3ff'x ) *  .00235 , $
     swem_1p5_C:  ( swap_endian(uint(ccsds_data, 182/8)) and '3ff'x ) *  .913 , $
     swem_3p3_C:  ( swap_endian(uint(ccsds_data, 198/8)) and '3ff'x ) *  .997 , $
     spc_22_C:  ( swap_endian(uint(ccsds_data, 214/8)) and '3ff'x ) *  .507 , $
     spb_22_C:  ( swap_endian(uint(ccsds_data, 230/8)) and '3ff'x ) *  .311  , $
     spa_22_C:  ( swap_endian(uint(ccsds_data, 246/8)) and '3ff'x ) *  .311  , $
     spi_22_C:   ( swap_endian(uint(ccsds_data, 262/8)) and '3ff'x ) * .311  , $
     spb_22_temp:  func( (swap_endian(uint(ccsds_data, 278/8)) and '3ff'x ) *  1.,param = temp_par_10bit)  , $
     spa_22_temp:   func( (swap_endian(uint(ccsds_data, 294/8)) and '3ff'x ) * 1. ,param = temp_par_10bit) , $
     spi_22_temp:   func( (swap_endian(uint(ccsds_data, 310/8)) and '3ff'x ) * 1. ,param = temp_par_10bit) , $
     gap:  ccsds.gap }
       
  return,str2

end


function spp_swp_swem_hkp_apdat::cdf_global_attributes
  
  global_att = self.spp_gen_apdat::cdf_global_attributes()
  global_att['Descriptor'] = 'SWEM>SWEAP Electronics Module'
;  global_att['Data_type'] = self.name +'>Survey Calibrated Particle Flux'
;  global_att['Data_version'] = 'v00'
;  global_att['TEXT'] = 'PSP'
;  global_att['MODS'] = 'Revision 0'
;  ;global_att['Logical_file_id'] =  self.name+'_test.cdf'  ; 'mvn_sep_l2_s1-cal-svy-full_20180201_v04_r02.cdf'
;  global_att['dirpath'] = './'
  ;global_att['Logical_source'] = '.cal.spec_svy'
  ;global_att['Logical_source_description'] = 'DERIVED FROM: PSP SWEAP'  ; SEP (Solar Energetic Particle) Instrument
  global_att['Sensor'] = 'SWEM'   ;'SEP1'
  global_att['PI_name'] = 'J. Kasper'
  global_att['PI_affiliation'] = 'U. Michigan'
  global_att['IPI_name'] = 'D. Larson (davin@ssl.berkeley.edu)
  global_att['IPI_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
  global_att['InstrumentLead_name'] = '  '
  global_att['InstrumentLead_affiliation'] = 'U.C. Berkeley Space Sciences Laboratory'
  global_att['Instrument_type'] = 'Electrostatic Analyzer Particle Detector'
  global_att['Mission_group'] = 'PSP'
  global_att['Parents'] = '' ; '2018-02-17/22:17:38   202134481 ChecksumExecutableNotAvailable            /disks/data/maven/data/sci/pfp/l0_all/2018/02/mvn_pfp_all_l0_20180201_v002.dat ...
  global_att = global_att + self.sw_version()
  ;  global_att['Planet'] = 'Mars
  ;  global_att['PDS_collection_id'] = 'MAVEN
  ;  global_att['PDS_start_time'] = '2018-02-01T00:00:14.230Z
  ;  global_att['PDS_stop_time'] = '2018-02-02T00:00:05.594Z
  ;  global_att['SW_VERSION'] = 'v00'
  ;  global_att['SW_TIME_STAMP_FILE'] = '/home/mavensep/socware/projects/maven/sep/mvn_sep_sw_version.pro
  ;  global_att['SW_TIME_STAMP'] =  time_string(systime(1))
  ;  global_att['SW_RUNTIME'] =  time_string(systime(1))
  ;  global_att['SW_RUNBY'] =
  ;  global_att['SVN_CHANGEDBY'] = '$LastChangedBy: davin-mac $'
  ;  global_att['SVN_CHANGEDATE'] = '$LastChangedDate: 2018-12-08 13:40:15 -0800 (Sat, 08 Dec 2018) $'
  ;  global_att['SVN_REVISION'] = '$LastChangedRevision: 26285 $'

  return,global_att
end







PRO spp_swp_swem_hkp_apdat__define

  void = {spp_swp_swem_hkp_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    flag: 0 $
  }
END


