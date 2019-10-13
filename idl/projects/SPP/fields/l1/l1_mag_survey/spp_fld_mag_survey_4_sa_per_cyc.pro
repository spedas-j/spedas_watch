pro spp_fld_mag_survey_4_sa_per_cyc, ppp, vectors, pkt_t, $
  times_1d = times_1d, b_1d = b_1d

  ; PPP   # full cadence samples   Sample rate       Vectors      Cycles
  ;       per sample in packet     vectors / cycle   per packet   per packet
  ;
  ;   0         1                      256              512          2
  ;   1         2                      128              512          4
  ;   2         4                       64              512          8
  ;   3         8                       32              512         16
  ;   4        16                       16              256         16
  ;   5        32                        8              128         16
  ;   6        64                        4               64         16
  ;   7       128                        2               32         16

  ; to get to 4 samples per NYS

  ; ppp       downsampled             n vectors per          t0        dt
  ;           vectors in packet       downsampled vector
  ;  0          8                     64                     31.5      64
  ;  1         16                     32                     15.5      64
  ;  2         32                     16                      7.5      64
  ;  3         64                      8                      3.5      64
  ;  4         64                      4                      1.5      64
  ;  5         64                      2                      0.5      64
  ;  6         64                      N/A                    N/A      64
  ;  7         32                      N/A                    N/A     128

  dt_full = 2d^17/38.4d6

  ;stop

  ;ppp = 0

  if n_elements(vectors) EQ 0 then vectors = dindgen(512)

  ;  for ppp = 0, 7 do begin

  ds_vec_all = [    8,     16,     32,     64,     64,     64,     64,      32]
  n_tri_all =  [   64,     32,     16,      8,      4,      2,      0,       0]
  t0_all =     [31.5d,  15.5d,  07.5d,  03.5d,  01.5d,  00.5d,  00.0d,   00.0d]
  dt_all =     [   64,     64,     64,     64,     64,     64,     64,     128]

  t_all = list()

  d_all = list()

  for pkt = 0, n_elements(ppp) - 1 do begin

    dprint, pkt, dwait = 5d

    p = fix(ppp[pkt])

    t0 = t0_all[p]

    ds_vec = ds_vec_all[p]

    n_tri = n_tri_all[p]

    dt = dt_all[p]

    t = (t0 + dt * dindgen(ds_vec)) * dt_full + pkt_t[pkt]

    if n_tri GT 0 then begin

      tri0 = [dindgen(n_tri/2) + 1, reverse(dindgen(n_tri/2) + 1)]

      tri = tri0 / total(tri0)

      ;print, tri
      ;print, t

      ds = findgen(ds_vec)

      for i = 0, ds_vec - 1 do begin

        ind = [i * n_tri, (i + 1) * n_tri - 1]

        vec_i = vectors[pkt,ind[0]:ind[1]]

        ds[i] = total(vec_i * tri)

        ;print, ind, ds

      endfor

      ;stop

    endif else begin

      ds = vectors[pkt, 0:(ds_vec-1)]

    endelse

    t_all.Add, t, /extract
    d_all.Add, ds, /extract

  end
  ;  stop
  ;  end

  times_1d = t_all.ToArray()
  b_1d = d_all.ToArray()

end