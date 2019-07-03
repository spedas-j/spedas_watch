;+
; PROCEDURE:
;         tplot_remove_panel
;
; PURPOSE:
;         Remove panel(s) from the current tplot window
;
; INPUT:
;         panel_num: int or array of ints containing panel #s 
;                    to remove from the current tplot window
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2019-07-02 14:08:30 -0700 (Tue, 02 Jul 2019) $
;$LastChangedRevision: 27402 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/tplot/tplot_remove_panel.pro $
;-

pro tplot_remove_panel, panel_num
  compile_opt idl2
  
  @tplot_com.pro
  if undefined(panel_num) then begin
    dprint, dlevel=0, 'Please specify a panel # to remove from the current tplot window'
    return
  endif
  
  current_vars = tplot_vars.options.varnames
  out_vars = current_vars
  
  for panel_idx=0, n_elements(panel_num)-1 do begin
    if size(panel_num[panel_idx], /type) eq 2 || size(panel_num[panel_idx], /type) eq 3 then begin
      if panel_num[panel_idx] gt n_elements(current_vars)-1 then begin
        dprint, dlevel=0, 'Panel does not exist'
        continue
      endif
      var_to_remove = current_vars[panel_num[panel_idx]]
      vars_to_keep = where(out_vars ne var_to_remove, keepcount)
      if keepcount ne 0 then out_vars = out_vars[where(out_vars ne var_to_remove)]
      if keepcount eq 0 then begin
        dprint, dlevel=0, 'Can not remove all panels from figure'
        return
      endif
    endif
  endfor
  
  tplot, out_vars
end