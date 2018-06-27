;+
; Procedure:
;         mms_part_isee3d
;
; Purpose:
;         This is a wrapper around isee_3d that loads required
;         support data and plots the distribution
;
; Keywords:
;         probe: MMS s/c # to create the 2D slice for
;         instrument: fpi or hpca
;         species: depends on instrument:
;             FPI: 'e' for electrons, 'i' for ions
;             HPCA: 'hplus' for H+, 'oplus' for O+, 'heplus' for He+, 'heplusplus', for He++
;         level: level of the data you'd like to plot
;         data_rate: data rate of the distribution data you'd like to plot
;         trange: two-element time range over which data will be averaged (optional, ignored if 'time' is specified)
;         spdf: load the data from the SPDF instead of the LASP SDC
;
; Notes:
;         This routine always centers the distribution/moments data
;
;$LastChangedBy: egrimes $
;$LastChangedDate: 2018-06-26 16:34:11 -0700 (Tue, 26 Jun 2018) $
;$LastChangedRevision: 25400 $
;$URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/particles/mms_part_isee3d.pro $
;-

pro mms_part_isee3d, time=time, probe=probe, level=level, data_rate=data_rate, species=species, instrument=instrument, $
                      trange=trange, subtract_bulk=subtract_bulk, spdf=spdf, _extra=_extra

    start_time = systime(/seconds)
  
    if undefined(time) then begin
      if ~keyword_set(trange) then begin
        trange = timerange()
      endif else trange = timerange(trange)
    endif else trange = time_double(time)+[-60, 60]

    if undefined(instrument) then instrument = 'fpi' else instrument = strlowcase(instrument)
    if undefined(species) then begin
      if instrument eq 'fpi' then species = 'e'
      if instrument eq 'hpca' then species = 'hplus'
    endif
    if undefined(data_rate) then begin
      if instrument eq 'fpi' then data_rate = 'fast'
      if instrument eq 'hpca' then data_rate = 'srvy'
    endif
    if undefined(probe) then probe = '1' else probe = strcompress(string(probe), /rem)

    mms_load_fgm, trange=trange, probe=probe, spdf=spdf
    bname = 'mms'+probe+'_fgm_b_gse_srvy_l2_bvec'
    
    if instrument eq 'fpi' then begin
      name = 'mms'+probe+'_d'+species+'s_dist_'+data_rate
      vname = 'mms'+probe+'_d'+species+'s_bulkv_gse_'+data_rate
      name = 'mms'+probe+'_d'+species+'s_dist_'+data_rate
      mms_load_fpi, datatype='d'+species+'s-'+['dist', 'moms'], data_rate=data_rate, /center, level=level, probe=probe, trange=trange, spdf=spdf, /time_clip
    endif else if instrument eq 'hpca' then begin
      name = 'mms'+probe+'_hpca_'+species+'_phase_space_density'
      vname = 'mms'+probe+'_hpca_'+species+'_ion_bulk_velocity'
      name = 'mms'+probe+'_hpca_'+species+'_phase_space_density'
      mms_load_hpca, datatype=['ion', 'moments'], data_rate=data_rate, /center, level=level, probe=probe, trange=trange, spdf=spdf, /time_clip
    endif else begin
      dprint, dlevel=0, 'Error, unknown instrument; valid options are: fpi, hpca'
      return
    endelse
    
    dist = mms_get_dist(name, trange=trange)
    
    data = spd_dist_to_hash(dist)
    
    isee_3d, data=data, trange=trange, bfield=bname, velocity=vname, unit='psd', /slice_volume, _extra=_extra
end