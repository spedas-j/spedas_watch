;+
;FUNCTION:   maven_orbit_eph
;PURPOSE:
;  Returns the MAVEN spacecraft ephemeris, consisting of the MSO and GEO state
;  vectors along with some derived quantities: altitude, GEO longitude, GEO
;  latitude, and solar zenith angle.  The reference surface for calculating
;  altitude ("datum") is specified.
;
;  The coordinate frames are:
;
;   GEO = body-fixed Mars geographic coordinates (non-inertial) = IAU_MARS
;
;              X ->  0 deg E longitude, 0 deg latitude
;              Y -> 90 deg E longitude, 0 deg latitude
;              Z -> 90 deg N latitude (= X x Y)
;              origin = center of Mars
;              units = kilometers
;
;   MSO = Mars-Sun-Orbit coordinates (approx. inertial)
;
;              X -> from center of Mars to center of Sun
;              Y -> opposite to Mars' orbital angular velocity vector
;              Z = X x Y
;              origin = center of Mars
;              units = kilometers
;
;USAGE:
;  eph = maven_orbit_eph()
;INPUTS:
;       none
;
;KEYWORDS:
;       none
;
; $LastChangedBy: dmitchell $
; $LastChangedDate: 2019-02-22 18:19:46 -0800 (Fri, 22 Feb 2019) $
; $LastChangedRevision: 26694 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/maven/maven_orbit_tplot/maven_orbit_eph.pro $
;-
function maven_orbit_eph

  @maven_orbit_common

  if (size(state,/type) gt 0) then begin
    eph = state
    str_element, eph, 'alt', hgt, /add
    str_element, eph, 'lon', lon, /add
    str_element, eph, 'lat', lat, /add
    str_element, eph, 'sza', sza*!radeg, /add
    str_element, eph, 'datum', datum, /add
    return, eph
  endif else begin
    print,"Ephemeris not defined.  Use maven_orbit_tplot first."
    return, 0
  endelse

end
