;$Author: nikos $
;$Date: 2014-09-03 15:05:59 -0700 (Wed, 03 Sep 2014) $
;$Header: /home/cdaweb/dev/control/RCS/plot_spectrogram.pro,v 1.116 2014/02/27 17:13:52 johnson Exp kovalick $
;$Locker: kovalick $
;$Revision: 15739 $
;+------------------------------------------------------------------------
; NAME: PLOT_SPECTROGRAM
; PURPOSE: To generate a spectrogram plot given the anonymous structures
;          returned by the read_mycdf function.
; CALLING SEQUENCE:
;       out = plot_spectrogram(Xstruct,Ystruct,Zstruct)
; INPUTS:
;       Xstruct = structure containing the Epoch variable structure of the
;                 type returned by the read_mycdf structure.
;       Ystruct = structure containing the variable to be plotted against
;                 the Epoch variable in the Xstruct parameter
;       Zstruct = structure containing the variable to be plotted as Z.
; KEYWORD PARAMETERS:
;	TSTART   = Forces the time axis to begin at this Epoch time.
;	TSTOP    = Forces the time axis to end at this Epoch time.
;	ELEMENTS = if set, then only these elements of a dimensional variable
;                  will be plotted.
;	POSITION = If set, this routine will draw the plot(s) at this position
;                  of an existing window, rather than open a new one.
;       FIRSTPLOT= Use this key in conjunction with the position keyword. Set
;                  this flag to indicate that the variable is the first in the
;                  window.
;       LASTPLOT = Use this key in conjunction with the position keyword. Set
;                  this flag to indicate that the variable is the last in the
;                  window.
;       PANEL_HEIGHT = vertical height, in pixels, of each panel
;	CDAWEB   = If set, the plot will have sufficient margin along the Z
;                  axis to hold a colorbar.
;       GIF      = If set, the plot will be a .gif file instead of Xwindow
;	XSIZE    = if set, forces the plot window to this width
;       YSIZE    = if set, forces the plot window to this height
;	AUTO     = if set, turns auto-scaling on
;       NOGAPS   = if set, eliminates data gap scanning
;       NOCLIP   = set when writing to GIF file
;       IGNORE_DISPLAY_TYPE = if set, causes the attribute display_type to
;			      be ignored.
;	NOSUBTITLE = if set, will not print 'time range = ' subtitle even after
;			the last graph. Needed for timetext case. RCJ
;	COMBINE = if set, need to add the dataset name to the y axis label
;		  added 10/22/2003 - TJK.	
;       DEBUG    = if set, turns on additional debug output.
; OUTPUTS:
;       out = status flag, 0=0k, -1 = problem occured.
; AUTHOR:
;       Richard Burley, NASA/GSFC/Code 632.0, Feb 22, 1996
;       burley@nssdca.gsfc.nasa.gov    (301)286-2864
; MODIFICATION HISTORY:
;       8/20/96  R. Burley      : Reform the epoch data if retrieved from
;                               : a handle to remove spurious extra dim. 
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------
;
;TJK 05/12/99
;added two functions to find the next or previous "valid" time value
function findprev, times, t
for i = t-1, 0, -1 do begin
   if (times[i] gt 0) then return, i
endfor
return, -1
end

function findnext, times, t
for i = t+1, n_elements(times)-1 do begin
   if (times[i] gt 0) then return, i
endfor
return, -1
end

FUNCTION plot_spectrogram, Xvar, Yvar, Zvar, $
                          TSTART=TSTART,TSTOP=TSTOP,ELEMENTS=ELEMENTS,$
                          POSITION=POSITION,PANEL_HEIGHT=PANEL_HEIGHT,$
                          FIRSTPLOT=FIRSTPLOT,LASTPLOT=LASTPLOT,$
                          CDAWEB=CDAWEB,GIF=GIF,NOCLIP=NOCLIP,$
                          XSIZE=XSIZE,YSIZE=YSIZE,COMBINE=COMBINE,$
                          ;QUICK=QUICK,SLOW=SLOW,SMOOTH=SMOOTH,AUTO=AUTO,$
                          QUICK=QUICK,SLOW=SLOW,AUTO=AUTO,$
                          IGNORE_DISPLAY_TYPE=IGNORE_DISPLAY_TYPE,$
                          FILLER=FILLER,NOSUBTITLE=NOSUBTITLE, NPANELS=NPANELS, $
                          DEBUG=DEBUG,_EXTRA=EXTRA

; Verify that both Xvar and Yvar are present
if (n_params() ne 3) then begin
   print,'ERROR=missing parameter to plot_spectrogram function' & return,-1
endif
;if(keyword_set(CDAWEB)) then GIF=1L  ;RTB added
; Verify the type of the first parameter and retrieve the data
a = size(Xvar)
if (a[n_elements(a)-2] ne 8) then begin
   print,'ERROR=1st parameter to plot_spectrogram not a structure' & return,-1
endif else begin
   a = tagindex('DAT',tag_names(Xvar))
   if (a[0] ne -1) then times = Xvar.DAT $
   else begin
      a = tagindex('HANDLE',tag_names(Xvar))
      if (a[0] ne -1) then begin
         handle_value,Xvar.HANDLE,times  
         sxz=size(times)
         if(sxz[0] ne 0) then times = reform(times)
      endif else begin
         print,'ERROR=1st parameter does not have DAT or HANDLE tag' & return,-1
      endelse
      b = size(times)
;TJK 8/2/2012 - add check for 9 and 14, epoch_16 and tt2000 respectively 
      if ((b[n_elements(b)-2] eq 5) or (b[n_elements(b)-2] eq 9) or $
        (b[n_elements(b)-2] eq 14)) then begin
          print, 'Epoch parameter ok'
      endif else begin
        print,'ERROR=1st parameter datatype not a CDF TIME related type' & return,-1
     endelse
   endelse
endelse


a = tagindex('FILLVAL',tag_names(Xvar))
if (a[0] ne -1 and (Xvar.FILLVAL ne '')) then Xfillval = Xvar.FILLVAL else Xfillval = -1.0e31

; Verify the type of the second parameter and retrieve the data
a = size(Yvar)
if (a[n_elements(a)-2] ne 8) then begin
   print,'ERROR=2nd parameter to plot_spectrogram not a structure' & return,-1
endif else begin
   YTAGS = tag_names(Yvar) ; avoid multiple calls to tag_names
   a = tagindex('DAT',YTAGS)
   if (a[0] ne -1) then THEENERGY = Yvar.DAT $
   else begin
      a = tagindex('HANDLE',YTAGS)
      if (a[0] ne -1) then handle_value,Yvar.HANDLE,THEENERGY else begin
         print,'ERROR=2nd parameter does not have DAT or HANDLE tag' & return,-1
      endelse
   endelse
endelse

; Verify the type of the third parameter and retrieve the data
a = size(Zvar)
if (a[n_elements(a)-2] ne 8) then begin
   print,'ERROR=3rd parameter to plot_spectrogram not a structure' & return,-1
endif else begin
   ZTAGS = tag_names(Zvar) ; avoid multiple calls to tag_names
   a = tagindex('DAT',ZTAGS)
   if (a[0] ne -1) then THEDATA = Zvar.DAT else begin
      a = tagindex('HANDLE',ZTAGS)
      if (a[0] ne -1) then handle_value,Zvar.HANDLE,THEDATA else begin
         print,'ERROR=3rd parameter does not have DAT or HANDLE tag' & return,-1
      endelse
   endelse
endelse

;TJK 6/27/2007 - add capability to check for new display_type keywords
;reverse_yaxis or reverse_zaxis - this means what it says, it will
;flip the axis min/max and values - added for stereo_l2 data
y_reverse = 0L & z_reverse = 0L
b = tagindex('DISPLAY_TYPE',ZTAGS)
if (b[0] ne -1) then begin ; evaluate the display type
  if(strpos(strupcase(Zvar.DISPLAY_TYPE),'REVERSE_ZAXIS') ne -1) then z_reverse=1L
endif
if (b[0] ne -1) then begin ; evaluate the display type
  if(strpos(strupcase(Zvar.DISPLAY_TYPE),'REVERSE_YAXIS') ne -1) then y_reverse=1L
endif

