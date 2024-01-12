; $LastChangedBy: ali $
; $LastChangedDate: 2024-01-10 19:12:00 -0800 (Wed, 10 Jan 2024) $
; $LastChangedRevision: 32359 $
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
    tod_day:                swfo_data_select(ccsds_data,(6) *8,  16),$
    tod_millisec:           swfo_data_select(ccsds_data,(8) *8,  32),$
    tod_microsec:           swfo_data_select(ccsds_data,(12)*8,  16),$
    header_spare_bytes:     swfo_data_select(ccsds_data,(14)*8,  16),$
    gap:ccsds.gap }

  return,datastr

end


pro swfo_sc_100_apdat__define
  void = {swfo_sc_100_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

