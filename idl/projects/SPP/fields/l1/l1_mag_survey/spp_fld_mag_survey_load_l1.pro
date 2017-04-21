;
;  $LastChangedBy: spfuser $
;  $LastChangedDate: 2017-04-19 14:58:30 -0700 (Wed, 19 Apr 2017) $
;  $LastChangedRevision: 23197 $
;  $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/SPP/fields/l1/l1_mag_survey/spp_fld_mag_survey_load_l1.pro $
;

pro spp_fld_mag_survey_load_l1, file, prefix = prefix

  if not keyword_set(file) then begin
    print, 'file must be specified'
    return
  endif

  cdf2tplot, file, prefix = prefix

  if not keyword_set(prefix) then prefix = ''

  mag_string_index = prefix.IndexOf('mag')

  if mag_string_index GE 0 then begin
    short_prefix = prefix.Substring(mag_string_index, mag_string_index+3)
  endif else begin
    short_prefix = ''
  endelse

  store_data, prefix + 'mag_bx', newname = prefix + 'mag_bx_2d'
  store_data, prefix + 'mag_by', newname = prefix + 'mag_by_2d'
  store_data, prefix + 'mag_bz', newname = prefix + 'mag_bz_2d'

  get_data, prefix + 'avg_period_raw', data = d_ppp
  get_data, prefix + 'range_bits', data = d_range_bits

  options, prefix + 'avg_period_raw', 'ytitle', short_prefix + ' PPP'
  options, prefix + 'avg_period_raw', 'ysubtitle'
  options, prefix + 'avg_period_raw', 'yrange', [-0.5,7.5]
  options, prefix + 'avg_period_raw', 'ystyle', 1
  options, prefix + 'avg_period_raw', 'psym', 4

  if tnames(prefix + 'avg_period_raw') EQ '' then return

  times_2d = d_ppp.x

  times_1d = list()
  range_bits_1d = list()
  packet_index = list()

  foreach time, times_2d, ind do begin

    ppp = d_ppp.y[ind]

    navg = 2l^ppp

    ; If the number of averages is less than 16, then
    ; there are 512 vectors in the packet.  Otherwise, there
    ; are fewer (See FIELDS CTM)

    if navg LT 16 then begin
      nvec = 512l
      nseconds = 2l * navg
    endif else begin
      nvec = 512l / 2l^(ppp-3)
      nseconds = 16l
    endelse

    ; rate = Vectors per NYS

    rate = 512l / (2l^(ppp+1))

    ; (2.^25 / 38.4d6) is the FIELDS NYS
    ; 512 vectors with no averaging yields 256 vectors
    ; per NYS

    timedelta = dindgen(nvec) / rate * (2.^25/38.4e6)

    times_1d.Add, list(time + timedelta, /extract), /extract

    packet_index.Add, dindgen(nvec), /extract

    ; There are 2 range bits per second, left justified
    ; in a 32 bit range_bit item.  Depending on the averaging
    ; period, there can be 2, 4, 8, or 16 seconds worth of data
    ; in the packet, yielding 4, 8, 16, or 32 range bits.
    ; The data item is always 32 bits long.  If there are fewer than
    ; 32 range bits required for the length of the packet,
    ; the first 2 * (# of seconds) bits are used and the
    ; remainder are zero filled.

    range_bits_i = d_range_bits.y[ind]

    range_bits_str = string(range_bits_i, format = '(b032)')

    ;if range_bits_str NE '01010000000000000000000000000000' then stop

    range_bits_list = list()

    for j = 0, nseconds - 1 do begin

      range_bits_int_j = 0

      range_bits_str_j = strmid(range_bits_str, j * 2, 2)

      reads, range_bits_str_j, range_bits_int_j, format = '(B)'

      range_bits_arr_j = lonarr(rate) + range_bits_int_j

      range_bits_list.Add, range_bits_arr_j, /extract

    end

    range_bits_1d.Add, range_bits_list, /extract

  endforeach

  mag_comps = ['mag_bx', 'mag_by', 'mag_bz']

  foreach mag_comp, mag_comps do begin

    get_data, prefix + mag_comp + '_2d', data = d_b_2d

    b_1d = reform(transpose(d_b_2d.y), n_elements(d_b_2d.y))

    store_data, prefix + mag_comp, data = {x:times_1d.ToArray(), y:b_1d}

    options, prefix + mag_comp, 'ytitle', $
      short_prefix + ' b' + mag_comp.Substring(-1,-1)
    ;options, prefix + mag_comp, 'ysubtitle', '[Counts]'

  endforeach

  store_data, prefix + 'packet_index', $
    data = {x:times_1d.ToArray(), y:packet_index.ToArray()}

  options, prefix + 'packet_index', 'ytitle', $
    short_prefix + ' pkt_ind'

  options, prefix + 'packet_index', 'psym', 3


  store_data, prefix + 'range', $
    data = {x:times_1d.ToArray(), y:range_bits_1d.ToArray()}

  options, prefix + 'range', 'yrange', [-0.5,3.5]

  options, prefix + 'range', 'ytitle', $
    short_prefix + ' range'

  options, prefix + 'range', 'yminor', 1

  options, prefix + 'range', 'psym', 3


end