;+
;NAME:
;   icon_crib_euv
;
;PURPOSE:
;   Example of loading and plotting ICON data for the EUV instrument
;
;KEYWORDS:
;   step: (optional) selects the example to run, if 99 then it runs all of them
;   img_path: (optional) Directory where the plot files will be saved
;
;KEYWORDS:
;
;
;HISTORY:
;$LastChangedBy: nikos $
;$LastChangedDate: 2018-05-25 12:51:09 -0700 (Fri, 25 May 2018) $
;$LastChangedRevision: 25273 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/icon/examples/icon_crib.pro $
;
;-------------------------------------------------------------------

pro icon_crib_euv, step=step, img_path=img_path

  ; Specify a time range
  timeRange = ['2010-05-23/23:58:00', '2010-05-24/00:02:00']
  ; Specify a directory for images
  if ~keyword_set(img_path) then begin
    if (!D.NAME eq 'WIN') then img_path = 'C:\temp\icon\' else img_path = 'temp/icon/'
  endif

  if ~keyword_set(step) then step = 1

  cdf_leap_second_init

  if step eq 1 or step eq 99 then begin
    del_data, '*'
    instrument = 'euv'
    datal1type = '*'
    datal2type = ''
    icon_load_data, trange = timeRange, instrument = instrument, datal1type = datal1type, datal2type = datal2type

    get_data, 'ICON_L1_EUV_Flux', data=d, dlimits=dlimits
    store_data, 'ICON_L1_EUV_Flux1', data={x:d.x, y:reform(d.y[*,5,*]), v:d.v2}, dlimits=dlimits

    tdegap, ['ICON_L1_EUV_Deadcor'], overwrite=1
    tdegap, ['ICON_L1_EUV_Spectrum','ICON_L1_EUV_Flux1'], overwrite=1, /twonanpergap

    ylim, 'ICON_L1_EUV_Deadcor', 0.95212D, 0.95216D
    options, 'ICON_L1_EUV_Deadcor', 'psym', 4
    options, 'ICON_L1_EUV_Deadcor', 'ytitle', 'EUV Deadcor!C'
    options, 'ICON_L1_EUV_Spectrum', 'ytitle', 'EUV Spectrum !C'
    options, 'ICON_L1_EUV_Flux1', 'ytitle', 'EUV Flux !C'

    options, 'ICON_L1_EUV_Deadcor', 'ysubtitle', ''

    tplot_options, 'title', 'ICON EUV'

    tplot, ['ICON_L1_EUV_Deadcor', 'ICON_L1_EUV_Spectrum', 'ICON_L1_EUV_Flux1']

  endif

  print, 'icon_crib_euv finished'
end