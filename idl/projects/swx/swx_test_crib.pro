;swx_text_crib
;
swx_apdat_init
swx_apdat_info,rt_flag=0, save_flag=1, /clear
;files = FILE_SEARCH('/disks/data/swx/sst/prelaunch/realtime/cleantent/ptp_reader/2023/12/27/*.dat')
source = { remote_data_dir: 'http://sprg.ssl.berkeley.edu/data/',resolution:3600d}
trange = ['2023-12-27 5','2023-12-27 / 8']
files = file_retrieve('swx/s\st/prelaunch/realtime/cleantent/ptp_reader/YYYY/MM/DD/ptp_reader_YYYYMMDD_hh.dat',_extra=source,trange=trange)
swfo_ptp_file_read, files,file_type =  'ptp_file'
end