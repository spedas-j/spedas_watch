;+
; $LastChangedBy: ali $
; $LastChangedDate: 2020-06-22 15:26:08 -0700 (Mon, 22 Jun 2020) $
; $LastChangedRevision: 28794 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/sweap/SPAN/spp_swp_qf.pro $
;-

pro spp_swp_qf,prefix=prefix

  if ~keyword_set(prefix) then prefix=''
  qf_labels = ['Counter Overflow','Snapshot On','Alt. Energy Table','Spoiler Test','Attenuator Engaged']
  options,verbose=0,prefix+'QUALITY_FLAG',tplot_routine='bitplot',numbits=5,yticks=6,psyms=2,labels=qf_labels,colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1

  pre='spp_sc_hkp_0x262_SWEAP_CRIT_SW_'
  options,verbose=0,pre+'58',tplot_routine='bitplot',numbits=8,yticks=9,psyms=2,labels=['SPC_PWR','SPANAI_PWR','SPANAE_PWR','SPANB_PWR','SPANA_HTR','SPANB_HTR','ACTR_PWR','OVERCURR_DETECT'],colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1,panel_size=2
  options,verbose=0,pre+'59',tplot_routine='bitplot',numbits=4,yticks=5,psyms=2,labels=['LINK_B_ACTIVE','LINK_A_ACTIVE','FIELDS_CLOCK','FLASH_PLBK_IN_PROGRESS'],colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1
  options,verbose=0,pre+'60',tplot_routine='bitplot',numbits=4,yticks=5,psyms=2,labels=['WDOG_RESET_DETECTED','BOOT_MODE','FSW_CSCI','OP_OVERRUN'],colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1
  options,verbose=0,pre+['SPANAI','SPANAE','SPANB'],tplot_routine='bitplot',numbits=4,yticks=5,psyms=2,labels=['HV_ENABLED','ATT_OR_IN1_IN2','CVR_OR_EOT1_EOT2','HK_MON_TRIP'],colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1
  options,verbose=0,pre+'SPC',tplot_routine='bitplot',numbits=4,yticks=5,psyms=2,labels=['RAIL_DAC_GT_LIMIT','OR_ELEC_FA_CALON','HV_ENABLED','MODE'],colors=[0,1,2,6],yticklen=1,ygridstyle=1,yminor=1
  options,verbose=0,pre+['LAST_FSW_EVENT','SPANAI_HV_MODE','SPANAE_HV_MODE','SPANB_HV_MODE'],tplot_routine='bitplot',numbits=4,yticks=5,psyms=4,yticklen=1,ygridstyle=1,yminor=1

end

;SWEAP_CRIT_SW_OVERCURR_DETECT,                                 58,    7,    1;
;SWEAP_CRIT_SW_ACTR_PWR,                                        58,    6,    1;
;SWEAP_CRIT_SW_SPANB_HTR,                                       58,    5,    1;
;SWEAP_CRIT_SW_SPANA_HTR,                                       58,    4,    1;
;SWEAP_CRIT_SW_SPANB_PWR,                                       58,    3,    1;
;SWEAP_CRIT_SW_SPANAE_PWR,                                      58,    2,    1;
;SWEAP_CRIT_SW_SPANAI_PWR,                                      58,    1,    1;
;SWEAP_CRIT_SW_SPC_PWR,                                         58,    0,    1;
;SWEAP_CRIT_SW_EVENT_CNTR,                                      59,    7,    4;
;SWEAP_CRIT_SW_FLASH_PLBK_IN_PROGRESS,                          59,    3,    1;
;SWEAP_CRIT_SW_FIELDS_CLOCK,                                    59,    2,    1;
;SWEAP_CRIT_SW_LINK_A_ACTIVE,                                   59,    1,    1;
;SWEAP_CRIT_SW_LINK_B_ACTIVE,                                   59,    0,    1;
;SWEAP_CRIT_SW_LAST_FSW_EVENT,                                  60,    7,    4;
;SWEAP_CRIT_SW_OP_OVERRUN,                                      60,    3,    1;
;SWEAP_CRIT_SW_FSW_CSCI,                                        60,    2,    1;
;SWEAP_CRIT_SW_BOOT_MODE,                                       60,    1,    1;
;SWEAP_CRIT_SW_WDOG_RESET_DETECTED,                             60,    0,    1;
;SWEAP_CRIT_SW_SWEM3P3V,                                        61,    7,    8;
;SWEAP_CRIT_SW_SPANAI_HK_MON_TRIP,                              62,    7,    1;
;SWEAP_CRIT_SW_SPANAI_CVR_OR_EOT1_EOT2,                         62,    6,    1;
;SWEAP_CRIT_SW_SPANAI_ATT_OR_IN1_IN2,                           62,    5,    1;
;SWEAP_CRIT_SW_SPANAI_HV_ENABLED,                               62,    4,    1;
;SWEAP_CRIT_SW_SPANAI_HV_MODE,                                  62,    3,    4;
;SWEAP_CRIT_SW_SPANAE_HK_MON_TRIP,                              63,    7,    1;
;SWEAP_CRIT_SW_SPANAE_CVR_OR_EOT1_EOT2,                         63,    6,    1;
;SWEAP_CRIT_SW_SPANAE_ATT_OR_IN1_IN2,                           63,    5,    1;
;SWEAP_CRIT_SW_SPANAE_HV_ENABLED,                               63,    4,    1;
;SWEAP_CRIT_SW_SPANAE_HV_MODE,                                  63,    3,    4;
;SWEAP_CRIT_SW_SPANB_HK_MON_TRIP,                               64,    7,    1;
;SWEAP_CRIT_SW_SPANB_CVR_OR_EOT1_EOT2,                          64,    6,    1;
;SWEAP_CRIT_SW_SPANB_ATT_OR_IN1_IN2,                            64,    5,    1;
;SWEAP_CRIT_SW_SPANB_HV_ENABLED,                                64,    4,    1;
;SWEAP_CRIT_SW_SPANB_HV_MODE,                                   64,    3,    4;
;SWEAP_CRIT_SW_SPC_MODE,                                        65,    7,    1;
;SWEAP_CRIT_SW_SPC_HV_ENABLED,                                  65,    6,    1;
;SWEAP_CRIT_SW_SPC_OR_ELEC_FA_CALON,                            65,    5,    1;
;SWEAP_CRIT_SW_SPC_RAIL_DAC_GT_LIMIT,                           65,    4,    1;
;SWEAP_CRIT_SW_SPC_ERR_CNTR,                                    65,    3,    4;