; Eliminate time overlaps, if any.  RCJ 11/14/2008
if keyword_set(DEBUG) then print,'Eliminating time overlaps, if any.........'
; What we want to do is turn something like:
; times=[1,2,3,4,5,6,7,5,6,7,8,9,10,11,12,13,11,12,13]
; into
; times=[1,2,3,4,5,6,7,8,9,10,11,12,13]
; Overlaps are introduced when one cdf ends and another begins.
; 
if n_elements(times) ne 1 then begin
   ntimes=times
   nthedata=thedata
   nt=times[1:*]-times ;differnce in times[0] vs. times[1], etc.
   dim=size(thedata,/dimensions)
   done=0
   q=where(nt le 0) ; where no good data
   if q[0] eq -1 then done=1
   ttt=systime(1)
   while done eq 0 do begin
      q=where(nt gt 0) ;good times
      if n_elements(dim) eq 2 then begin ; 2D
        ntimes=ntimes[q] ; look at just the good times
        nthedata=nthedata[*,q]
        ntimes=[ntimes,times[n_elements(times)-1]]
        nthedata=[[nthedata],[thedata[*,dim[1]-1]]]
      endif
      if n_elements(dims) eq 3 then begin ; 3D
       qq=where(dim eq n_elements(times))
       case qq[0] of 
          0: begin
           nthedata=nthedata[q,*,*]
	   end
          1: begin
	   nthedata=nthedata[*,q,*]
	   end 
          2: begin
	   nthedata=nthedata[*,*,q]
	   end 
	endcase   
       ntimes=ntimes[q]
       ; missing last element. add it:
       ntimes=[ntimes,times[n_elements(times)-1]]
     endif 
      nt=ntimes[1:*]-ntimes
; q=where(nt le 0) ;TJK 5/6/2013 change to also look for fill values,
; otherwise stuck in this infinite while loop...
      q=where(nt le 0 and nt ne Xfillval)
      if q[0] eq -1 then done=1
   endwhile
   if keyword_set(DEBUG) then print,'done w/ while loop in ',systime(1)-ttt,' seconds.'
   times=ntimes
   thedata=nthedata
;help, times & print, 'DEBUG ',times

endif
; RCJ 03/15/2013  Code below used to work for 2D data only.
;if n_elements(times) ne 1 then begin
;   ntimes=times
;   nthedata=thedata
;   ;if n_elements(ntimes) eq 1 then begin
;   ;    if keyword_set(DEBUG) then print,'ERROR=Cannot plot. Only one time array element'
;   ;   return,0
;   ;endif   
;   nt=times[1:*]-times
;   dim=size(thedata,/dimensions)
;   done=0
;   q=where(nt le 0)
;   if q[0] eq -1 then done=1
;   ttt=systime(1)
;   while done eq 0 do begin
;      q=where(nt gt 0)
;      ntimes=ntimes[q]
;      nthedata=nthedata[*,q]
;      ; missing last element. add it:
;      ntimes=[ntimes,times[n_elements(times)-1]]
;      nthedata=[[nthedata],[thedata[*,dim[1]-1]]]
;      nt=ntimes[1:*]-ntimes
;      q=where(nt le 0)
;      if q[0] eq -1 then done=1
;   endwhile
;   if keyword_set(DEBUG) then print,'done w/ while loop in ',systime(1)-ttt,' seconds.'
;   times=ntimes
;   thedata=nthedata
;endif
;
; Verify type of data and determine the number of panels that will be plotted
; and which elements of the data array are to be plotted.
a = size(thedata) & b = a[n_elements(a)-2] & thedata_size = a
c = size(theenergy) & d = c[n_elements(c)-2] & theenergy_size = c

if keyword_set(DEBUG) then begin
   print,'SIZE OF THEDATA=',a     ;debug
   print,'SIZE OF THEENERGY=',c   ;debug
endif

;print, d, n_elements(c)-2 

;if ((b eq 0) OR (b gt 5)) then begin  
; RCJ 02/02 Need to include data type 13 to plot ulysses data:
if ((b eq 0) OR ((b gt 5) and (b lt 12))) then begin
   print,'ERROR=datatype indicates that Z axis var not plottable' & return,-1
endif
;if ((d eq 0) OR (d gt 5)) then begin  
; RTB  2/99  IDL 5.2 changed meaning of size{type} from Int to UInt
if ((d eq 0) OR ((d gt 5) and (d lt 12))) then begin
   print,'ERROR=datatype indicates that Y axis var not plottable' & return,-1
endif
; Determine the number of panels
use_zlist = 0L

; RCJ 02/12/2013  Note: If plot_spectrogram is called by plotmaster then the number of panels is already
; determined and passed in through the keyword npanels.
case a[0] of
  0   : begin
           print,'ERROR=single data points are not plottable' & return,-1
        end
  1   : begin
           print,'ERROR=single spectra points are not plottable' & return,-1
        end
  ; 2   : elist = 0 ; single panel spectrogram
  2   : begin
           elist = 0 & igram = 0L & bgram = 0L; assume single panel spectrogram
           b = tagindex('DISPLAY_TYPE',ZTAGS)
           if (b[0] ne -1) then begin ; evaluate the display type
              dtype = examine_spectrogram_dt(Zvar.DISPLAY_TYPE, thedata=thedata, data_fillval=zvar.fillval, $
	               valid_minmax=[zvar.VALIDMIN, zvar.VALIDMAX], debug=debug)
	      d=size(dtype)
              if (d[n_elements(d)-2] eq 8) then elist = dtype.elist
              if(strpos(strupcase(Zvar.DISPLAY_TYPE),'TOPSIDE') ne -1) then igram=1L
              if(strpos(strupcase(Zvar.DISPLAY_TYPE),'BOTTOMSIDE') ne -1) then begin
                 igram=1L
                 bgram=1L
              endif
           endif
           ;rint, "igram ", igram, bgram
        end
  3   : begin ; #panels determined by dimensionality or by display type
           b = tagindex('DISPLAY_TYPE',ZTAGS)
           if (b[0] ne -1) then begin ; evaluate the display type
              dtype = examine_spectrogram_dt(Zvar.DISPLAY_TYPE, thedata=thedata, data_fillval=zvar.fillval, $
	               valid_minmax=[zvar.VALIDMIN, zvar.VALIDMAX], debug=debug)
	      d=size(dtype)
              if (d[n_elements(d)-2] eq 8) then elist = dtype.elist
           endif else elist = indgen(a[1]) ; all elements
           if (dtype.igram eq 1) then igram = 1L  else igram = 0L
           bgram=0
           if (dtype.dvary gt -1) then vary_dim = dtype.dvary
        end
  4   : begin ; #panels determined by dimensionality or by display type
           b = tagindex('DISPLAY_TYPE',ZTAGS)
           if (b[0] ne -1) then begin ; evaluate the display type
              dtype = examine_spectrogram_dt(Zvar.DISPLAY_TYPE, thedata=thedata, data_fillval=zvar.fillval, $
	               valid_minmax=[zvar.VALIDMIN, zvar.VALIDMAX], debug=debug) 
	      d=size(dtype)
              if (d[n_elements(d)-2] eq 8) then use_zlist = 1
           endif else elist = indgen(a[1]) ; all elements
           if (dtype.igram eq 1) then igram = 1L  else igram = 0L
           bgram=0
           varys = where((dtype.dvary eq 1), wc)
           if (wc gt 0) then vary_dim = dtype.dvary
        end
  5   : begin ; #panels determined by dimensionality or by display type
           b = tagindex('DISPLAY_TYPE',ZTAGS)
           if (b[0] ne -1) then begin ; evaluate the display type
              dtype = examine_spectrogram_dt(Zvar.DISPLAY_TYPE, thedata=thedata, data_fillval=zvar.fillval, $
	               valid_minmax=[zvar.VALIDMIN, zvar.VALIDMAX], debug=debug) 
	      d=size(dtype)
              if (d[n_elements(d)-2] eq 8) then use_zlist = 1
           endif else elist = indgen(a[1]) ; all elements

           if (dtype.igram eq 1) then igram = 1L  else igram = 0L
           bgram=0
           varys = where((dtype.dvary eq 1), wc)
           if (wc gt 0) then vary_dim = dtype.dvary

        end
  else: begin           print,'ERROR=cannot plot data with > 5 dimensions' & return,-1
        end
endcase
; Hack for FAST RTB 7/97 - TJK extended to DE 7/97
; TJK - 7/22/97 - also changed variable "fast_gram" to "scale_gram";
; had to also change the determination of the temp_str since the length
; of the Source_name varies...  Source_name looks like 'DE>Dynamics Explorer'
; so we're looking at the character string before the ">"

;
;TJK 02/21/2001 - finally found the source of the problem for trying to use the xmin/max and 
;ymin/max and yfillval keywords so we are going to use the "scale_gram" option for all spacecraft
;except ISIS (for now).
;
temp_str = strmid(Yvar.SOURCE_NAME,0,strpos(Yvar.Source_name, '>'))

if (temp_str eq 'ISIS') then scale_gram = 0 else scale_gram = 1

;if((temp_str eq 'FAST') or (temp_str eq 'DE') or (temp_str eq 'IMAGE') or (temp_str eq 'GEOTAIL')); then scale_gram = 1 else scale_gram = 0

if(n_elements(scale_gram) eq 0) then scale_gram=0

