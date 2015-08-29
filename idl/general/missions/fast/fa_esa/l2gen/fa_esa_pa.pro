;+
;NAME:
; fa_esa_pa_array
;PURPOSE:
; creates a pitch angle array for FAST ESA data;
;CALLING SEQUENCE:
; pa = fa_esa_pa_array(theta, theta_shift, mode_ind)
;INPUT:
; theta = an array of (96, 64, 2 or 3) of angle values
; theta_shift = an array of (ntimes) values for the offset to get
;               pitch angle from theta, PA = theta+theta_shift
; mode = 0, 1 (or 2) the mode index used to get the correct value of
;               theta_shift to apply for each time interval
;KEYWORDS:
; fillval = the fill value, the default is !values.f_nan
;HISTORY:
; 2015-08-28, jmm, jimm@ssl.berkeley.edu
;-
Function fa_esa_pa_array, theta, theta_shift, mode_ind, fillval = fillval

  ntimes = n_elements(mode_ind)
  If(n_elements(theta_shift) Ne ntimes) Then Return, -1
  If(keyword_set(fillval)) Then fv = fillval Else fv = !values.f_nan
  theta_out = fltarr(96, 64, ntimes) & theta_out[*] = fv
  mode0 = where(mode_ind Eq 0, nmode0)
  If(nmode0 Gt 0) Then Begin
     For j = 0, nmode0-1 Do theta_out[0, 0, mode0[j]] = theta[*, *, 0]+theta_shift[mode0[j]]
  Endif
  mode1 = where(mode_ind Eq 0, nmode1)
  If(nmode1 Gt 0) Then Begin
     For j = 0, nmode1-1 Do theta_out[0, 0, mode1[j]] = theta[*, *, 1]+theta_shift[mode1[j]]
  Endif
  mode2 = where(mode_ind Eq 0, nmode2)
  If(nmode2 Gt 0) Then Begin
     For j = 0, nmode2-1 Do theta_out[0, 0, mode2[j]] = theta[*, *, 2]+theta_shift[mode2[j]]
  Endif
  Return, theta_out
End

;+
;NAME:
; fa_esa_pa
;CALLING SEQUENCE:
; pitch_angle = fa_esa_pa(astruct, orig_names, index=index)
;INPUT:
; astruct - the structure, created by read_myCDF that should contain
;           at least one Virtual variable.
; orig_names - the list of varibles that exist in the structure.
; index - the virtual variable (index number) for which this
;         function is being called to compute.  If this isn't
;         defined, then the function will find the 1st virtual variable.
;HISTORY:
; hacked from CDAWlib apply_esa_qflag.pro, jmm, 2015-08-28
; $LastChangedBy: jimm $
; $LastChangedDate: 2015-08-28 13:51:59 -0700 (Fri, 28 Aug 2015) $
; $LastChangedRevision: 18665 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/missions/fast/fa_esa/l2gen/fa_esa_pa.pro $
;-
Function fa_esa_pa, astruct, orig_names, index=index

;This code assumes that the Component_0 is theta, the mode-dependent
;angle, Component_1 is the theta_shift variable and Component_2 the
;mode_ind variable
  
  atags = tag_names(astruct)    ;get the variable names.
  vv_tagnames=strarr(1)
  vv_tagindx = vv_names(astruct,names=vv_tagnames) ;find the virtual vars

  if keyword_set(index) then begin
     index = index
  endif else begin              ;get the 1st vv
     index = vv_tagindx[0]
     if (vv_tagindx[0] lt 0) then return, -1
  endelse
  
  c_0 = astruct.(index).COMPONENT_0
  c_1 = astruct.(index).COMPONENT_1
  c_2 = astruct.(index).COMPONENT_2
  if (c_0 ne '' && c_1 ne '' && c_2 ne '') then begin
;theta variable
     var_idx = tagindex(c_0, atags)
     itags = tag_names(astruct.(var_idx)) ;tags for comp 0
     d0 = tagindex('DAT', itags)
     if(d0[0] ne -1) then theta = astruct.(var_idx).DAT else begin
        d0 = tagindex('HANDLE',itags)
        handle_value, astruct.(var_idx).HANDLE, theta
     endelse
;shift
     var_idx = tagindex(c_1, atags)
     itags = tag_names(astruct.(var_idx)) ;tags for comp 1
     d1 = tagindex('DAT', itags)
     if(d1[0] ne -1) then theta_shift = astruct.(var_idx).DAT else begin
        d1 = tagindex('HANDLE',itags)
        handle_value, astruct.(var_idx).HANDLE, theta_shift
     endelse
     fill_val = astruct.(var_idx).fillval
;mode_ind
     var_idx = tagindex(c_2, atags)
     itags = tag_names(astruct.(var_idx)) ;tags for comp 2
     d2 = tagindex('DAT', itags)
     if(d2[0] ne -1) then mode_ind = astruct.(var_idx).DAT else begin
        d2 = tagindex('HANDLE',itags)
        handle_value, astruct.(var_idx).HANDLE, mode_ind
     endelse
;That's all, fill the output variable
     theta_out = fa_esa_pa_array(theta, theta_shift, mode_ind, fillval=fillval)

;now, need to fill the virtual variable data structure with this new data array
;and "turn off" the original variable.
     temp = handle_create(value=theta_out)
     astruct.(index).HANDLE = temp
  endif
; Check astruct and reset variables not in orignal variable list to metadata,
; so that variables that weren't requested won't be plotted/listed.
  status = check_myvartype(astruct, orig_names)

  return, astruct
end
