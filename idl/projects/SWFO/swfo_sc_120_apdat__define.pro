; $LastChangedBy: ali $
; $LastChangedDate: 2024-01-10 19:12:00 -0800 (Wed, 10 Jan 2024) $
; $LastChangedRevision: 32359 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_120_apdat__define.pro $


function swfo_sc_120_apdat::decom,ccsds,source_dict=source_dict

  ccsds_data = swfo_ccsds_data(ccsds)

  datastr = {$
    time:ccsds.time,  $
    time_delta:ccsds.time_delta, $
    met:ccsds.met,   $
    apid:ccsds.apid,  $
    seqn:ccsds.seqn,$
    seqn_delta:ccsds.seqn_delta,$
    packet_size:ccsds.pkt_size,$
    tod_day:                          swfo_data_select(ccsds_data,6  *8  ,16),$
    tod_millisec:                     swfo_data_select(ccsds_data,8  *8  ,32),$
    tod_microsec:                     swfo_data_select(ccsds_data,12 *8  ,16),$
    header_spare_bytes:               swfo_data_select(ccsds_data,14 *8  ,16),$
    stis_power:                       swfo_data_select(ccsds_data,93 *8+6, 1),$
    stis_current_raw:                 swfo_data_select(ccsds_data,93 *8+7,12),$
    stis_overcurrent_trip:            swfo_data_select(ccsds_data,95 *8+3, 1),$
    stis_overcurrent_enable:          swfo_data_select(ccsds_data,95 *8+4, 1),$
    stis_survival_heater_power:       swfo_data_select(ccsds_data,219*8+5, 1),$
    stis_survival_heater_current_raw: swfo_data_select(ccsds_data,219*8+6,12),$
    stis_survival_heater_oc_trip:     swfo_data_select(ccsds_data,221*8+2, 1),$
    stis_survival_heater_oc_setpoint_raw:swfo_data_select(ccsds_data,221*8+3,12),$
    gap:ccsds.gap }

  str2={$
    stis_current_amps:-.02727+.002447*datastr.stis_current_raw,$
    stis_survival_heater_current_amps:.000357*datastr.stis_survival_heater_current_raw,$
    stis_survival_heater_oc_setpoint_amps:.000357*datastr.stis_survival_heater_oc_setpoint_raw}

  return,create_struct(datastr,str2)

end


pro swfo_sc_120_apdat__define
  void = {swfo_sc_120_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