;if (use_zlist) then num_panels = n_elements(dtype.zelist1) $
;else num_panels = n_elements(elist)
if not keyword_set(npanels) then begin
  if (use_zlist) then num_panels = n_elements(dtype.zelist1) $
  else num_panels = n_elements(elist)
endif else num_panels=npanels  

; Determine the average time resolution in seconds
nt = n_elements(times)
resolution = ((times[nt-1] - times[0]) / nt) / 1000.0

;TJK**greatly modified this section
; Determine the proper start and stop times of the plot
tbegin = times[0] & tend = times[n_elements(times)-1] ; default to data

if keyword_set(TSTART) then begin ; set tbegin
  tbegin = TSTART & tbegin16 = TSTART & tbegintt = TSTART & a = size(TSTART)
  if (a[n_elements(a)-2] eq 7) then begin ;if tstart is a string, convert it
     split_ep=strsplit(TSTART,'.',/extract)
    tbegin = encode_CDFEPOCH(TSTART)
    tbegin16 = encode_CDFEPOCH(TSTART,/EPOCH16,msec=split_ep[1]);TJK added for use when data is epoch16
    tbegintt = encode_cdfepoch(TSTART, /TT2000, MSEC=split_ep[1]) ;TJK added for TT2000 time
  endif
endif

if keyword_set(TSTOP) then begin ; set tend
   tend = TSTOP & tend16 = TSTOP & tendtt= TSTOP & a = size(TSTOP)
   if (a[n_elements(a)-2] eq 7) then begin ;if tstop is a string, convert it
    split_ep=strsplit(TSTOP,'.',/extract)
     tend = encode_CDFEPOCH(TSTOP)
     tend16 = encode_CDFEPOCH(TSTOP,/EPOCH16,msec=split_ep[1]);TJK added for use when data is epoch16
     tendtt = encode_cdfepoch(TSTOP, /TT2000, MSEC=split_ep[1]) ;TJK added for TT2000 time
   endif
endif
;TJK***end of modified section

print, 'From tstart and tstop keywords: tbegin, tend ', tbegin, tend 

;TJK 8/2/2012 - add code to handle new time datatypes Epoch16 and TT2000

ep16 = 0 & eptt=0
if (size(times[0],/tname) eq 'DCOMPLEX')then begin
    ep16 = 1
    tend = tend16
    tbegin = tbegin16
 endif
if (size(times[0],/tname) eq 'LONG64')then begin
    eptt = 1
    tend = tendtt
    tbegin = tbegintt
 endif

print, 'DEBUG in plot_spectrogram, ep16 and eptt = ',ep16, eptt
print, 'DEBUG in plot_spectrogram, tbegin and tend = ',tbegin, tend
; Compare the range of the time data to the requested start and stop times
; Pad 1st value; changed lt to le and gt ge (may change back) RTB 11/96 
pad_front = 0L & pad_end = 0L

if(igram eq 1) then begin
   i = lindgen(n_elements(times)-1) & w = where(times[i] gt times[i+1],wc)
   if (wc gt 0) then begin
      if keyword_set(DEBUG) then print,'WARNING=Repairing',wc,' backward time steps'
      for j=0,wc-1 do begin ; process each back step
         ;   ; locate where the data after the break overlaps the data before the break
         ;   ; and flag the overlapped times by zeroing out the times fields
         b = where(times ge times[w[j]+1],bc) & times[w[j]+1] = 0.0D0
      endfor
      ; ; Scrub out the data where the times array was set to zero
      w = where(times ne 0.0D0) & times=times[w] 
   endif
   if(tbegin lt times[0]) then tbegin=times[0]  ; Set start time for Ionograms
   if(tend gt times[n_elements(times)-1]) then $
              tend=times[n_elements(times)-1] ;Set end time for Ionograms
endif else begin

   ;TJK look for any times that aren't valid and replace them w/ a
   ;reasonable number (not a fill value). Start w/ the 2nd value
   bad = where(times le 0, nbad)
   if (nbad gt 0) then begin
      print, 'Found ',nbad,' fillvalue time records, replacing w/ averaged times.'
      ;TJK force this data to use exact x and y scale ranges by setting
      ;scale_gram to 1, otherwise w/ all of the fill data, the x range gets 
      ;extended way to far and produces incorrect plots.
      scale_gram = 1
      size_times = n_elements(times)-1
      for t = 0L, size_times do begin
         if (times[t] le 0) then begin
	    if (t eq 0) then times[t] = tbegin
	    if (t ge 1 and t lt size_times) then begin
	       prev = findprev(times, t)
	       next = findnext(times, t)
	       ;if fill at the beginning or out to the end then just
	       ;assign the begin or end requested time to times...
               if ((prev eq -1) and (next ge 0)) then $
	          times[t] = (tbegin+times[next])/2
       	       if ((prev ge 0) and (next eq -1)) then $
	          times[t] = (times[prev]+tend)/2
               if (next ge 0 and prev ge 0) then $
	          times[t] = (times[prev] + times[next])/2
	    endif
	    if (t eq size_times) then times[t] = tend
         endif
      endfor
   endif

 if (!version.release ge '6.2' and (ep16 or eptt)) then begin
  if (cdf_epoch_compare(times[0], tbegin)) then begin
    if keyword_set(DEBUG) then print,'Padding front of times...'
    times = [tbegin,times] & pad_front = 1L
  endif
  if (cdf_epoch_compare(tend, times[n_elements(times)-1])) then begin
    if keyword_set(DEBUG) then print,'Padding end of times...'
    times = [times,tend] & pad_end = 1L
  endif
 endif else begin
   if (tbegin lt times[0]) then begin
      times = [tbegin,times] & pad_front = 1L
   endif
   if (tend gt times[n_elements(times)-1]) then begin
      times = [times,tend] & pad_end = 1L
   endif
 endelse 
endelse 

; Determine the first and last data time points to be plotted
;the where statement doesn't work on complex doubles (epoch 16)
;so use our new cdf_epoch_compare (which returns 1 if the values are greater)
rbegin = 0L  
;w = where(times ge tbegin,wc)
w = where((cdf_epoch_compare(times, tbegin) ge 0), wc)
if (wc gt 0) then rbegin = w[0]
rend = n_elements(times)-1 
;w = where(times le tend,wc)
w = where((cdf_epoch_compare(times, tend) le 0),wc)
if (wc gt 0) then rend = w[n_elements(w)-1]
if (rbegin ge rend) then begin
   print,'ERROR=No data within specified time range.'  
   plot,[0,1],[0,1],/nodata,ystyle=8+4,xstyle=8+4
   deviceclose  
   return,-1
endif

if(igram eq 1) then begin
   tdif=double(tend-tbegin)
   ; define this RTB 10/96
   ; tdel=46000
   tdel= 90000 ; ms by default. May have variable field name in cdf to 
   if(tdif le 9000.D) then begin 
      print, "STATUS=< 10 sec. of data available for selected interval"
      return, -1
   endif
   ;if(tdif gt 900000) then print, "STATUS=15 min. maximum ionogram interval"
   if(tdif lt tdel) then tdel=tdif
   num_panels=ceil(tdif/tdel)
   
   for jj=tbegin,tend,tdel do begin
      w = where((times ge jj) and (times le jj+tdel))
      if (w[0] eq -1) then begin
         ;print,'ERROR=No data within specified time range. setting: num_panels-1
	 num_panels=num_panels-1
      endif
   endfor
   
   ; the next 3 lines were executed when we did not want less than 5 min
   ; in one panel:
   ;num_panels=fix(tdif/tdel)
   ;pan_dif=tdif-num_panels*tdel
   ;if(pan_dif gt 5000) then num_panels=num_panels+1
   if(num_panels gt 10) then begin
      num_panels=10 
      print, "WARNING: Not more than 10 panels can be generated at a time" 
   endif  
   ; scale=num_panels*PANEL_HEIGHT    ; Add an extra panel in case freq is 
   ;scale=(num_panels+1)*PANEL_HEIGHT+40 ; being plotted in plot_timeseries 
   scale=(num_panels)*(PANEL_HEIGHT+30) ; RCJ 02/25/2009  Trying new scale to go w/
                                        ; addition of 'date' to label tick marks.
   sizeWindow=[640,scale+!d.y_size]
   if(!D.name eq 'Z') then begin 
      device,set_resolution=sizeWindow,set_colors=240,set_char=[6,11], $
      z_buffering=0
   endif
endif

