;$Author: nikos $
;$Date: 2014-09-03 15:05:59 -0700 (Wed, 03 Sep 2014) $
;$Header: /home/cdaweb/dev/control/RCS/Compare_myCDFs.pro,v 1.4 2012/05/15 16:41:43 johnson Exp johnson $
;$Locker: johnson $
;$Revision: 15739 $
;This file contains a utility function to compare two cdfs and determine
;whether they are structurally the same...
;
;+------------------------------------------------------------------------
; NAME: compare_mycdfs
; PURPOSE:
;       To compare all record varying variables in two CDF files, and
;       to determine if these variables are similarly named, typed, and
;       dimensioned.
; CALLING SEQUENCE:
;       out = compare_mycdfs(cid1,cid1)
; INPUTS:
;       cid1 = the id of a CDF file which has already been opened.
;       cid2 = the id of a second CDF file which has already been opened.
; KEYWORD PARAMETERS:
; OUTPUTS:
;       out = TRUE/FALSE value indicating if the CDFs are equivalently
;             structured or not.  1 = equivalent, 0 = NOT equivalent
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 13, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;       11/1/96 R. Burley       Improved the comparison logic, so that
;                               variable order does not matter, and so that
;                               additional non-record-varying variables do
;                               not cause a comparison failure.
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------
;
FUNCTION Compare_myCDFs, cid1, cid2
vnames = get_allvarnames(CDFID=cid1) ; get the names of all vars in first CDF
for i=0L,n_elements(vnames)-1 do begin
  v1info = cdf_varinq(cid1,vnames[i])
  if v1info.RECVAR eq 'VARY' then begin ; search for corresponding variable

    ; Establish an error handler to trap cases where the second CDF does not
    ; have a variable by the same name as the first CDF.
    Error_status = 0
    CATCH, Error_status
    if Error_status ne 0 then begin
      print,'ERROR> The variable ',vnames[i],' does not exist in second CDF.'
      return,0
    endif
    v2info = cdf_varinq(cid2,v1info.NAME)

    ; Compare the structure of the two variables
    if v1info.DATATYPE ne v2info.DATATYPE then begin
      print,'ERROR> The vars named ',vnames[i],' have different datatypes.'
      return,0
    endif
    if v1info.NUMELEM ne v2info.NUMELEM then begin
      if v1info.DATATYPE ne 'CDF_CHAR' then begin ; strlen doesn't matter
        print,'ERROR> The vars named ',vnames[i],' have different numelems.'
        return,0
      endif
    endif
    if v1info.RECVAR ne v2info.RECVAR then begin
      print,'ERROR> The vars named ',vnames[i],' have different r-variance.'
      return,0
    endif
    v1size = size(v1info.DIMVAR) & v2size = size(v2info.DIMVAR)
    if n_elements(v1size) ne n_elements(v2size) then begin
      print,'ERROR> The vars named ',vnames[i],' have != number of dimensions.'
      return,0
    endif else begin
      for j=0,n_elements(v1size)-1 do begin
        if v1size(j) ne v2size(j) then begin
          print,'ERROR> The vars named ',vnames[i],' have different dim sizes.'
          return,0
        endif
      endfor
    endelse
  endif
endfor
return,1
end
