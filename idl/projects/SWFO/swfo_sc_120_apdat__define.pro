; $LastChangedBy: ali $
; $LastChangedDate: 2024-02-13 18:05:22 -0800 (Tue, 13 Feb 2024) $
; $LastChangedRevision: 32446 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SWFO/swfo_sc_120_apdat__define.pro $


function swfo_sc_120_apdat::decom,ccsds,source_dict=source_dict

  ccsds_data = swfo_ccsds_data(ccsds)

  stis_power=                       swfo_data_select(ccsds_data,93 *8+6, 1)
  stis_current_raw=                 swfo_data_select(ccsds_data,93 *8+7,12)
  stis_overcurrent_trip=            swfo_data_select(ccsds_data,95 *8+3, 1)
  stis_overcurrent_enable_status=   swfo_data_select(ccsds_data,95 *8+4, 1)
  stis_survival_heater_power0=       swfo_data_select(ccsds_data,219*8+5, 1)
  stis_survival_heater_current_raw0= swfo_data_select(ccsds_data,219*8+6,12)
  stis_survival_heater_oc_trip0=     swfo_data_select(ccsds_data,221*8+2, 1)
  stis_survival_heater_oc_setpoint_raw0=swfo_data_select(ccsds_data,221*8+3,12)
  stis_survival_heater_power=       swfo_data_select(ccsds_data,1661, 1)
  stis_survival_heater_current_raw= swfo_data_select(ccsds_data,1662,12)
  stis_survival_heater_oc_trip=     swfo_data_select(ccsds_data,1674, 1)
  stis_survival_heater_oc_setpoint_raw=swfo_data_select(ccsds_data,1675,12)

  ccor_power=                       swfo_data_select(ccsds_data,99 *8+6, 1)
  ccor_current_raw=                 swfo_data_select(ccsds_data,99 *8+7,12)
  ccor_overcurrent_trip=            swfo_data_select(ccsds_data,101*8+3, 1)
  ccor_overcurrent_enable_status=   swfo_data_select(ccsds_data,101*8+4, 1)
  ccor_survival_heater_power=       swfo_data_select(ccsds_data,226*8+1, 1)
  ccor_survival_heater_current_raw= swfo_data_select(ccsds_data,226*8+2,12)
  ccor_survival_heater_oc_trip=     swfo_data_select(ccsds_data,227*8+6, 1)
  ccor_survival_heater_oc_setpoint_raw=swfo_data_select(ccsds_data,227*8+7,12)

  mag_arm_power=                    swfo_data_select(ccsds_data,109*8+5, 1)
  mag_power=                        swfo_data_select(ccsds_data,109*8+6, 1)
  mag_current_raw=                  swfo_data_select(ccsds_data,109*8+7,12)
  mag_overcurrent_trip=             swfo_data_select(ccsds_data,111*8+3, 1)
  mag_overcurrent_enable_status=    swfo_data_select(ccsds_data,111*8+4, 1)
  mag_survival_heater_power=        swfo_data_select(ccsds_data,266*8+1, 1)
  mag_survival_heater_current_raw=  swfo_data_select(ccsds_data,266*8+2,12)
  mag_survival_heater_oc_trip=      swfo_data_select(ccsds_data,267*8+6, 1)
  mag_survival_heater_oc_setpoint_raw=swfo_data_select(ccsds_data,267*8+7,12)

  swips_arm_power=                  swfo_data_select(ccsds_data,111*8+5, 1)
  swips_power=                      swfo_data_select(ccsds_data,111*8+6, 1)
  swips_current_raw=                swfo_data_select(ccsds_data,111*8+7,12)
  swips_overcurrent_trip=           swfo_data_select(ccsds_data,113*8+3, 1)
  swips_overcurrent_enable_status=  swfo_data_select(ccsds_data,113*8+4, 1)
  swips_survival_heater_power=      swfo_data_select(ccsds_data,256*8+3, 1)
  swips_survival_heater_current_raw=swfo_data_select(ccsds_data,256*8+4,12)
  swips_survival_heater_oc_trip=    swfo_data_select(ccsds_data,258*8  , 1)
  swips_survival_heater_oc_setpoint_raw=swfo_data_select(ccsds_data,258*8+1,12)

  instrument_current_raw=[stis_current_raw,ccor_current_raw,mag_current_raw,swips_current_raw]
  instrument_survival_heater_current_raw=[stis_survival_heater_current_raw,ccor_survival_heater_current_raw,mag_survival_heater_current_raw,swips_survival_heater_current_raw]
  instrument_survival_heater_oc_setpoint_raw=[stis_survival_heater_oc_setpoint_raw,ccor_survival_heater_oc_setpoint_raw,mag_survival_heater_oc_setpoint_raw,swips_survival_heater_oc_setpoint_raw]

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
    power_commanded_charge_control_mode:swfo_data_select(ccsds_data,14 *8  , 2),$
    power_commanded_flag_manual_mode:   swfo_data_select(ccsds_data,14 *8+2, 1),$
    power_fsw_pcm_sas_command_state:    swfo_data_select(ccsds_data,14 *8+3, 1),$
    power_fsw_charge_control_status:    swfo_data_select(ccsds_data,14 *8+4, 1),$
    power_commanded_charge_control_cycle_time_ms:swfo_data_select(ccsds_data,15 *8  ,16),$
    ;power_calculated_vt_setpoint_for_vt_mode:swfo_data_select(ccsds_data,17 *8  ,64),$
    ;power_latest_commanded_voltage_offset:   swfo_data_select(ccsds_data,25 *8  ,64),$
    power_commanded_flag_use_safe_vt_offset: swfo_data_select(ccsds_data,33 *8  , 8),$
    instrument_current_raw:instrument_current_raw,$
    instrument_current_amps:-.02727+.002447*instrument_current_raw,$
    instrument_survival_heater_current_raw:instrument_survival_heater_current_raw,$
    instrument_survival_heater_current_amps:.000357*instrument_survival_heater_current_raw,$
    instrument_survival_heater_oc_setpoint_raw:instrument_survival_heater_oc_setpoint_raw,$
    instrument_survival_heater_oc_setpoint_amps:.000357*instrument_survival_heater_oc_setpoint_raw,$
    stis_power_bits:(((stis_power*2b+stis_overcurrent_trip)*2b+stis_overcurrent_enable_status)*2b+stis_survival_heater_power)*2b+stis_survival_heater_oc_trip,$
    ccor_power_bits:(((ccor_power*2b+ccor_overcurrent_trip)*2b+ccor_overcurrent_enable_status)*2b+ccor_survival_heater_power)*2b+ccor_survival_heater_oc_trip,$
    mag_power_bits:((((mag_arm_power*2b+mag_power)*2b+mag_overcurrent_trip)*2b+mag_overcurrent_enable_status)*2b+mag_survival_heater_power)*2b+mag_survival_heater_oc_trip,$
    swips_power_bits:((((swips_arm_power*2b+swips_power)*2b+swips_overcurrent_trip)*2b+swips_overcurrent_enable_status)*2b+swips_survival_heater_power)*2b+swips_survival_heater_oc_trip,$
    gap:ccsds.gap }

  return,create_struct(datastr)

end


pro swfo_sc_120_apdat__define
  void = {swfo_sc_120_apdat, $
    inherits swfo_gen_apdat $    ; superclass
  }
end

