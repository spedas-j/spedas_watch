  ;+
  ;Procedure: elf_plot_multispec_overviews
  ;
  ;Purpose:
  ; Routine just wraps EPDE_plot_wIGRF_multispec_overviews. Mainly used for processing.
  ;
  ;Date: date for plot creation, if not set, assumes current date and duration counts backwards(ie last N days from today)
  ;Dur: If set, number of days to process, default is 1
  ;probe: 'a' or 'b'
  ;no_download: If set no files will be downloaded
  ;
  ;-
pro elf_plot_multispec_overviews, date, dur=dur, probe=probe, no_download=no_download

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
  if undefined(probe) then probe='a'

  dprint,"Processing start time " + time_string(systime(/seconds)) + ' UT'

  dprint,"Generating ELFIN EPDE overview plots for " + date + " with duration " + strtrim(dur,2) + " days."

  dir_products=!elf.local_data_dir + 'overplots'

  for j = 0,dur-1 do begin

    start_time = time_double(date)+j*60.*60.*24.
    end_time = start_time + 86400.
    
    EPDE_plot_wIGRF_multispec_overviews, trange=[start_time, end_time], probe=probe, no_download=no_download
  endfor 
  
end