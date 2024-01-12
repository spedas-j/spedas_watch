; $LastChangedBy: ali $
; $LastChangedDate: 2024-01-10 19:12:00 -0800 (Wed, 10 Jan 2024) $
; $LastChangedRevision: 32359 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_170_apdat__define.pro $


function swfo_sc_170_apdat::decom,ccsds,source_dict=source_dict

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
    stis_automessaging_enabled:       swfo_data_select(ccsds_data,28 *8+3, 1),$
    stis_communications_enabled:      swfo_data_select(ccsds_data,28 *8+4, 1),$
    stis_tod_enabled:                 swfo_data_select(ccsds_data,28 *8+5, 1),$
    stis_tx_protocol_error_counter:   swfo_data_select(ccsds_data,37 *8  , 8),$
    stis_rx_protocol_error_counter:   swfo_data_select(ccsds_data,38 *8  , 8),$
    stis_tod_transmit_success_counter:swfo_data_select(ccsds_data,39 *8  , 8),$
    stis_tod_transmit_fail_counter:   swfo_data_select(ccsds_data,40 *8  , 8),$
    stis_command_counter:             swfo_data_select(ccsds_data,41 *8  , 8),$
    stis_command_fail_counter:        swfo_data_select(ccsds_data,42 *8  , 8),$
    stis_telemetry_counter:           swfo_data_select(ccsds_data,43 *8  , 8),$
    stis_telemetry_fail_counter:      swfo_data_select(ccsds_data,44 *8  , 8),$
    stis_invalid_version_number_ctr:  swfo_data_select(ccsds_data,45 *8  , 8),$
    stis_invalid_type_indicator_ctr:  swfo_data_select(ccsds_data,46 *8  , 8),$
    stis_invalid_secondary_header_ctr:swfo_data_select(ccsds_data,47 *8  , 8),$
    stis_last_packet_length_field:    swfo_data_select(ccsds_data,48 *8  ,32),$
    stis_last_packet_length_total:    swfo_data_select(ccsds_data,52 *8  ,32),$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_170_apdat__define
  void = {swfo_sc_170_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

