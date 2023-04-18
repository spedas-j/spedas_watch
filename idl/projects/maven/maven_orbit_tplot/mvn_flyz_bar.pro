;+
;PROCEDURE:   mvn_flyz_bar
;PURPOSE:
;  Creates a bar indicating planned times of fly-plus-Z.  Time ranges
;  are drawn from the Science Constraints spreadsheet, which is
;  produced by Lockheed Martin once a year in mid-summer.  You can
;  find the latest spreadsheet (sci_constraints_YYYY.xlsx) here:
;
;    https://lasp.colorado.edu/galaxy/display/MAVEN/Science+Operations+Spreadsheets
;
;  You need to have a MAVEN account on Galaxy to access this file.
;
;USAGE:
;  mvn_flyz_bar
;
;INPUTS:
;       none
;
;KEYWORDS:
;       COLOR:    Bar color index.  Default is the current foreground color.
;                 This can be changed later using options.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2023-04-17 12:35:14 -0700 (Mon, 17 Apr 2023) $
; $LastChangedRevision: 31756 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/mvn_flyz_bar.pro $
;
;CREATED BY:    David L. Mitchell
;-
pro mvn_flyz_bar, color=color

  bname = 'mvn_flyz_bar'

  tstart = time_double(['2022-11-03','2023-04-06','2023-08-03'])
  tstop  = time_double(['2022-12-29','2023-06-15','2023-10-19'])
  oneday = 86400D
  ndays = floor((max(tstop) - min(tstart))/oneday) + 3L
  t = min(tstart) + oneday*(dindgen(ndays) - 1L)

  y = replicate(!values.f_nan,ndays)
  for i=0L,(n_elements(tstart)-1L) do begin
    indx = where((t ge tstart[i]) and (t lt tstop[i]), count)
    if (count gt 0L) then y[indx] = 3.
  endfor

  store_data,bname,data={x:t, y:y}
  ylim,bname,0,6,0
  options,bname,'ytitle',''
  options,bname,'no_interp',1
  options,bname,'thick',8
  options,bname,'xstyle',4
  options,bname,'ystyle',4
  if keyword_set(color) then options,bname,'colors',fix(color[0])
  
  return

end