if not (keyword_set(nosubtitle)) then begin
  ; Create a subtitle for the plots showing the data start and stop times
  ; TJK 8/9/2012 - add code to handle tt2000 values
  if (not eptt) then begin
   ; Create a subtitle for the plots showing the data start and stop times
    CDF_EPOCH,tbegin,byear,bmonth,bday,hour,minute,second,milli,/BREAK
    CDF_EPOCH,tend,eyear,emonth,eday,hour,minute,second,milli,/BREAK
 endif else begin ;if tt2000, can still call cdf_epoch but need to specifiy tointeger
    CDF_EPOCH,tbegin,byear,bmonth,bday,hour,minute,second,milli,/TOINTEGER,/BREAK
    CDF_EPOCH,tend,eyear,emonth,eday,hour,minute,second,milli,/TOINTEGER,/BREAK
 endelse

   ical,byear,doy,bmonth,bday,/idoy
   subtitle = 'TIME RANGE='+strtrim(string(byear),2)+'/'+strtrim(string(bmonth),2)
   subtitle = subtitle + '/' + strtrim(string(bday),2)
   subtitle = subtitle + ' (' + strtrim(string(doy),2) + ') to '

   ical,eyear,doy,emonth,eday,/idoy
   subtitle = subtitle + strtrim(string(eyear),2)+'/'+strtrim(string(emonth),2)
   subtitle = subtitle + '/' + strtrim(string(eday),2)
   subtitle = subtitle + ' (' + strtrim(string(doy),2) + ')'
endif else subtitle=''

; Convert the time array into seconds since tbegin
if (not eptt) then begin
  CDF_EPOCH,tbegin,year,month,day,hour,minute,second,milli,/BREAK
  CDF_EPOCH,idlep,year,month,day,0,0,0,0,/COMPUTE_EPOCH ;a is the beginning of the day
endif else begin
  CDF_EPOCH,tbegin,year,month,day,hour,minute,second,milli,/BREAK, /TOINTEGER
  CDF_EPOCH,idlep,year,month,day,0,0,0,0,/COMPUTE,/TT2000 ;a is the beginning of the day
endelse
;CDF_EPOCH,tbegin,year,month,day,hour,minute,second,milli,/BREAK
;CDF_EPOCH,idlep,year,month,day,0,0,0,0,/COMPUTE_EPOCH

;****
;TJK 8/9/2012 - new section to "do the math" on the epoch16 values
if (ep16)then begin 
  CDF_EPOCH16,b,year,month,day,0,0,0,0,0,0,0,/COMPUTE_EPOCH ;a for epoch16
  ;lets try cdf_epoch_diff now that it works w/ arrays
  if keyword_set(DEBUG) then tatime = systime(1)
  ep_diff = cdf_epoch_diff (times, b, /micro_seconds)
  temp2 = ep_diff/1000000.d0
  if keyword_set(DEBUG) then print, 'Took ',systime(1)-tatime, ' seconds to compute time difference WITH NEW cdf_epoch_diff'
;help, temp2
;n_times = n_elements(temp2)
;print, 'end times = ',temp2(n_times-5:n_times-1)
    times = temp2

endif else if (eptt) then begin ;this is the computation for cdf_tt2000
    times  = (times - idlep) / 1000000000.d0 ; int in seconds from first of day
    ;print, 'TT2000 beginning times = ',times[0:5]
 endif else begin
    times  = (times - idlep) / 1000.d0 ; double in seconds from first of day
endelse
;****
;done above times  = (times - idlep) / 1000
julday = ymd2jd(year,month,day)

; Determine label for time axis based on time range

xranger = dblarr(2)  ; RTB 4/97 changed this from long to double 

;TJK 8/9/2012 - if ep16, replace w/ the "real parts" of the 1st and last element
;of the times array, which was already "converted" (reduced by idlep
;and 1000000000.d0 ) above.
if (ep16 or eptt) then begin
  xranger[0] = times[0]
  xranger[1] = times[n_elements(times)-1]
print, 'times[0] =',times[0]
endif else begin
  xranger[0] = (tbegin-idlep)/1000
  xranger[1] = (tend-idlep)/1000
endelse

if(igram ne 1) then begin
   trange = xranger[1] - xranger[0]
   if (trange le 60.0) then tform='h$:m$:s$.f$@y$ n$ d$' $
      else tform='h$:m$:s$@y$ n$ d$'
;endif else tform='h$:m$:s$'
endif else tform='h$:m$:s$@y$ n$ d$'  ; RCJ 02/25/2009  Added date to tick marks 

; Determine if a new window should be opened for the plots
new_window = 1L ; initialize assuming a new window needs to be created
if keyword_set(POSITION) then begin ; adding to existing plot
   a = size(POSITION) & b = n_elements(a)
   if ((a[b-1] ne 4)OR(a[b-2] ne 3)) then begin
      print,'ERROR=Invalid value for POSITION keyword' & return,-1
   endif
   if keyword_set(PANEL_HEIGHT) then begin ; verify it
      a = size(PANEL_HEIGHT) & b = n_elements(a)
      if ((a[b-2] le 1)OR(a[b-2] gt 5)) then begin
         print,'ERROR=Invalid value for PANEL_HEIGHT keyword' & return,-1
      endif else psize = PANEL_HEIGHT
   endif else begin
      print,'ERROR=PANEL_HEIGHT keyword must be specified with POSITION keyword'
      return,-1
   endelse
   if keyword_set(FIRSTPLOT) then clear_plot = 0L else clear_plot = 1L
   new_window = 0L ; no new window needed
endif

; Determine the size of the new window to be created
if keyword_set(NOCLIP) then noclipflag = 1 else noclipflag = 0
if (new_window eq 1) then begin
   if keyword_set(GIF) then begin ; set default gif sizes
      xs = 640 & ys = 512 & noclipflag = 1
   endif else begin ; set default xwindow sizes
      a = lonarr(2) & DEVICE,GET_SCREEN_SIZE=a ; get device resolution
      xs = (a[0]*0.66) & ys = (a[1]*0.66) ; compute defaults
   endelse
   if keyword_set(XSIZE) then xs = XSIZE ; override if keyword present
   if keyword_set(YSIZE) then ys = YSIZE ; override if keyword present
   if keyword_set(PANEL_HEIGHT) then begin
      ys = (PANEL_HEIGHT * num_panels) + 100 & psize = PANEL_HEIGHT
   endif else begin
      psize = ((ys-100) / num_panels) ; leave space for time axis and title
   endelse
   if (psize lt 50) then begin ; sanity check for #pixels per panel
      print,'ERROR=Insufficient resolution for a ',num_panels,' panel plot'
      return,-1
   endif
endif

; Initialize plotting position arrays and flags
if keyword_set(POSITION) then ppos = POSITION else begin
   ppos    = fltarr(4)         ; create position array
   ppos[0] = 100               ; default plot x origin ;changed from 100
   ppos[2] = (xs - 40)         ; default plot x corner
   ppos[1] = (ys - 30) - psize ; 1st plot y origin
   ppos[3] = (ys - 30)         ; 1st plot y corner
   ppos[2] = xs - 100          ; set margin for spectrogram color bar
endelse
if(igram eq 1) then begin
   ppos[0]= 100  &  ppos[2]=!d.x_size-100
   ppos[1]= (!d.y_size - 60) - psize 
   ppos[3]= (!d.y_size - 60)
endif 
;print, "position;",ppos

; Determine the title for the window or gif file
if (new_window eq 1) then begin
   a = tagindex('SOURCE_NAME',ZTAGS)
   if (a[0] ne -1) then b = Zvar.SOURCE_NAME else b = ''
   a = tagindex('DESCRIPTOR',ZTAGS)
   if (a[0] ne -1) then b = b + '  ' + Zvar.DESCRIPTOR
   window_title = b
endif

; Create the new window or the gif file
if (new_window eq 1) then begin
   if keyword_set(GIF) then begin
      a = size(GIF) & if (a[n_elements(a)-2] ne 7) then GIF = 'idl.gif'
      deviceopen,6,fileOutput=GIF,sizeWindow=[xs,ys]
   endif else begin ; open x-window display
      window,/FREE,XSIZE=xs,YSIZE=ys,TITLE=window_title
      clear_plot = 0L ; initialize clear plot flag
   endelse
endif

; Determine the fill value for the Y and Z data
a = tagindex('FILLVAL',ZTAGS)
if (a[0] ne -1) then Zfillval = Zvar.FILLVAL else Zfillval = -1.0e31
a = tagindex('FILLVAL',YTAGS)
if (a[0] ne -1) then Yfillval = Yvar.FILLVAL else Yfillval = -1.0e31


