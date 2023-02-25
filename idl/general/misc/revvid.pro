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
;   WHITE:   Make !p.background the lightest color (often white) and 
;            !p.color the darkest color (often black).
;
;   BLACK:   Make !p.background the darkest color (often black) and 
;            !p.color the lightest color (often white).
;
;SEE ALSO:
;   line_colors.pro to set custom line, background and foreground colors.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-02-24 15:38:23 -0800 (Fri, 24 Feb 2023) $
; $LastChangedRevision: 31512 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/revvid.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro revvid, white=white, black=black

  foreground = !p.color
  background = !p.background

  tvlct, r, g, b, /get
  i = sqrt(float(r)^2. + float(g)^2. + float(b)^2.)
  i_min = min(i, dark)
  i_max = max(i, lite)

  if keyword_set(white) then begin
    foreground = dark
    background = lite
  endif
  if keyword_set(black) then begin
    foreground = lite
    background = dark
  endif
  
  !p.color = background
  !p.background = foreground

  i = find_handle('alt_lab',verbose=-2)  ; special case -- not useful for most people
  if (i gt 0) then begin
    get_data,'alt_lab',alim=lim
    options,'alt_lab','colors',[lim.colors[0:2],!p.color]
  endif

  return

end
