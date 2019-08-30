
;+
;Procedure: elf_map_state_t96_wrapper
;
;Purpose:
; Routine just wraps elf_map_state_t96(north and south tracing variants). Making separate
; calls for each type of overview interval. Mainly used to reprocess.
;
;Date: date for plot creation, if not set, assumes current date and duration counts backwards(ie last N days from today)
;Dur: If set, number of days to process, default is 1
;South_only: If set, does tracing to southern hemisphere only
;North_only: If set, does tracing to northern hemisphere only
;            The default value is to plot both north and south
;            
;Note:
;  This routine now called during periodic processing by the routine process_modified_orbit_dates.pro
;
; $LastChangedBy: pcruce $
; $LastChangedDate: 2012-07-31 14:50:02 -0700 (Tue, 31 Jul 2012) $
; $LastChangedRevision: 10758 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/thmsoc/trunk/idl/thmsoc/asi/map_themis_state_t96_wrapper.pro $
;-
pro elf_map_state_t96_intervals_wrapper,date,dur=dur,south_only=south_only, $
   north_only=north_only

  compile_opt idl2

  defsysv,'!elf',exists=exists
  if not keyword_set(exists) then elf_init

  if ~keyword_set(dur) then begin
    dur = 1
  endif

  if n_params() eq 0 then begin
    ts = time_struct(systime(/seconds)-dur*60.*60.*24)
    ;form time truncated datetime string
    date = num_to_str_pad(ts.year,4) + '-' + num_to_str_pad(ts.month,2) + '-' + num_to_str_pad(ts.date,2)
  endif

  dprint,"Processing start time " + time_string(systime(/seconds)) + ' UT'

  dprint,"Generating ELFIN T96 Maps for date " + date + " with duration " + strtrim(dur,2) + " days."

  dir_products=!elf.local_data_dir + 'gtrackplots'

  for j = 0,dur-1 do begin

    in_date = time_double(date)+j*60.*60.*24.

    if keyword_set(north_only) then begin
      elf_map_state_t96_intervals,time_string(in_date),/gif,/move,/tstep,/noview,dir_move=dir_products,/quick_trace
      return
    endif
    if keyword_set(south_only) then begin
     elf_map_state_t96_intervals,time_string(in_date),/gif,/move,/tstep,/noview,dir_move=dir_products,/south,/quick_trace
     return
    endif

    elf_map_state_t96_intervals,time_string(in_date),/gif,/move,/tstep,/noview,dir_move=dir_products,/quick_trace
    elf_map_state_t96_intervals,time_string(in_date),/gif,/move,/tstep,/noview,dir_move=dir_products,/south,/quick_trace

  endfor

end
