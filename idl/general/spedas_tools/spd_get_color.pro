;+
; FUNCTION:
;   spd_get_color
; 
; PURPOSE:
;   Return color index by name (uses current color table, whatever that might be)
;   
; NOTES:
;   spd_get_color_index was heisted from get_colors, and the color table was heisted from fsc_color
;
; $LastChangedBy: egrimes $
; $LastChangedDate: 2019-03-21 17:46:22 -0700 (Thu, 21 Mar 2019) $
; $LastChangedRevision: 26877 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/general/spedas_tools/spd_get_color.pro $
;-

function spd_get_color_index,color
  tvlct,r,g,b,/get
  vecs = replicate(1.,n_elements(r)) # reform(color)
  tbl = [[r],[g],[b]]
  d = sqrt( total((vecs-tbl)^2,2) )
  m = min(d,bin)
  return,byte(bin)
end

function spd_get_color, name
  colors = ['White']
  rvalue = [ 255]
  gvalue = [ 255]
  bvalue = [ 255]
  colors = [ colors,       'Snow',     'Ivory','Light Yellow',   'Cornsilk',      'Beige',   'Seashell' ]
  rvalue = [ rvalue,          255,          255,          255,          255,          245,          255 ]
  gvalue = [ gvalue,          250,          255,          255,          248,          245,          245 ]
  bvalue = [ bvalue,          250,          240,          224,          220,          220,          238 ]
  colors = [ colors,      'Linen','Antique White',    'Papaya',     'Almond',     'Bisque',  'Moccasin' ]
  rvalue = [ rvalue,          250,          250,          255,          255,          255,          255 ]
  gvalue = [ gvalue,          240,          235,          239,          235,          228,          228 ]
  bvalue = [ bvalue,          230,          215,          213,          205,          196,          181 ]
  colors = [ colors,      'Wheat',  'Burlywood',        'Tan', 'Light Gray',   'Lavender','Medium Gray' ]
  rvalue = [ rvalue,          245,          222,          210,          230,          230,          210 ]
  gvalue = [ gvalue,          222,          184,          180,          230,          230,          210 ]
  bvalue = [ bvalue,          179,          135,          140,          230,          250,          210 ]
  colors = [ colors,       'Gray', 'Slate Gray',  'Dark Gray',   'Charcoal',      'Black', 'Light Cyan' ]
  rvalue = [ rvalue,          190,          112,          110,           70,            0,          224 ]
  gvalue = [ gvalue,          190,          128,          110,           70,            0,          255 ]
  bvalue = [ bvalue,          190,          144,          110,           70,            0,          255 ]
  colors = [ colors,'Powder Blue',   'Sky Blue', 'Steel Blue','Dodger Blue', 'Royal Blue',       'Blue' ]
  rvalue = [ rvalue,          176,          135,           70,           30,           65,            0 ]
  gvalue = [ gvalue,          224,          206,          130,          144,          105,            0 ]
  bvalue = [ bvalue,          230,          235,          180,          255,          225,          255 ]
  colors = [ colors,       'Navy',   'Honeydew', 'Pale Green','Aquamarine','Spring Green',       'Cyan' ]
  rvalue = [ rvalue,            0,          240,          152,          127,            0,            0 ]
  gvalue = [ gvalue,            0,          255,          251,          255,          250,          255 ]
  bvalue = [ bvalue,          128,          240,          152,          212,          154,          255 ]
  colors = [ colors,  'Turquoise', 'Sea Green','Forest Green','Green Yellow','Chartreuse', 'Lawn Green' ]
  rvalue = [ rvalue,           64,           46,           34,          173,          127,          124 ]
  gvalue = [ gvalue,          224,          139,          139,          255,          255,          252 ]
  bvalue = [ bvalue,          208,           87,           34,           47,            0,            0 ]
  colors = [ colors,      'Green', 'Lime Green', 'Olive Drab',     'Olive','Dark Green','Pale Goldenrod']
  rvalue = [ rvalue,            0,           50,          107,           85,            0,          238 ]
  gvalue = [ gvalue,          255,          205,          142,          107,          100,          232 ]
  bvalue = [ bvalue,            0,           50,           35,           47,            0,          170 ]
  colors = [ colors,      'Khaki', 'Dark Khaki',     'Yellow',       'Gold','Goldenrod','Dark Goldenrod']
  rvalue = [ rvalue,          240,          189,          255,          255,          218,          184 ]
  gvalue = [ gvalue,          230,          183,          255,          215,          165,          134 ]
  bvalue = [ bvalue,          140,          107,            0,            0,           32,           11 ]
  colors = [ colors,'Saddle Brown',       'Rose',       'Pink', 'Rosy Brown','Sandy Brown',       'Peru' ]
  rvalue = [ rvalue,          139,          255,          255,          188,          244,          205 ]
  gvalue = [ gvalue,           69,          228,          192,          143,          164,          133 ]
  bvalue = [ bvalue,           19,          225,          203,          143,           96,           63 ]
  colors = [ colors,  'Indian Red',  'Chocolate',     'Sienna','Dark Salmon',    'Salmon','Light Salmon' ]
  rvalue = [ rvalue,          205,          210,          160,          233,          250,          255 ]
  gvalue = [ gvalue,           92,          105,           82,          150,          128,          160 ]
  bvalue = [ bvalue,           92,           30,           45,          122,          114,          122 ]
  colors = [ colors,     'Orange',      'Coral', 'Light Coral',  'Firebrick',      'Brown',  'Hot Pink' ]
  rvalue = [ rvalue,          255,          255,          240,          178,          165,          255 ]
  gvalue = [ gvalue,          165,          127,          128,           34,           42,          105 ]
  bvalue = [ bvalue,            0,           80,          128,           34,           42,          180 ]
  colors = [ colors,  'Deep Pink',    'Magenta',     'Tomato', 'Orange Red',        'Red', 'Violet Red' ]
  rvalue = [ rvalue,          255,          255,          255,          255,          255,          208 ]
  gvalue = [ gvalue,           20,            0,           99,           69,            0,           32 ]
  bvalue = [ bvalue,          147,          255,           71,            0,            0,          144 ]
  colors = [ colors,     'Maroon',    'Thistle',       'Plum',     'Violet',    'Orchid','Medium Orchid']
  rvalue = [ rvalue,          176,          216,          221,          238,          218,          186 ]
  gvalue = [ gvalue,           48,          191,          160,          130,          112,           85 ]
  bvalue = [ bvalue,           96,          216,          221,          238,          214,          211 ]
  colors = [ colors,'Dark Orchid','Blue Violet',     'Purple' ]
  rvalue = [ rvalue,          153,          138,          160 ]
  gvalue = [ gvalue,           50,           43,           32 ]
  bvalue = [ bvalue,          204,          226,          240 ]

  color_idx = where(strlowcase(colors) eq strlowcase(name), colorcount)
  if colorcount ne 0 then begin
    return, spd_get_color_index([rvalue[color_idx], gvalue[color_idx], bvalue[color_idx]])
  endif
end