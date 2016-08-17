;+
; PROCEDURE:
;         mms_load_brst_segments
;
; PURPOSE:
;         Loads the brst segment intervals into a bar that can be plotted
;
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2016-07-01 08:27:16 -0700 (Fri, 01 Jul 2016) $
;$LastChangedRevision: 21416 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/common/data_status_bar/mms_load_brst_segments.pro $
;-

pro mms_load_brst_segments, trange=trange, suffix=suffix
  if undefined(suffix) then suffix = ''
  if (keyword_set(trange) && n_elements(trange) eq 2) $
    then tr = timerange(trange) $
  else tr = timerange()
  
  mms_init

  brst_file = spd_download(remote_file='http://www.spedas.org/mms/mms_brst_intervals.sav', $
    local_file=!mms.local_data_dir+'mms_brst_intervals.sav', $
    SSL_VERIFY_HOST=0, SSL_VERIFY_PEER=0) ; these keywords ignore certificate warnings

  restore, brst_file
  
  if is_struct(brst_intervals) then begin
    unix_start = brst_intervals.start_times
    unix_end = brst_intervals.end_times
    
    sorted_idxs = bsort(unix_start)
    unix_start = unix_start[sorted_idxs]
    unix_end = unix_end[sorted_idxs]
    
    times_in_range = where(unix_start ge tr[0]-300.0 and unix_start le tr[1]+300, t_count)

    if t_count ne 0 then begin
      unix_start = unix_start[times_in_range]
      unix_end = unix_end[times_in_range]
      
      for idx = 0, n_elements(unix_start)-1 do begin
        if unix_end[idx] ge tr[0] and unix_start[idx] le tr[1] then begin
          append_array, bar_x, [unix_start[idx], unix_start[idx], unix_end[idx], unix_end[idx]]
          append_array, bar_y, [!values.f_nan, 0.,0., !values.f_nan]
        endif
      endfor
      
      store_data,'mms_bss_burst'+suffix,data={x:bar_x, y:bar_y}
      options,'mms_bss_burst'+suffix,thick=5,xstyle=4,ystyle=4,yrange=[-0.001,0.001],ytitle='',$
        ticklen=0,panel_size=0.09,colors=4, labels=['Burst'], charsize=2.
    endif else begin
      dprint, dlevel = 0, 'Error, no brst segments found in this time interval: ' + time_string(tr[0]) + ' to ' + time_string(tr[1])
    endelse
  endif else begin
    dprint, dlevel = 0, 'Error, couldn''t find the brst intervals save file'
  endelse
end