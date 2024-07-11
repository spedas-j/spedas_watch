;+
; :NAME:
;   eva_sitl_copy_fomstr
; 
; :PURPOSE:
;   To make a FOMstr tplot-varible for individuatl spacecraft.
; 
; :INPUT:
;   None, but "mms_stlm_fomstr" must exists.
;   
;   $LastChangedBy: moka $
;   $LastChangedDate: 2024-07-10 14:20:15 -0700 (Wed, 10 Jul 2024) $
;   $LastChangedRevision: 32733 $
;   $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl_copy_fomstr.pro $
;- 
PRO eva_sitl_copy_fomstr
  compile_opt idl3

  tn = tnames('mms_stlm_fomstr',ct)
  if(ct eq 0) then begin
    message, "mms_stlm_fomstr not found (eva_sitl_copy_fomstr)"
  endif
  
  copy_data, 'mms_stlm_fomstr','mms1_stlm_fomstr'
  copy_data, 'mms_stlm_fomstr','mms2_stlm_fomstr'
  copy_data, 'mms_stlm_fomstr','mms3_stlm_fomstr'
  copy_data, 'mms_stlm_fomstr','mms4_stlm_fomstr'
  options,   'mms1_stlm_fomstr','ytitle','mms1!CFOM'
  options,   'mms2_stlm_fomstr','ytitle','mms2!CFOM'
  options,   'mms3_stlm_fomstr','ytitle','mms3!CFOM'
  options,   'mms4_stlm_fomstr','ytitle','mms4!CFOM'  
END