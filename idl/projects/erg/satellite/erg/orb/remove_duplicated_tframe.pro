;+
; PRO  remove_duplicated_tframe
; 
;
; :Description:
;    This function was taken from erg_load_orb.pro
;
; :Params:
;
;
; :History:
;    Prepared by Kunihiro Keika, ISEE, Nagoya University in July 2016
;    2016/02/01: first protetype
;    2017/02/20: Cut the part of loading predicted orb data in 'erg_load_orb.pro'
;                Pasted it to 'erg_load_orb_predict.pro'
;                by Mariko Teramoto, ISEE, Nagoya University
;    2018/07/31: Marge 'erg_load_orb_l3.pro' with this erg_load_orb.pro
;    2019/02/17: add t89 keyword in Level-3 data
;
; :Author:
;   Tzu-Fang Chang, ISEE, Nagoya University (jocelyn at isee.nagoya-u.ac.jp)
;   Mariko Teramoto, ISEE, Naogya Univ. (teramoto at isee.nagoya-u.ac.jp)
;   Kuni Keika, Department of Earth and Planetary Science,
;     Graduate School of Science,The University of Tokyo (keika at eps.u-tokyo.ac.jp)
;
; $LastChangedDate: 2019-03-15 12:52:35 -0700 (Fri, 15 Mar 2019) $
; $LastChangedRevision: 26822 $
;-
pro remove_duplicated_tframe, tvars

  if n_params() ne 1 then return
  tvars = tnames(tvars)
  if strlen(tvars[0]) lt 1 then return

  for i=0L, n_elements(tvars)-1 do begin
    tvar = tvars[i]

    get_data, tvar, time, data, dl=dl, lim=lim
    n = n_elements(time)
    dt = [ time[1:(n-1)], time[n-1]+1 ] - time[0:(n-1)]
    idx = where( abs(dt) gt 0d, n1 )

    if n ne n1 then begin
      newtime = time[idx]
      if size(data,/n_dim) eq 1 then begin
        newdata = data[idx]
      endif else newdata = data[ idx, *]
      store_data, tvar, data={x:newtime, y:newdata},dl=dl, lim=lim
    endif


  endfor

  return
end