; EXTRACT THE DATA FOR EACH PANEL AND PLOT
for i=0,num_panels-1 do begin
   ; extract data for a single panel from the data array
   ;TJK added the capability to use the elist (filter out individual
   ;energies/flux's/angles from different dimensions. 5/13/98
;   if (thedata_size[0] eq 2) then begin 
;      mydata = thedata 
;   endif else begin ;three dimensions
;      if (vary_dim eq 1) then mydata = thedata[(elist[i]-1),*,*]
;      if (vary_dim eq 0) then mydata = thedata[*,(elist[i]-1),*]
;   endelse
;   if (theenergy_size[0] le 2) then begin
;      myenergy = theenergy
;   endif else begin ;three dimensions
;      if (vary_dim eq 0) then myenergy = theenergy[*,(elist[i]-1),*]
;      if (vary_dim eq 1) then myenergy = theenergy[(elist[i]-1),*,*]
;   endelse

;TJK 12/11/2012 new section for more than three dimensions

   case (thedata_size[0]) of
      2: mydata = thedata 
      3: begin
           if (vary_dim eq 1) then mydata = thedata[(elist[i]-1),*,*]
           if (vary_dim eq 0) then mydata = thedata[*,(elist[i]-1),*]
         end
      4: begin
           if (vary_dim[0] eq 1) then mydata = thedata[*,dtype.zelist2[i]-1,dtype.zelist3[i]-1,*]
           if (vary_dim[1] eq 1) then mydata = thedata[dtype.zelist1[i]-1,*,dtype.zelist3[i]-1,*]
           if (vary_dim[2] eq 1) then mydata = thedata[dtype.zelist1[i]-1,dtype.zelist2[i]-1,*,*]
         end
      5: begin
           if (vary_dim[0] eq 1) then mydata = thedata[*,dtype.zelist2[i]-1,dtype.zelist3[i]-1,dtype.zelist4[i]-1,*]
           if (vary_dim[1] eq 1) then mydata = thedata[dtype.zelist1[i]-1,*,dtype.zelist3[i]-1,dtype.zelist4[i]-1,*]
           if (vary_dim[2] eq 1) then mydata = thedata[dtype.zelist1[i]-1,dtype.zelist2[i]-1,*,dtype.zelist4[i]-1,*]
           if (vary_dim[3] eq 1) then mydata = thedata[dtype.zelist1[i]-1,dtype.zelist2[i]-1,dtype.zelists3[i]-1,*,*]
         end
      else: begin print,'ERROR=cannot plot data with > 5 dimensions' & return,-1
            end
   endcase      
;end of new section for more than three dimensions
   
   if (theenergy_size[0] le 2) then begin
      myenergy = theenergy
   endif else begin ;three dimensions
      if (vary_dim eq 0) then myenergy = theenergy[*,(elist[i]-1),*]
      if (vary_dim eq 1) then myenergy = theenergy[(elist[i]-1),*,*]
   endelse
   ; remove any extraneous dimensions and determine new sizes
   mydata = reform(mydata)    & myenergy = reform(myenergy)
   mydata_size = size(mydata) & myenergy_size = size(myenergy)
   mydata_type = mydata_size[n_elements(mydata_size)-2]
   myenergy_type = myenergy_size[n_elements(myenergy_size)-2]
help, mydata
   ; pad the beginning and end of data if extra time points were added

   if (pad_front) then begin ; add fill point to front
      if (mydata_size[0] eq 2) then begin
         if keyword_set(DEBUG) then print,'Padding front of data...'
         fill = make_array(mydata_size[1],TYPE=mydata_type,VALUE=Zfillval)
         mydata=append_myDATA(mydata,fill,/vector) & mydata_size=size(mydata)
      endif
      if (myenergy_size[0] eq 2) then begin
         if keyword_set(DEBUG) then print,'Padding front of energy...'
         fill = make_array(myenergy_size[1],TYPE=myenergy_type)
         for b=0,myenergy_size[1]-1 do fill[b] = myenergy[b,0]
         myenergy=append_myDATA(myenergy,fill,/vector) & myenergy_size=size(myenergy)
      endif
   endif
   if (pad_end) then begin ; add fill point to back
      if (mydata_size[0] eq 2) then begin
         if keyword_set(DEBUG) then print,'Padding back of data...'
         fill = make_array(mydata_size[1],TYPE=mydata_type,VALUE=Zfillval)
         mydata=append_myDATA(fill,mydata,/vector) & mydata_size=size(mydata)
      endif
      if (myenergy_size[0] eq 2) then begin
         if keyword_set(DEBUG) then print,'Padding back of energy...'
         fill = make_array(myenergy_size[1],TYPE=myenergy_type)
         for b=0,myenergy_size[1]-1 do fill[b] = myenergy[b,0]
         myenergy=append_myDATA(fill,myenergy,/vector) & myenergy_size=size(myenergy)
      endif
   endif
   ; If ionogram increment through times
   reduction= 1000.D
   if (eptt) then reduction = 1000000000.d0 ;TJK 8/9/2012 - added for TT2000 support
   if(igram eq 1) then begin
    tryagain:  
      if(i eq 0) then tend_save=(tend-idlep)/reduction
      if(i ne 0) then tbegin=tend
      tend=tbegin+tdel
      ;print,"time ", tbegin, tend
      xranger[0] = (tbegin-idlep)/reduction
      xranger[1] = (tend-idlep)/reduction
      w=where(((times*reduction)+idlep ge tbegin) and ((times*reduction)+idlep le tend))
      if w[0] eq -1 then begin
         if tend ne rend then goto, tryagain
      endif	 

      ; Determine the average time resolution.
      mytimes=times[w]  ; mytimes will be redefined below
      nt = n_elements(mytimes)
      resolution = ((mytimes[nt-1] - mytimes[0]) / nt)    ; / 1000.0

      ; Pad last panel if needed
      mytimes=[xranger[0],times[w],xranger[1]] 
      if (mydata_size[0] eq 2) then begin
         if keyword_set(DEBUG) then print,'Padding back of ionogram data...'
	 mydata = mydata[*,w[0]:w[n_elements(w)-1]]
	 mydata_size=size(mydata)
         fill = make_array(mydata_size[1],TYPE=mydata_type,VALUE=Zfillval)
         mydata=append_myDATA(fill,mydata,/vector) 
         if keyword_set(DEBUG) then print,'Padding front of ionogram data...'
         mydata=append_myDATA(mydata,fill,/vector) 
      endif 
      if (myenergy_size[0] eq 2) then begin
         if keyword_set(DEBUG) then print,'Padding back of ionogram energy...'
         fill = make_array(myenergy_size[1],TYPE=myenergy_type)
         for b=0L,myenergy_size[1]-1 do fill[b] = myenergy[b,0]
         myenergy=append_myDATA(fill,myenergy,/vector) 
         if keyword_set(DEBUG) then print,'Padding front of ionogram energy...'
         myenergy=append_myDATA(myenergy,fill,/vector) 
      endif
      FILLER=1L
        
   endif else begin; end if ionogram
      ; screen out data points which are outside the plotting time range
      if (mydata_size[0] eq 2)   then mydata   = mydata[*,rbegin:rend]
      if (mydata_size[0] eq 3)   then mydata   = mydata[*,*,rbegin:rend]
      if (mydata_size[0] eq 4)   then mydata   = mydata[*,*,*,rbegin:rend]
      if (myenergy_size[0] eq 2) then myenergy = myenergy[*,rbegin:rend]
      mytimes = times[rbegin:rend]
  endelse

   ; recompute array sizing information
   mytimes_size  = size(mytimes)
   mydata_size   = size(mydata)
   myenergy_size = size(myenergy)


   ; When plotting spectrograms using the /QUICK keyword, the spectrogram
   ; function uses the TV command, and when not QUICK, it uses POLYFILL.
   ; When plotting QUICK, data gaps must be filled in if the spectrogram
   ; is to be vs. time instead of just by record number.  Determine if
   ; plotting in QUICK mode, and if so, fill in the data gaps in all arrays.
   if keyword_set(FILLER) then begin
      gaps = -1 
      gaps = find_gaps(mytimes,ratio=3.0) 
      a = size(gaps)
      if (a[0] eq 0) then done = 1 else done = 0
      if ((done eq 0)AND(keyword_set(DEBUG))) then begin
         print,'Filling in ',a[1],' data gaps...'
      endif
      while (done eq 0) do begin
         ; compute the number of fill points required to smooth the gap
         a = gaps[0] 
	 b=(mytimes[a+1] - mytimes[a]) / resolution 
	 b=long(b)
         if (b gt 0) then begin ; proceed with the gap filling
            ; create array of timing data to fill the gap
            fill = fltarr(b) 
	    c = indgen(b)+1 
	    d = mytimes[gaps[0]]
            fill = fill + ((resolution * c) + d)
            ; plug the fill data into the time data array
            c=mytimes[0:gaps[0]] 
	    d=mytimes[gaps[0]+1:mytimes_size[1]-1]
            mytimes = append_mydata(fill,c,/vector) 
	    mytimes = append_mydata(d,mytimes,/vector)
            ; create array of Zdata to fill the gap
            fill = make_array(mydata_size[1],b,TYPE=mydata_type,VALUE=Zfillval)
            ; plug the fill data into the zdata array
            c=mydata[*,0:gaps[0]]
	    d=mydata[*,gaps[0]+1:mydata_size[2]-1]
            mydata = append_mydata(fill,c,/vector) 
	    mydata = append_mydata(d,mydata,/vector)
            ; smooth the gap in the energy data if it is time varying
            if (myenergy_size[0] eq 2) then begin ; time-varying energy
               ; create array of Ydata to fill the gap
               fill = make_array(myenergy_size[1],b,TYPE=myenergy_type)
               for c=0L,myenergy_size[1]-1 do fill[c,*] = myenergy[c,0]
               ; plug the fill data into the ydata array
               c=myenergy[*,0:gaps[0]]
	       d=myenergy[*,gaps[0]+1:myenergy_size[2]-1]
               myenergy=append_mydata(fill,c,/vector) 
	       myenergy=append_mydata(d,myenergy,/vector)
            endif
         endif
         ; reset array sizing information
         mytimes_size = size(mytimes)        ; reset array sizing data
         mydata_size = size(mydata)          ; reset array sizing data
         myenergy_size = size(myenergy)      ; reset array sizing data
         gaps = find_gaps(mytimes,ratio=3.0) ; recompute the data gaps
         ; RCJ 02/20/02 Output of find_gaps is array even if one element.
         ; Turn it into scalar, otherwise a[0] will be 1 and we get into
         ; an infinite loop:
         if n_elements(gaps) eq 1 then gaps=gaps[0]
         a = size(gaps) 
	 ;if (a[0] eq 0) then done = 1
	 if (gaps[0] eq -1) then done = 1
      endwhile
   endif

   ; If not plotting in quickmode, then compare the number of actual data
   ; points to the number of pixels available to plot on the xaxis.  Reduce
   ; the number of datapoints by averaging if required.
;   if keyword_set(SMOOTH) then begin
;      a = ppos[2] - ppos[0]
;      if (n_elements(mytimes) gt (a*2)) then begin ; reduce the data
;         if keyword_set(DEBUG) then print,'Averaging data to fit window...'
;         
;         mytimes = congrid(mytimes,a,/interp,/minus_one)
;         
;         w = where(mydata eq Zfillval,wc) 
;         ; smoothing method depends on presence of fill data
;         if (wc gt 0) then mydata = congrid(mydata,mydata_size[1],a,/minus_one) $
;         else mydata = congrid(mydata,mydata_size[1],a,/interp,/minus_one)
;         ;smooth y-axis...
;         if (myenergy_size[0] eq 2) then begin
;         ;print, 'smooth y data...'
;         ;check for y-fill values...   9/97 CGallap
;         w = where(myenergy eq Yfillval,wc)
;  	 if (wc gt 0)  then print, 'fill data detected...'
;         ;Do not interpolate - fill values are present!
;	 if (wc gt 0) then $
;	 myenergy = congrid(myenergy, myenergy_size[1],a,/minus_one) $
;         else myenergy = congrid(myenergy,myenergy_size[1],a,/interp,/minus_one)
;      endif
;   endif
;endif

;If scalemin/max exist, use them
; determine the proper scale for the Y axis
ymax = 1.0 & ymin = 0.0 ; initialize to any value
a = tagindex('SCALEMIN',YTAGS)
if (a[0] ne -1) then begin
   ; TJK 3/1/2001 add check for if there's a value for the attribute, if 
   ; not don't want to use it.
   if (string(yvar.scalemax) ne '') then begin 
      b=size(Yvar.SCALEMIN)
      if (b[0] eq 0) then ymin = Yvar.SCALEMIN $
      else ymin = Yvar.SCALEMIN[elist[i]]
   endif
endif
a = tagindex('SCALEMAX',YTAGS)
if (a[0] ne -1) then begin
   ; TJK 3/1/2001 add check for if there's a value for the attribute, if 
   ; not don't want to use it.
   if (string(yvar.scalemax) ne '') then begin 
      b=size(Yvar.SCALEMAX)
      if (b[0] eq 0) then ymax = Yvar.SCALEMAX $
      else ymax = Yvar.SCALEMAX[elist[i]]
   endif
endif

;TJK add use of validmin/max 2/26/2001
; determine the proper scale for the Y axis
a = tagindex('VALIDMIN',YTAGS)
if (a[0] ne -1) then begin 
   ; TJK 3/1/2001 add check for if there's a value for the attribute, if 
   ; not don't want to use it.
   if (string(yvar.validmin) ne '') then begin 
      b=size(Yvar.VALIDMIN)
      if (b[0] eq 0) then ymin = Yvar.VALIDMIN $
      else ymin = Yvar.VALIDMIN[elist[i]]
   endif
endif

a = tagindex('VALIDMAX',YTAGS)
if (a[0] ne -1) then begin 
   ; TJK 3/1/2001 add check for if there's a value for the attribute, if   
   ; not don't want to use it.
   if (string(yvar.validmax) ne '') then begin 
      b=size(Yvar.VALIDMAX)
      if (b[0] eq 0) then ymax = Yvar.VALIDMAX $
      else ymax = Yvar.VALIDMAX[elist[i]]
   endif
endif

if (n_elements(elist) gt 0) then print, 'elist, ymin, ymax =', elist, ymin, ymax

; Why autoscaling used here validmin and validmax set in cdf
;
w = where(mydata ne Zfillval,non_fillcount) & w=0 ; look for filldata
;print, 'looking for z-fill data, non_fillcount =', non_fillcount

if (keyword_set(AUTO))AND(non_fillcount gt 0) then begin
   ; temporary patch (HACK) for scale adjustment
   y1max=0.0
   a = tagindex('DELTA_PLUS_VAR',YTAGS)
   if (a[0] ne -1) then y1max = max(Yvar.DELTA_PLUS_VAR)
   a = tagindex('SOURCE_NAME',YTAGS)
   if (a[0] ne -1) then temp_str = strmid(Yvar.SOURCE_NAME,0,6)
   if(temp_str eq 'SAMPEX') then begin 
      ymax = max(myenergy)+y1max & ymin = min(myenergy)
   endif else begin
      ;TJK changed to screen out the values outside the scale min and max - even
      ;when autoscaling.
      w =where(((myenergy ne Yfillval)AND(myenergy ge ymin)AND(myenergy le ymax)),wc)
      if (wc gt 0) then ymin = min(myenergy[w],MAX=ymax)
      ;    ymax = max(myenergy) & ymin = min(myenergy)
   endelse
      print,'AUTOSCALING ENERGY: ymax=',ymax,' ymin=',ymin ;DEBUG
   endif
   ; quality check the y scales
   ; RCJ 02/15/02 'ymin - 1' -> 'ymin - 1.' in case ymin is unsigned number.
   if (ymax eq ymin) then begin & ymax = ymax + 1 & ymin = ymin - 1. & endif
      yranger = fltarr(2) & yranger[0] = ymin & yranger[1] = ymax
      ; determine the yaxis scale type, natural or logarithmic
      yscaletype = 1L ; initialize assuming logarithmic
      a = tagindex('SCALETYP',YTAGS)
      if (a[0] ne -1) then begin
         if (strupcase(Yvar.SCALETYP) eq 'LINEAR') then yscaletype = 0L
      endif

      ; Determine the proper labeling for the yaxis
      ylabel = '' & yunits = ''
      if keyword_set(COMBINE) then begin
        a = tagindex('LOGICAL_SOURCE',YTAGS)
        if (a[0] ne -1) then yds = strupcase(Yvar.(a[0]))
      endif
      a = tagindex('FIELDNAM',YTAGS)
      if (a[0] ne -1) then ylabel = Yvar.(a[0])
      a = tagindex('LABLAXIS',YTAGS)
      if (a[0] ne -1 and Yvar.(a[0]) ne '') then ylabel = Yvar.(a[0])
      a = tagindex('UNITS',YTAGS)
      if (a[0] ne -1) then yunits = Yvar.(a[0])
      ;  ylabel = ylabel + '!C!C' + yunits - TJK changed to reduce space 11/98

      if (n_elements(yds) gt 0) then begin
        ylabel = yds + '!C' + ylabel + '!C' + yunits
      endif else ylabel = ylabel + '!C' + yunits

      ; compare the size of the yaxis label to the panel height
      ycsize = 1.0 & ylength = max([strlen(ylabel),strlen(yunits)])
      if ((!d.x_ch_size * ylength) gt psize) then begin
         ratio    = float(!d.x_ch_size * ylength) / float(psize)
         ycsize = 1.0 - (ratio/8.0) + 0.1
      endif
      ; Determine the proper labeling for the z axis
      zlabel = '' & zunits = '' ; initialize
      a = tagindex('FIELDNAM',ZTAGS)
      if (a[0] ne -1) then zlabel = Zvar.(a[0])
      a = tagindex('LABLAXIS',ZTAGS)
      if (a[0] ne -1) then if(Zvar.(a[0])) then zlabel = Zvar.(a[0])
      ; RTB check for blank lablaxis 10/96
      if (num_panels gt 1 and igram ne 1) then begin ; RTB added igram  
        if (use_zlist) then begin
           for l = 0, n_elements(dtype.lptrn)-1 do begin
              if (dtype.lptrn[l] eq 1) then begin ; get labling from labl_ptr_1
                 a = tagindex('LABL_PTR_1',ZTAGS)
                 if (a[0] ne -1) then begin
                    if (Zvar.(a[0])[0] ne '') then zlabel = Zvar.(a[0])
                 endif
              endif
              if (dtype.lptrn[l] eq 2) then begin ; get labling from labl_ptr_2
                 a = tagindex('LABL_PTR_2',ZTAGS)
                 if (a[0] ne -1) then begin
                    if (Zvar.(a[0])[0] ne '') then zlabel = Zvar.(a[0])
                 endif
              endif
              if (dtype.lptrn[l] eq 3) then begin ; get labling from labl_ptr_3
                 a = tagindex('LABL_PTR_3',ZTAGS)
                 if (a[0] ne -1) then begin
                    if (Zvar.(a[0])[0] ne '') then zlabel = Zvar.(a[0])
                 endif
              endif
           endfor
        endif else begin
          if (dtype.lptrn eq 1) then begin ; get labling from labl_ptr_1
           a = tagindex('LABL_PTR_1',ZTAGS)
           if (a[0] ne -1) then begin
              if (Zvar.(a[0])[0] ne '') then zlabel = Zvar.(a[0])[elist[i]-1]
           endif
          endif
          if (dtype.lptrn eq 2) then begin ; get labling from labl_ptr_2
           a = tagindex('LABL_PTR_2',ZTAGS)
           if (a[0] ne -1) then begin
              if (Zvar.(a[0])[0] ne '') then zlabel = Zvar.(a[0])[elist[i]-1]
           endif
          endif
        endelse  
   endif
   
   a = tagindex('UNITS',ZTAGS)
   if (a[0] ne -1) then zunits = Zvar.(a[0])
   if (num_panels gt 1 and igram ne 1) then begin ; RTB added igram
      a = tagindex('UNIT_PTR',ZTAGS)
      if (a[0] ne -1) then begin
         if (Zvar.(a[0])[0] ne '') then zunits = Zvar.(a[0])[elist[i]-1]
;might need some day
;         if (Zvar.(a[0])[elist[i]-1] ne '') then zunits = Zvar.(a[0])[elist[i]-1]
      endif
   endif
   ;TJK take out one !C 11/98 zlabel = zlabel + '!C!C' + zunits
   zlabel = zlabel + '!C' + zunits
   ; compare the size of the zaxis label to the panel height
   zcsize = 1.0 & zlength = max([strlen(zlabel),strlen(zunits)])
   if ((!d.x_ch_size * zlength) gt psize) then begin
      ratio    = float(!d.x_ch_size * zlength) / float(psize)
      zcsize = 1.0 - (ratio/8.0) + 0.1
   endif
   
   ; determine the proper scale for the Z axis
   ; TJK set zmin/max defaults from the data

;TJK 6/20/2007 - look for NAN values and do not use them as zmin/max   
;   w = where((mydata ne Zfillval),wc)
;print, 'check values for NaN'
;print, min(mydata), max(mydata), Zfillval
   not_nan = where(finite(mydata) eq 1,nanc)
   if (nanc gt 0) then begin
     scaledata = mydata[not_nan] 
     w = where((scaledata ne Zfillval),wc)
     if (wc gt 0) then begin 
        zmin = min(scaledata[w],MAX=zmax)
     endif else begin
        zmax = 1.0 & zmin = 0.0 ; initialize to any value
     endelse   
   endif else begin
      zmax = 1.0 & zmin = 0.0 ; initialize to any value
   endelse
   print, 'zmin and max defaults (from data) = ',zmin, zmax
   
   zvmin = 0; TJK added on 2/13/2003 for use below in noauto section
   a = tagindex('VALIDMIN',ZTAGS)
   if (a[0] ne -1) then begin 
      ; TJK 3/1/2001 add check for if there's a value for the attribute, if 
      ; not don't want to use it.
      if (string(zvar.validmin) ne '') then begin 
         b=size(Zvar.VALIDMIN)
         if (b[0] eq 0) then zmin = Zvar.VALIDMIN $
         else zmin = Zvar.VALIDMIN[elist[i]]
      endif
   zvmin = zmin ;TJK save this value otherwise overwritten by scalemin (if it exists)
   endif
   
   a = tagindex('VALIDMAX',ZTAGS)
   if (a[0] ne -1) then begin 
      ; TJK 3/1/2001 add check for if there's a value for the attribute, if 
      ; not don't want to use it.
      if (string(zvar.validmax) ne '') then begin 
         b=size(Zvar.VALIDMAX)
         if (b[0] eq 0) then zmax = Zvar.VALIDMAX $
         else zmax = Zvar.VALIDMAX[elist[i]]
      endif
   endif
   
   print, 'zmin and max (after validmin/max check) = ',zmin, zmax
   
   zsmin = 0;TJK added on 2/13/2003 for use below in noauto section
   a = tagindex('SCALEMIN',ZTAGS)
   if (a[0] ne -1) then begin
      ; TJK 3/1/2001 add check for if there's a value for the attribute, if 
      ; not don't want to use it.
      if (string(zvar.scalemin) ne '') then begin 
         b=size(Zvar.SCALEMIN)
         if (b[0] eq 0) then zmin = Zvar.SCALEMIN $
         else zmin = Zvar.SCALEMIN[elist[i]]
      endif
   zsmin = zmin
   endif
   
   zsmax = 0L ;TJK initialize a flag to indicate whether scalemax has been defined
   a = tagindex('SCALEMAX',ZTAGS)
   if (a[0] ne -1) then begin
      ; TJK 3/1/2001 add check for if there's a value for the attribute, if 
      ; not don't want to use it.
      if (zvar.scalemax ne '') then begin 
	 zsmax = 1L
         b=size(Zvar.SCALEMAX)
         if (b[0] eq 0) then zmax = Zvar.SCALEMAX $
         else zmax = Zvar.SCALEMAX[elist[i]]
      endif
   endif
   
   print, 'zmin and max (after scalemin/max check) = ',zmin, zmax
   
   ; determine the zaxis scale type, natural or logarithmic
   zscaletype = 0L ; initialize assuming linear
   a = tagindex('SCALETYP',ZTAGS)
   if (a[0] ne -1) then begin
      if (strupcase(Zvar.SCALETYP) eq 'LOG') then zscaletype = 1L
   endif

   if (keyword_set(AUTO)) then begin
      if (zscaletype eq 1) then begin ; screen all fill and negative data
         ;TJK added this section 4/19/99 so that when there are valid values that
         ;fall below zero they will get scaled up so as not to drop off just because
         ;we're log scaling.  This change requested by Bob McGuire.
         if (zmin le 0.0) then begin
            scase = where(((mydata le 0.0) and (mydata ne Zfillval) and (mydata ge zmin)), sc)
            if (sc gt 0) then begin
               zcase = where((mydata gt 0.0) and (mydata ne Zfillval),zc) ;find the min of the vals above 0.
   	      if (zc gt 0) then begin
   	       newmin = min(mydata[zcase]);
   	       print, 'reassigning ',sc,' values le 0.0 to lowest data value above zero to ',newmin
   	       mydata[scase] = newmin ;reassign all values that are "valid" but because they
                    ;fall below 0 (w/ log scaling), they would be lost.
   	      endif
           endif 
        endif
      ;TJK end of change.
      w = where(((mydata ne Zfillval)AND(mydata gt 0.0)AND(mydata ge zmin)$
      AND(mydata le zmax)),wc)
      if (wc gt 0) then zmin = min(mydata[w],MAX=zmax)
     endif else begin ; screen all fill
      ;TJK changed to screen out the values outside the scale min and max - even
      ;when autoscaling.
      w =where(((mydata ne Zfillval)AND(mydata ge zmin)AND(mydata le zmax)),wc)
      if (wc gt 0) then zmin = min(mydata[w],MAX=zmax)
     endelse
  endif else begin ;noautoscaling and scaletype = log - Kent wants another change 2/12/2003 (TJK)
      if (zscaletype eq 1) then begin ; screen all fill and negative data
            scase = where((mydata ge zvmin) and (mydata lt zsmin) and (mydata ne Zfillval), sc)
            if (sc gt 0) then begin
   	       print, 'NOAUTO - reassigning values lt scalemin to scalemin = ',zsmin
   	       mydata[scase] = zsmin ;reassign all valid values below scalemin.
   	    endif
	    if (zsmax eq 0) then zmax = max(mydata) ;TJK added 2/13/2003 for Kent
      endif
  endelse
  
; quality check the z scales
if (zmax eq zmin) then begin & zmax = zmax + 1. & zmin = zmin - 1. & endif
   if keyword_set(DEBUG) then begin
      print,'ymin=',ymin,' ymax=',ymax,' yscaletype=',yscaletype         ;DEBUG
      print,'zmin=',zmin,' zmax=',zmax,' zscaletype=',zscaletype         ;DEBUG
      print,'ycsize=',ycsize,' zcsize=',zcsize,' noclipflag=',noclipflag ;DEBUG
   endif
   ; reverse the data if generating an ionogram for top ionograms only
   ; bottom ionograms remain unchanged
   if (igram eq 1 and bgram eq 0)  then begin
      if keyword_set(DEBUG) then print,'Converting data for ionogram...' ;DEBUG
      mydata = reverse(temporary(mydata))
      myenergy = reverse(temporary(myenergy))
      ; SCALEMIN and SCALEMAX changed in MASTERS don't need to switch scale RTB 4/98
      ; if keyword_set(AUTO) then begin ; ionograms are inverted
      ;   temp = yranger[1] & yranger[1] = yranger[0] & yranger[0] = temp
      ; endif
   endif
   ; generate the spectrogram
   if keyword_set(QUICK) then quickflag = 1 else quickflag = 0
   if keyword_set(SLOW) then quickflag = 0
   if (!d.name eq 'Z') then clip=1 else clip=0
   mystatus=0; init


   ; TJK - Spectrogram is a little wierd in how it deals with min and max scale
   ; values, for some reason it doesn't always produce nice plots when
   ; the ymin/max and xmin/max values are specified... certain data need
   ; to have them specified (ISIS ionograms and Fast/DE spectrograms) so we've 
   ; got them pulled out as special cases.  It also seems to have a wierd
   ; sideaffect when Quick=true/false.  If Quick is true then the energies
   ; are read in reverse order than if Quick is false. 
   ;

   ; comment out xrange and yrange values to let idl scale
   ; May need xrange in call but must also include yrange 
   ; Ionograms MUST have yrange set in call to spectrogram
   if(igram) then begin
      spectrogram,transpose(mydata),mytimes,transpose(myenergy),$
              YSTYLE=16+1,XSTYLE=4+1,LOGZ=zscaletype,LOGY=yscaletype,$
              YTITLE=ylabel,POSITION=ppos,FILLVALUE=Zfillval,$
              /DEVICE,NOERASE=clear_plot,XRANGE=xranger,YRANGE=[yranger[1],yranger[0]],$
              QUICK=1,CHARSIZE=ycsize,NOCLIP=noclipflag,$
              CTITLE=zlabel,CSCALE=[zmin,zmax],cCharSize=zcsize,$
              STATUS=mystatus, firstplot=firstplot

   endif else if(scale_gram) then begin
      desc_str = strmid(Yvar.descriptor,0,strpos(Yvar.Descriptor, '>'))
      if (desc_str eq 'RPI') then begin
         print, 'Calling spectrogram w/ X and Y min/maxes specified (IMAGE/RPI data)'
         spectrogram,transpose(mydata),mytimes,transpose(myenergy),$
              YSTYLE=16+1,XSTYLE=4+1,LOGZ=zscaletype,LOGY=yscaletype,$
              YTITLE=ylabel,POSITION=ppos,FILLVALUE=Zfillval,$
	      MINVALUE=zmin, MAXVALUE=zmax,$   
              /DEVICE,NOERASE=clear_plot,YFILLVAL=Yfillval,/noskipgaps,$
              QUICK=0,CHARSIZE=ycsize,XRANGE=xranger,YRANGE=yranger,$
              CTITLE=zlabel,CSCALE=[zmin,zmax],cCharSize=zcsize,$
              STATUS=mystatus, firstplot=firstplot
      endif else begin        
         print, 'TJK Calling spectrogram w/ X and Y min/maxes specified'

	 if (y_reverse) then thisyranger=[yranger[1],yranger[0]] else thisyranger=yranger
	 if (z_reverse) then zscale=[zmax,zmin] else zscale=[zmin,zmax]
	 ;
	 ; RCJ 01/29/2014   Set thiscentery=1.  However, as we've seen for wind_sw-ion-dist_swe-faraday
	 ;    where y axis was array of azimuths, thiscentery=1 triggers a call to align_center
	 ;   (in spectrogram.pro) which only accepts evenly spaced arrays othewise it assumes
	 ;   the scale is log. Our array of azimuths may not be evenly spaced and the scale
	 ;   is certainly not log so, in this case, make thiscentery=0
	 ;   A better test can be devised if we find similar cases.
	 thiscentery=1
	 ;  if scale *is* log, no problem, move on. But if it's not, it could be an azimuth array...
	 if (yscaletype eq 0) then begin
	    ; similar test as in align_center.pro ('ge' as opposed to 'lt')
            dx1 = abs(myenergy[1]-myenergy[0]) & dx2 = abs(myenergy[2]-myenergy[1])
            if (abs(dx1-dx2)*1.0 ge (1.e-6*(min([dx1, dx2])))) then $ ; if not evenly spaced...
	    ; ... make sure align_center will not be called:	    
	        thiscentery=0
	 endif
	 ;
         spectrogram,transpose(mydata),mytimes,transpose(myenergy),$
              YSTYLE=16+1,XSTYLE=4+1,LOGZ=zscaletype,LOGY=yscaletype,$
              YTITLE=ylabel,POSITION=ppos,FILLVALUE=Zfillval,$
	      MINVALUE=zmin, MAXVALUE=zmax,$ ;TJK added these   
              /DEVICE,NOERASE=clear_plot,YFILLVAL=Yfillval,$
              ;QUICK=0,CHARSIZE=ycsize,XRANGE=xranger,YRANGE=yranger,/reduce,$
              QUICK=0,CHARSIZE=ycsize,XRANGE=xranger,YRANGE=thisyranger,$
              CTITLE=zlabel,CSCALE=zscale,cCharSize=zcsize,$
              STATUS=mystatus,centery=thiscentery, $ ;try just centery
              ; TJK take out 2/9/2001 because it alters
	      ;the x axis scale , /CENTER
	      firstplot=firstplot
      endelse
   endif else begin
      print, 'Calling spectrogram w/o x and y min/maxes specified'
      spectrogram,transpose(mydata),mytimes,transpose(myenergy),$
              YSTYLE=16+1,XSTYLE=4+1,LOGZ=zscaletype,LOGY=yscaletype,$
              YTITLE=ylabel,POSITION=ppos,FILLVALUE=Zfillval, $  ;/reduce,$
	      MINVALUE=zmin, MAXVALUE=zmax,$ ;TJK added these   
              /DEVICE,NOERASE=clear_plot, $; XRANGE=xranger,YRANGE=yranger,$
              QUICK=quickflag,CHARSIZE=ycsize,NOCLIP=noclipflag,$
              CTITLE=zlabel,CSCALE=[zmin,zmax],cCharSize=zcsize,$
              STATUS=mystatus, $
	      firstplot=firstplot

   endelse

   if(DEBUG) then print,'mystatus=',mystatus ;DEBUG
   ;  if(mystatus lt 0) then deviceclose  & return, 0 
   timeaxis_text,JD=julday,/NOLABELS
   ; Adjust plot position and flags for next plot
   if(igram eq 1) then begin
      ;ppos[3]=ppos[3]-(psize+20) & ppos[1]=ppos[1]-(psize+20) & clear_plot=1
      ; RCJ 02/25/2009  Need more space for date under tick marks:
      ppos[3]=ppos[3]-(psize+30) & ppos[1]=ppos[1]-(psize+30) & clear_plot=1
      timeaxis_text,FORM=tform,CHARSIZE=0.9,/NOYEAR,jd=julday
   endif else begin
      ppos[3] = ppos[1] & ppos[1] = ppos[1] - psize & clear_plot=1
   endelse
  
endfor

; draw the time axis by default or if lastplot flag is specified
if keyword_set(POSITION) then begin
   if keyword_set(LASTPLOT) then begin
      timeaxis_text,FORM=tform,JD=julday,title=subtitle,CHARSIZE=0.9
   endif
endif else begin
   timeaxis_text,FORM=tform,JD=julday,title=subtitle,CHARSIZE=0.9
   if keyword_set(GIF) then begin
      print,'not yet titling gifs from within plot_spectrogram'
      deviceclose
   endif
endelse

return,0
end
