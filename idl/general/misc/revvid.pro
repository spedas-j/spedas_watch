;+
;PROCEDURE:   revvid
;PURPOSE:
;  Reverses video for graphics windows by swapping !p.color and
;  !p.background.
;
;USAGE:
;  revvid
;
;INPUTS:
;   none:    A simple toggle.
;
;KEYWORDS:
;   WHITE:   Make background white, pen color black.
;
;   BLACK:   Make background black, pen color white.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-06-15 11:17:23 -0700 (Wed, 15 Jun 2022) $
; $LastChangedRevision: 30857 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/revvid.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro revvid, white=white, black=black

  foreground = !p.color
  background = !p.background
  
  if keyword_set(white) then foreground = max([!p.color,!p.background], min=background)
  if keyword_set(black) then foreground = min([!p.color,!p.background], max=background)
  
  !p.color = background
  !p.background = foreground

  i = find_handle('alt_lab',verbose=-2)  ; special case -- not useful for most people
  if (i gt 0) then begin
    get_data,'alt_lab',alim=lim
    options,'alt_lab','colors',[lim.colors[0:2],!p.color]
  endif

  return

end
