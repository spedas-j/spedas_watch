;+
;PROCEDURE showct, n
;   Show the specified color table in a new window.  Does not alter the current
;   color table.
;
;INPUTS:
;   n:         Color table number.  Standard tables have n < 1000.  CSV tables
;              have n >= 1000.  See 'loadcsv' for details.  If n is not provided,
;              show the current color table.
;
;KEYWORDS:
;   REVERSE:   If set, then reverse the table order from bottom_c to top_c.
;
;SEE ALSO:
;   xpalette:  Shows the current color table in an interactive widget.  Provides
;              much more functionality, but only for the current color table.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2022-07-31 19:10:09 -0700 (Sun, 31 Jul 2022) $
; $LastChangedRevision: 30982 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/misc/system/showct.pro $
;-
pro showct, color_table, reverse=color_reverse

  cols = get_colors()
  crev = keyword_set(color_reverse)

  if (n_elements(color_table) gt 0) then begin
    ctab = fix(color_table[0])
    if (ctab ge 0 and ctab lt 1000) then loadct2,ctab,previous_ct=pct,reverse=crev,previous_rev=prev
    if (ctab ge 1000) then loadcsv,ctab,previous_ct=pct,reverse=crev,previous_rev=prev,/silent
  endif else begin
    ctab = cols.color_table
    pct = ctab
    if (crev) then begin
      if (ctab ge 0 and ctab lt 1000) then loadct2,ctab,previous_ct=pct,reverse=crev,previous_rev=prev
      if (ctab ge 1000) then loadcsv,ctab,previous_ct=pct,reverse=crev,previous_rev=prev,/silent
    endif else begin
      crev = cols.color_reverse
      prev = crev
    endelse
  endelse

  usersym,[-1,-1,1,1,-1],[-1,1,1,-1,-1],/fill
  win,/free,/secondary,xsize=600,ysize=600,dx=10,dy=-10
  plot,[-1],[-1],xrange=[0,4],yrange=[0.5,6.5],xstyle=5,ystyle=5,$
                 xmargin=[0.1,0.1],ymargin=[0.1,0.1]
  k = indgen(16)*16
  for j=0,15 do for i=k[j],k[j]+15 do oplot,[float(i mod 16)/4.5 + 0.35],[6. - float(j)/3.],$
                                            psym=8,color=i,symsize=4

  usersym,[-1,-1,1,1,-1],[-1,1,1,-1,-1]
  for j=0,15 do for i=k[j],k[j]+15 do oplot,[float(i mod 16)/4.5 + 0.35],[6. - float(j)/3.],$
                                            psym=8,color=!p.color,symsize=4,thick=2

  msg = 'Color Table ' + strtrim(string(ctab),2)
  if (crev) then msg = msg + ' (reverse)'
  xyouts,2.0,6.25,msg,align=0.5,charsize=1.8

  x = 0.23
  y = 5.97 - findgen(16)/3.
  nums = strtrim(string(16*indgen(16)),2)
  for i=0,15 do xyouts,x,y[i],nums[i],align=1.0,charsize=1.2

  if (ctab ne pct || crev ne prev) then $
    if (pct lt 1000) then loadct2,pct,reverse=prev else loadcsv,pct,reverse=prev,/silent

end
