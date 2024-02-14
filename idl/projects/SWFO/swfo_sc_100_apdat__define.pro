; $LastChangedBy: ali $
; $LastChangedDate: 2024-02-13 18:05:22 -0800 (Tue, 13 Feb 2024) $
; $LastChangedRevision: 32446 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_100_apdat__define.pro $


function swfo_sc_100_apdat::decom,ccsds,source_dict=source_dict

  ccsds_data = swfo_ccsds_data(ccsds)

  datastr = {$
    time:ccsds.time,  $
    time_delta:ccsds.time_delta, $
    met:ccsds.met,   $
    apid:ccsds.apid,  $
    seqn:ccsds.seqn,$
    seqn_delta:ccsds.seqn_delta,$
    packet_size:ccsds.pkt_size,$
    tod_day:                            swfo_data_select(ccsds_data,  6*8,16),$
    tod_millisec:                       swfo_data_select(ccsds_data,  8*8,32),$
    tod_microsec:                       swfo_data_select(ccsds_data, 12*8,16),$
    flight_software_version_number:     swfo_data_select(ccsds_data, 14*8,32),$
    packet_definition_version_number:   swfo_data_select(ccsds_data, 18*8,32),$
    tmon_master_enabled:                swfo_data_select(ccsds_data,237*8, 1),$
    tmon_001_sample_enabled_armed_triggered:swfo_data_select(ccsds_data,237*8+1, 3),$
    tmon_230_enabled_armed_triggered: swfo_data_select(ccsds_data,364*8+6, 3),$
    tmon_231_enabled_armed_triggered: swfo_data_select(ccsds_data,365*8+1, 3),$
    tmon_232_enabled_armed_triggered: swfo_data_select(ccsds_data,365*8+4, 3),$
    tmon_233_enabled_armed_triggered: swfo_data_select(ccsds_data,365*8+7, 3),$
    tmon_234_enabled_armed_triggered: swfo_data_select(ccsds_data,366*8+2, 3),$
    tmon_235_enabled_armed_triggered: swfo_data_select(ccsds_data,366*8+5, 3),$
    tmon_236_enabled_armed_triggered: swfo_data_select(ccsds_data,367*8  , 3),$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_100_apdat__define
  void = {swfo_sc_100_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

