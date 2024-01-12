; $LastChangedBy: ali $
; $LastChangedDate: 2024-01-10 19:12:00 -0800 (Wed, 10 Jan 2024) $
; $LastChangedRevision: 32359 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_130_apdat__define.pro $


function swfo_sc_130_apdat::decom,ccsds,source_dict=source_dict

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
    stis_interface_temp_raw:          swfo_data_select(ccsds_data,71 *8  ,12),$
    stis_temp1_raw:                   swfo_data_select(ccsds_data,104*8  ,12),$
    stis_temp2_raw:                   swfo_data_select(ccsds_data,108*8+4,12),$
    gap:ccsds.gap }

  temp0=double(datastr.stis_interface_temp_raw)
  temps=double([datastr.stis_temp1_raw,datastr.stis_temp2_raw])
  c0=-68.0794195858006
  c1=0.144869362010568
  c2=-0.000162342734683212
  c3=1.0265159480653E-07
  c4=-3.03845645517943E-11
  c5=3.40727455823906E-15
  
  str2={$
    stis_interface_temp:163.6-.2928*temp0+2.993e-4*temp0^2-1.5618e-7*temp0^3+3.815e-11*temp0^4-3.5233e-15*temp0^5,$
    stis_temps:c0+c1*temps+c2*temps^2+c3*temps^3+c4*temps^4+c5*temps^5}

  return,create_struct(datastr,str2)

end


pro swfo_sc_130_apdat__define
  void = {swfo_sc_130_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

