;+
;NAME:
;tplot_panel_label
;PURPOSE:
;For an input tplot variable, add an attribute, 'panel_label', that will be
;printed on the tplot panel for that variable.
;CALLING SEQUENCE:
;tplot_panel_label, tvar, panel_label, x, y, data_coordinates =
;data_coordinates, upper_right=upper_right, lower_right=lower_right, $
;upper_left=upper_left, lower_left=lower_left, charsize=charsize
;INPUT:
;tvar = the tplot variable name
;panel_label = the string input
;x, y = the plot position for the panel_label; the default is relative to
;the plot panel, e.g., x, y = [0.9, 0.9] will put the panel_label in the
;upper right hand corner 9/10 od the way from the lower left.
;data_coordinates = if, set, then use data values instead of relative
;values
;upper_right = if set, then set [x,y] = [.9, .9]
;lower_right = if set, then set [x, y] = [.9, .1]
;Upper_left = if set, then set [x,y]=[0.05, 0.9]
;lower_left = if set, then set[x,y]=[0.05, 0.1]
;charsize = default is 1
;OUTPUT:
;No explicit output, instead, an attribute 'panel_label' is added to the
;limits structure for the given variable
;HISTORY:
;2025-02-04, jmm. jimm@ssl.berkeley.edu
; $LastChangedBy: $
; $LastChangedDate: $
; $LastChangedRevision: $
; $URL: $
;-
Pro tplot_panel_label, tvar, label, x, y, $
                       data_coordinates=data_coordinates, $
                       upper_right=upper_right, lower_right=lower_right, $
                       upper_left=upper_left, lower_left=lower_left, $
                       charsize=charsize
  
  If(keyword_set(data_coordinates)) Then dq_set = 1b Else Begin
     dq_set = 0b
     If(keyword_set(upper_right)) Then Begin
        x = 0.9 & y =  0.9
     Endif Else If(keyword_set(lower_right)) Then Begin
        x = 0.9 & y = 0.1
     Endif Else If(keyword_set(upper_left)) Then Begin
        x = 0.05 & y = 0.9
     Endif Else If(keyword_set(lower_left)) Then Begin
        x = 0.05 & y = 0.1
     Endif
  Endelse

  If(keyword_set(charsize)) Then char = charsize Else char = 1
  opt_struct = {label:label, xpos:x, ypos:y, $
                dq_set:dq_set, charsize:char}
  options, tvar, 'panel_label', opt_struct

End

