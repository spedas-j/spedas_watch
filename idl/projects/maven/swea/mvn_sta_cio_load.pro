;+
;PROCEDURE:   mvn_sta_cio_load
;PURPOSE:
;  Loads all available MAVEN cold ion outflow data that were 
;  processed by mvn_sta_coldion.pro.
;
;INPUTS:
;     ptr   : A named variable to hold a pointer to the data.
;  species  : Which database to load?  ('h', 'o1', 'o2')
;
;KEYWORDS:
;
;    FROOT  : File root for save file (e.g., 'cio_ABCD_').
;
;     TAGS  : A named variable to hold a string array of the names
;             of the data structure tags.
;
;     NPTS  : A named variable to hold the number of data points.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2018-03-16 10:41:25 -0700 (Fri, 16 Mar 2018) $
; $LastChangedRevision: 24895 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_sta_cio_load.pro $
;
;CREATED BY:	David L. Mitchell
;FILE:  mvn_sta_cio_load.pro
;-
pro mvn_sta_cio_load, ptr, species, froot=froot, tags=tags, npts=npts

  mvn_sta_cio_clear, ptr
  path = '/Users/mitchell/Documents/Home/Mars/MAVEN/Cold Ion Outflow/'
  if (size(froot,/type) ne 7) then froot = 'cio_ABCD_'

  if (size(species,/type) ne 7) then species = 'O2' else species = strupcase(species[0])
  case species of
    'H'  : fname = path + froot + 'h.sav'
    'O1' : fname = path + froot + 'o1.sav'
    'O2' : fname = path + froot + 'o2.sav'
    else : begin
             print,'Species not recognized: ',species
             return
           end
  endcase

  finfo = file_info(fname)
  if (~finfo.exists) then begin
    print," Can't find data file: ",fname
    return
  endif   

  print,'  Reading data ... ',format='(a,$)'
  restore, fname
  print,'done.'

  case species of
    'H'  : data = temporary(cio_h)
    'O1' : data = temporary(cio_o1)
    'O2' : data = temporary(cio_o2)
    else : begin
             print,'Unrecognized variable name.'
             return
           end
  endcase

; Convert from array of structures to structure of arrays

  mvn_sta_cio_convert, data

; Make sure it is a pointer

  if (data_type(data) eq 8) then data = ptr_new(data,/no_copy)
  if (data_type(data) ne 10) then begin
    print,'  No data structure found.'
    return
  endif

; Report the result and return

  ptr = data
  print,''

  return

end
