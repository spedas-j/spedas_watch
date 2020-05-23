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
;$LastChangedDate: 2020-05-22 14:49:22 -0700 (Fri, 22 May 2020) $
;$LastChangedRevision: 28727 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/examples/advanced/mms_cotrans_lmn_crib.pro $
;-

; load the FGM data to be transforme4d
mms_load_fgm, trange=['2015-10-16/13:05:35', '2015-10-16/13:07:25'], data_rate='brst', probe=2

; transfrom the B-field in GSM coordinates to LMN coordinates
mms_cotrans_lmn, 'mms2_fgm_b_gsm_brst_l2_bvec', 'mms2_fgm_b_lmn_brst_l2_bvec'

tplot, 'mms2_fgm_b_lmn_brst_l2_bvec'

stop
end