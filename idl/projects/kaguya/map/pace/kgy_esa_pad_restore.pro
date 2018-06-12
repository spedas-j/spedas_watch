;+
; PROCEDURE:
;       kgy_esa_pad_restore
; PURPOSE:
;       Restores pre-generated Kaguya ESA PADs
; KEYWORDS:
;       trange: time range
; CREATED BY:
;       Yuki Harada on 2018-06-02
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-06-10 21:14:06 -0700 (Sun, 10 Jun 2018) $
; $LastChangedRevision: 25342 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_esa_pad_restore.pro $
;-

pro kgy_esa_pad_restore, trange=trange, no_server=no_server, _extra=_extra

if size(no_server,/type) eq 0 then no_server = 0
remote_path = 'http://step0ku.kugi.kyoto-u.ac.jp/~haraday/data/'

pf = 'kaguya/pace/esa_pad/YYYY/MM/kgy_esa_pad_YYYYMMDD_v??_r??.tplot'

tr = timerange(trange)

f = spd_download( remote_file=time_intervals(tf=pf,trange=tr,/daily) ,$
                  remote_path=remote_path, $
                  local_path=root_data_dir(), $
                  /last_version, no_server=no_server, _extra=_extra )

if total(strlen(f)) gt 0 then tplot_restore,file=f,/append

end
