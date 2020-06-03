;+
; PROCEDURE:
;         mms_cotrans_lmn_crib
;
; PURPOSE:
;         Shows how to tranforms MMS vector fields to LMN (boundary-normal) coordinates
;         using the Shue et al., 1998 magnetopause model
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2020-06-02 09:56:49 -0700 (Tue, 02 Jun 2020) $
;$LastChangedRevision: 28760 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_cotrans_lmn_crib.pro $
;-

; load the FGM data to be transformed
mms_load_fgm, trange=['2015-10-16/13:05:35', '2015-10-16/13:07:25'], data_rate='brst', probe=2

; transfrom the B-field in GSM coordinates to LMN coordinates
mms_cotrans_lmn, 'mms2_fgm_b_gsm_brst_l2_bvec', 'mms2_fgm_b_lmn_brst_l2_bvec'
tplot, 'mms2_fgm_b_lmn_brst_l2_bvec'
stop

; perform the transformation from GSE coordinates to LMN coordinates using WIND data instead of OMNI data
; note: internally, this transforms the input vector to GSM coordinates prior to transforming to LMN coordinates
mms_cotrans_lmn, 'mms2_fgm_b_gse_brst_l2_bvec', 'mms2_fgm_b_lmn_brst_l2_bvec_wind', /wind
tplot, 'mms2_fgm_b_lmn_brst_l2_bvec_wind'
stop

; perform the transformation from GSE coordinates to LMN coordinates using 5-min HRO data instead of the 1-min HRO data
mms_cotrans_lmn, 'mms2_fgm_b_gse_brst_l2_bvec', 'mms2_fgm_b_lmn_brst_l2_bvec', /min5
tplot, 'mms2_fgm_b_lmn_brst_l2_bvec'
stop

end