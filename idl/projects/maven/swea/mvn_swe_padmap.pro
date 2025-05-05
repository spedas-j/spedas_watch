;+
;FUNCTION:   mvn_swe_padmap
;PURPOSE:
;  Calculates the pitch angle map for a PAD.
;
;USAGE:
;  pam = mvn_swe_padmap(pkt)
;
;INPUTS:
;       pkt  :         A raw PAD packet (APID A2 or A3).
;
;KEYWORDS:
;       MAGF :         Magnetic field direction in SWEA coordinates.  Overrides
;                      the nominal direction contained in the A2 or A3 packet.
;
;       RESET:         Initialize the common block, which contains the unit vectors
;                      pointing to each element of the FOV.
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2025-05-04 15:21:41 -0700 (Sun, 04 May 2025) $
; $LastChangedRevision: 33289 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/swea/mvn_swe_padmap.pro $
;
;CREATED BY:    David L. Mitchell  03-18-14
;FILE: mvn_swe_padmap.pro
;-
function mvn_swe_padmap, pkt, magf=magf, reset=reset

  @mvn_swe_com
  common swe_padmap_com, Sx3d, Sy3d, Sz3d, patch_size

; Update the common block if requested or necessary.

  if (keyword_set(reset) || (size(patch_size,/type) eq 0)) then begin

    k = indgen(96)  ; 96 solid angle bins
    i = k mod 16    ; 16 anode bins
    j = k / 16      ;  6 deflector bins

;   nxn azimuth-elevation patch for each of the 96 solid angle bins

    ddtor = !dpi/180D
    ddtors = replicate(ddtor,64)

    n = 15L  ; patch size (odd integer)
    patch_size = n
    ones1d = replicate(1D,n)
    ones2d = replicate(1D,n*n)
    Saz3d = dblarr(n*n,96,64,3)
    Sel3d = Saz3d

    daz = double((lindgen(n*n) mod n) - (n-1)/2)/double(n-1) # double(swe_daz[i])
    Saz = reform(ones2d # double(swe_az[i]) + daz, n*n*96) # ddtors
    Saz3d[*,*,*,0] = reform(Saz,n*n,96,64)  ; nxn az-el patch, 96 solid angle angle bins, 64 energies
    for g=1,2 do Saz3d[*,*,*,g] = Saz3d[*,*,*,0]

    Sel = dblarr(n*n*96,64)
    patch = reform(ones1d # double(lindgen(n) - (n-1)/2)/double(n-1), n*n)
    for g=0,2 do begin
      for m=0,8 do begin
        del = patch # double(swe_del[j,m,g])
        Sel[*,m] = reform(ones2d # double(swe_el[j,m,g]) + del, n*n*96)
      endfor
      for m=9,63 do Sel[*,m] = Sel[*,8]  ; elevations are constant below ~2 keV.

      Sel = temporary(Sel)*ddtor
      Sel3d[*,*,*,g] = reform(Sel,n*n,96,64)  ; nxn az-el patch, 16 solid angle bins, 64 energies, 3 groups
    endfor

;   unit vector pointing to each element of the FOV (each component: n*n,96,64,3)

    Sx3d = cos(Saz3d)*cos(Sel3d)
    Sy3d = sin(Saz3d)*cos(Sel3d)
    Sz3d = sin(Sel3d)

    undefine, Saz3d, Sel3d, Saz, Sel, daz, del

  endif

  str_element, pkt, 'Baz', success=ok        ; make sure it's a PAD packet

  if (ok) then begin

; Anode, deflector, and 3D bins for each PAD bin

    aBaz = pkt.Baz
    aBel = pkt.Bel
    group = pkt.group

    i = fix((indgen(16) + aBaz/16) mod 16)   ; 16 anode bins at each time
    j = swe_padlut[*,aBel]                   ; 16 deflector bins at each time
    k = j*16 + i                             ; 16 solid angle bins at each time

    Sx = Sx3d[*,k,*,group]                   ; FOV unit vector, x component (n*n,16,64)
    Sy = Sy3d[*,k,*,group]                   ; FOV unit vector, y component (n*n,16,64)
    Sz = Sz3d[*,k,*,group]                   ; FOV unit vector, z component (n*n,16,64)

; Magnetic field azimuth and elevation in SWEA coordinates
; Use L1 or L2 MAG data, if available.

    if (n_elements(magf) ne 3) then begin
      mvn_swe_magdir, pkt.time, aBaz, aBel, Baz, Bel
      cosBel = cos(Bel)
      Bx = cos(Baz)*cosBel
      By = sin(Baz)*cosBel
      Bz = sin(Bel)
    endif else begin
      B = sqrt(total(magf[0:2]*magf[0:2]))
      Bx = magf[0]/B
      By = magf[1]/B
      Bz = magf[2]/B

      Baz = atan(magf[1], magf[0])
      if (Baz lt 0.) then Baz += (2.*!pi)
      Bel = asin(magf[2]/B)
    endelse

; Calculate the nominal (center) pitch angle for each bin
;   This is a function of energy because the deflector high voltage supply
;   tops out above ~2 keV, and it's function of time because the magnetic
;   field varies: pam -> 16 angles X 64 energies.

    SxBx = temporary(Sx)*Bx
    SyBy = temporary(Sy)*By
    SzBz = temporary(Sz)*Bz
    SdotB = (SxBx + SyBy + SzBz)
    pam = acos(SdotB < 1D > (-1D))        ; (n*n,16,64)

    pa = mean(pam, dim=1)                 ; mean pitch angle
    pa_min = min(pam, dim=1, max=pa_max)  ; min and max pitch angle
    dpa = pa_max - pa_min                 ; pitch angle range

; Package the result

    pam = { pa     : float(pa)     , $    ; mean pitch angles (radians)
            dpa    : float(dpa)    , $    ; pitch angle widths (radians)
            pa_min : float(pa_min) , $    ; minimum pitch angle (radians)
            pa_max : float(pa_max) , $    ; maximum pitch angle (radians)
            iaz    : i             , $    ; anode bin (0-15)
            jel    : j             , $    ; deflector bin (0-5)
            k3d    : k             , $    ; 3D angle bin (0-95)
            Baz    : float(Baz)    , $    ; Baz in SWEA coord. (radians)
            Bel    : float(Bel)       }   ; Bel in SWEA coord. (radians)

  endif else pam = 0

  return, pam

end
