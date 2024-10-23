;swfo_stis_ar_crib.pro
;


swfo_stis_load,station = 'S2',trange=['23 7 27 4','23 7 27 5'],reader=rdr

swfo_stis_plot,param=param
printdat,param.lim
param.range = 10

swfo_stis_tplot,/set

ctime,/silent,t,routine_name="swfo_stis_plot"


end
