;$Author: nikos $
;$Date: 2014-09-03 15:05:59 -0700 (Wed, 03 Sep 2014) $
;$Header: /home/cdaweb/dev/control/RCS/generate_inventory2.pro,v 1.18 2012/03/09 18:03:23 kovalick Exp johnson $
;$Locker: johnson $
;$Revision: 15739 $
;---------------------------------------------------------------------------
;Modifications: 2/4/98 - T. Kovalick - modified this to do what the inventory function
;in inventory.pro use to do, so that I can free up memory w/ delvar (has to be
;done at the main program level).
; 5/1/2003 - removed IACG and Mpause generation - TJK 
;
;Copyright 1996-2013 United States Government as represented by the 
;Administrator of the National Aeronautics and Space Administration. 
;All Rights Reserved.
;
;------------------------------------------------------------------

@compile_inventory.pro

; Read the metadata file...
a = ingest_database('/home/cdaweb/metadata/bowshock_cdfmetafile.txt',DEBUG=DEBUG)
; Draw inventory graph...
s=draw_inventory(a,TITLE='BOWSHOCK',GIF='/home/cdaweb/metadata/bowshock_cdfmetafile.gif',/debug)
delvar, a

; Read the metadata file...
a = ingest_database('/home/cdaweb/metadata/cdaw9_cdfmetafile.txt',DEBUG=DEBUG)
; Draw inventory graph...
s=draw_inventory(a,TITLE='CDAW-9 CAMPAIGN',GIF='/home/cdaweb/metadata/cdaw9_cdfmetafile.gif',/debug)
delvar, a

; Read the metadata file...
; RCJ 02/2012 cluster no longer there.
;a = ingest_database('/home/cdaweb/metadata/cluster_cdfmetafile.txt',DEBUG=DEBUG)
; Draw inventory graph...
;s=draw_inventory(a,TITLE='CLUSTER DATA',GIF='/home/cdaweb/metadata/cluster_cdfmetafile.gif', $
;START_TIME='2000/10/01 00:00:00', STOP_TIME='2010/12/31 23:59:59', /debug)
;delvar, a

; Read the metadata file...
a = ingest_database('/home/cdaweb/metadata/radiation_cdfmetafile.txt',DEBUG=DEBUG)
; Draw inventory graph...
s=draw_inventory(a,TITLE='TRAPPED RADIATION STUDIES',GIF='/home/cdaweb/metadata/radiation_cdfmetafile.gif', /debug)
delvar, a

exit




