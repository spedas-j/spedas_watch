;+
; PROCEDURE:
;       kgy_esa_pad_save
; CREATED BY:
;       Yuki Harada on 2018-06-02
;
; $LastChangedBy: haraday $
; $LastChangedDate: 2018-06-10 21:14:06 -0700 (Sun, 10 Jun 2018) $
; $LastChangedRevision: 25342 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/kaguya/map/pace/kgy_esa_pad_save.pro $
;-

pro kgy_esa_pad_save, trange=trange, version=version, wdatadir=wdatadir

if ~keyword_set(version) then version = '_v00_r00'
if ~keyword_set(wdatadir) then wdatadir = root_data_dir()+'kaguya/pace/esa_pad/'

tr = timerange(trange)
timespan,tr

kgy_map_load

get_data,'kgy_esa1_en_counts',dtype=dtype1
get_data,'kgy_lmag_Bsat',dtype=dtype2
if dtype1*dtype2 eq 0 then return

kgy_esa_pad_comb,trange=tr,erange=[50,150],suffix='_50-150'
kgy_esa_pad_comb,trange=tr,erange=[150,250],suffix='_150-250'
kgy_esa_pad_comb,trange=tr,erange=[250,350],suffix='_250-350'
kgy_esa_pad_comb,trange=tr,erange=[350,450],suffix='_350-450'

tname = [ 'kgy_esa_pad_50-150','kgy_esa_pad_aveflux_50-150','kgy_esa_pad_counts_50-150', $
          'kgy_esa_pad_150-250','kgy_esa_pad_aveflux_150-250','kgy_esa_pad_counts_150-250', $
          'kgy_esa_pad_250-350','kgy_esa_pad_aveflux_250-350','kgy_esa_pad_counts_250-350', $
          'kgy_esa_pad_350-450','kgy_esa_pad_aveflux_350-450','kgy_esa_pad_counts_350-450' ]
maintname = 'kgy_esa_pad'

validtname = tnames(tname,n)
if n gt 0 then begin
   file_mkdir2, wdatadir+time_string(tr[0],tf='YYYY/MM/'), mode='0777'o
   wfile = wdatadir+time_string(tr[0],tf='YYYY/MM/')+maintname+time_string(tr[0],tf='_YYYYMMDD')+version
   tplot_save,validtname,file=wfile,/compress
   file_chmod,wfile+'.tplot','666'o
endif


end
