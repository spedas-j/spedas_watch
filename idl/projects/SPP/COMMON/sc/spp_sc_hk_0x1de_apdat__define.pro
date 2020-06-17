;Ali: June 2020
;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-06-16 08:55:23 -0700 (Tue, 16 Jun 2020) $
; $LastChangedRevision: 28779 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/COMMON/sc/spp_sc_hk_0x1de_apdat__define.pro $
;-

function spp_SC_HK_0x1de_struct,ccsds_data
  if n_elements(ccsds_data) eq 0 then ccsds_data = bytarr(67)

  a0 = -200.
  a1 = 500./65535
  str = {time:!values.d_nan ,$
    met:!values.d_nan, $
    seqn: 0u, $
    pkt_size: 0u, $
    RIU_DERIVED_D_SWEAP_SPAN_B_ELECT_BOX_TEMP:a0+a1*spp_swp_data_select(ccsds_data,136*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPAN_B_TOP_ANALYZER_TEMP:a0+a1*spp_swp_data_select(ccsds_data,142*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPAN_A_POS_TOP_ANALYZER_TEMP:a0+a1*spp_swp_data_select(ccsds_data,176*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPAN_B_PEDESTAL_TEMP:a0+a1*spp_swp_data_select(ccsds_data,234*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPAN_A_POS_ELECT_BOX_TEMP:a0+a1*spp_swp_data_select(ccsds_data,264*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPC_PRE_AMP_TEMP:a0+a1*spp_swp_data_select(ccsds_data,270*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SPAN_A_POS_PEDESTAL_TEMP:a0+a1*spp_swp_data_select(ccsds_data,296*8+7-7,16), $
    RIU_DERIVED_D_SWEAP_SWEM_TEMP:a0+a1*spp_swp_data_select(ccsds_data,416*8+7-7,16), $
    gap:0B}
  return, str
end

;Line 13125:     RIU_DERIVED_D_SWEAP_SPAN_B_ELECT_BOX_TEMP,                    136,    7,   16;
;Line 13128:     RIU_DERIVED_D_SWEAP_SPAN_B_TOP_ANALYZER_TEMP,                 142,    7,   16;
;Line 13145:     RIU_DERIVED_D_SWEAP_SPAN_A_POS_TOP_ANALYZER_TEMP,             176,    7,   16;
;Line 13174:     RIU_DERIVED_D_SWEAP_SPAN_B_PEDESTAL_TEMP,                     234,    7,   16;
;Line 13189:     RIU_DERIVED_D_SWEAP_SPAN_A_POS_ELECT_BOX_TEMP,                264,    7,   16;
;Line 13192:     RIU_DERIVED_D_SWEAP_SPC_PRE_AMP_TEMP,                         270,    7,   16;
;Line 13205:     RIU_DERIVED_D_SWEAP_SPAN_A_POS_PEDESTAL_TEMP,                 296,    7,   16;
;Line 13265:     RIU_DERIVED_D_SWEAP_SWEM_TEMP,                                416,    7,   16;
;Line 320: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_B_ELECT_BOX_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 323: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_B_TOP_ANALYZER_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 340: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_A_POS_TOP_ANALYZER_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 369: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_B_PEDESTAL_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 384: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_A_POS_ELECT_BOX_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 387: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPC_PRE_AMP_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 400: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SPAN_A_POS_PEDESTAL_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)
;Line 460: EU(Raw='SC_HK_0x1DE.RIU_DERIVED_D_SWEAP_SWEM_TEMP') := fCalCurve([0.0, 65535.0], [-200.0, 300.0], Raw)


function SPP_SC_HK_0x1de_apdat::decom,ccsds, source_dict=source_dict   ;,ptp_header=ptp_header

  ccsds_data = spp_swp_ccsds_data(ccsds)
  str2 = spp_SC_HK_0x1de_struct(ccsds_data)
  struct_assign,ccsds,str2,/nozero
  return,str2

end


pro spp_SC_HK_0x1de_apdat__define

  void = {spp_SC_HK_0x1de_apdat, $
    inherits spp_gen_apdat, $    ; superclass
    flag: 0 $
  }
end
;