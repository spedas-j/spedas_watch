;+
;
; PROCEDURE:
;         ap2tplot
;
; PURPOSE:
;         Loads the data from the current Autoplot window into tplot variables
;
; KEYWORDS:
;         port: Autoplot server port (default: 12345)
;         connect_timeout: connection timeout time in seconds (default: 6s)
;         read_timeout: read timeout time in seconds (default: 30s)
;         local_data_dir: set the local data directory
;         clear_cache: delete all temporary CDF files stored in the local data directory
;
; EXAMPLE:
;         IDL> ap2tplot
;
; NOTES:
;         This routine is very experimental; please report problems/comments/etc to:  egrimes@igpp.ucla.edu
;         
;         Please use the latest devel release of Autoplot: http://autoplot.org/jnlp/devel/
;         
;         For this to work, you'll need to open Autoplot and enable the 'Server' feature via
;         the 'Options' menu with the default port (12345)
;
;         This routine sends the Autoplot data to tplot via a CDF file stored in your
;         default local data directory (so this creates a 'temporary' file every time you
;         send data to Autoplot)
;
;         On Windows, you'll have to allow Autoplot / SPEDAS to have access to the
;         local network via the Firewall (it should prompt automatically, simply
;         click 'Allow' for private networks)
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2018-05-22 10:06:16 -0700 (Tue, 22 May 2018) $
; $LastChangedRevision: 25247 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/tplot2ap/ap2tplot.pro $
;-

pro ap2tplot, port=port, connect_timeout=connect_timeout, read_timeout=read_timeout, local_data_dir=local_data_dir, clear_cache=clear_cache
  if undefined(port) then port = 12345
  if undefined(connect_timeout) then connect_timeout = 6 ; seconds
  if undefined(read_timeout) then read_timeout = 30 ; seconds

  if undefined(local_data_dir) then local_data_dir = spd_default_local_data_dir() + 'autoplot/'
  
  if keyword_set(clear_cache) then begin ; here be dragons
    file_delete, local_data_dir, /recursive
    return
  endif
  
  socket, unit, '127.0.0.1', port, /get_lun, error=error, read_timeout=read_timeout, connect_timeout=connect_timeout

  ; wait for the connection
  wait, 0.1
  
  ; get the number of plots in the canvas
  printf, unit, "print len(dom.plots)"
  len_plots = ''
  readf, unit, len_plots
  len_plots = (strsplit(len_plots, 'autoplot> ', /extract))[0]
  len_plots = fix(len_plots)
  for i=0l, len_plots-1 do begin
    printf, unit, "print dom.dataSourceFilters["+strcompress(string(i), /rem)+"].uri"
    ap_var = ''
    readf, unit, ap_var

    ; parse out the variable name from id=
    var_name_parts = strsplit(ap_var, '&', /extract)
    for var_idx=0, n_elements(var_name_parts)-1 do begin
      if strmid(var_name_parts[var_idx], 0, 2) eq 'id' then var_name = strmid(var_name_parts[var_idx], 3, strlen(var_name_parts[var_idx]))
    endfor

    if undefined(var_name) then var_name = 'unknown'
    
    tmp_filename = local_data_dir + 'ap2tplot'+strcompress(string(randomu(seed, 1, /long)), /rem)+'.cdf'
    wait, 1
    printf, unit, "formatDataSet(dom.plotElements["+strcompress(string(i), /rem)+"].controller.dataSet, '"+tmp_filename+"?"+var_name+"')"
    wait, 1
    spd_cdf2tplot, tmp_filename, /all
    
    undefine, var_name
    
  endfor

  close, unit
end