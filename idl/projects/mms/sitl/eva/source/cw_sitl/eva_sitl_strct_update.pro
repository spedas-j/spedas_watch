;+
; NAME:
;   EVA_SITL_STRCT_UPDATE
;   
; COMMENT:
;   If a SITL modifies a segment, the information of the segement will be stored in
;   "segSelect" and is passed to this program. This program will then make changes
;   (add, split/combine,etc) to the FOM/BAK structure file. 
; 
; $LastChangedBy: moka $
; $LastChangedDate: 2015-02-09 17:37:52 -0800 (Mon, 09 Feb 2015) $
; $LastChangedRevision: 16932 $
; $URL: svn+ssh://thmsvn@ambrosia.ssl.berkeley.edu/repos/spdsoft/trunk/projects/mms/sitl/eva/source/cw_sitl/eva_sitl_strct_update.pro $
;
PRO eva_sitl_strct_update, segSelect
  compile_opt idl2
  common mms_sitl_connection, netUrl, connection_time, login_source
  
  type = size(netUrl, /type) ;will be 11 if object has been created
  if (type eq 11) then begin
    netUrl->GetProperty, URL_USERNAME = username
  endif else begin
    message,'Something is wrong'
  endelse
  defSourceID = 'SITL:'+username
  
  get_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl
  tfom = eva_sitl_tfom(lim.UNIX_FOMSTR_MOD)

  ;validation
  r = segment_overlap([segSelect.TS,segSelect.TE],tfom)
  case r of
    -1: segSelect.TS = tfom[0]
     1: segSelect.TE = tfom[1]
     2: message,'Something is wrong'
     3: message,'Something is wrong'
    else:;-2 or 0 --> OK
  endcase

  ;main (Determine if segSelect if for FOMStr or BAKStr)
  r = segment_overlap([segSelect.TS,segSelect.TE],tfom)
  case r of
    ;----------------------
    ; FOMStr
    ;----------------------
    0: begin
      s = lim.UNIX_FOMSTR_MOD
      result = min(abs(s.TIMESTAMPS-segSelect.TS),segSTART)
      result = min(abs(s.TIMESTAMPS-segSelect.TE),segSTOP)
      segSTOP -= 1 ; 
      segSelectTime = [s.TIMESTAMPS[segSTART], s.TIMESTAMPS[segSTOP+1]]
      newSEGLENGTHS = 0L
      newSOURCEID   = ' '
      newSTART      = 0L
      newSTOP       = 0L
      newFOM        = 0.
      newCOMMENT    = ''
      newISPENDING  = 1L
      
      ; scan all segments
      for N=0,s.Nsegs-1 do begin
        ss = s.TIMESTAMPS[s.START[N]]; segment start time
        se = s.TIMESTAMPS[s.STOP[N]+1]; segment stop time
        fv = s.FOM[N]; segment FOM value
        
        ; Each segment is compared to the User's new/modified segement
        rr = segment_overlap([ss,se],segSelectTime)
        case abs(rr) of; 
          1: begin; partial overlap --> split
            if rr eq -1 then begin
              if segSTART eq 0 then segSTART += 1L
              newSTART = [newSTART, s.START[N]]
              newSTOP  = [newSTOP, segSTART-1]
              newSEGLENGTHS = [newSEGLENGTHS,(segSTART-1L) - s.START[N] + 1L] 
            endif else begin
              if segSTOP ge s.NUMCYCLES-1 then segSTOP -= 1L
              newSTART = [newSTART, segSTOP+1]
              newSTOP  = [newSTOP, s.STOP[N]]
              newSEGLENGTHS = [newSEGLENGTHS,s.STOP[N] - (segSTOP+1L) + 1L]
            endelse
            newCOMMENT    = [newCOMMENT, s.COMMENT[N]]
            newSOURCEID   = [newSOURCEID, defSourceID]
            newFOM        = [newFOM,s.FOM[N]]
            ;newISPENDING  = [newISPENDING,s.ISPENDING[N]]
            end
          2: begin; no overlap --> preserve this segment
            newSEGLENGTHS = [newSEGLENGTHS, s.SEGLENGTHS[N]]
            ;newISPENDING  = [newISPENDING,s.ISPENDING[N]]
            newSOURCEID   = [newSOURCEID, s.SOURCEID[N]]
            newCOMMENT    = [newCOMMENT, s.COMMENT[N]]
            newSTART      = [newSTART, s.START[N]]
            newSTOP       = [newSTOP, s.STOP[N]]
            newFOM        = [newFOM,s.FOM[N]]
            end
          else:; rr=0 or 3 --> contained in segSelect --> remove
        endcase
      endfor
      
      ;add selected segment
      if segSelect.FOM gt 0. then begin
        newSEGLENGTHS = [newSEGLENGTHS, segSTOP-segSTART+1]
        newFOM        = [newFOM,segSelect.FOM]
        ;newISPENDING  = [newISPENDING, 1L]
        newSOURCEID   = [newSOURCEID, defSourceID]
        newSTART      = [newSTART, segSTART]
        newSTOP       = [newSTOP, segSTOP]
        newCOMMENT    = [newCOMMENT,segSelect.COMMENT]
      endif
      
      ;update FOM structure
      Nmax = n_elements(newFOM)
      newNsegs = Nmax - 1
      
      if newNsegs ge 1 then begin
        str_element,/add,s,'SEGLENGTHS',long(newSEGLENGTHS[1:Nmax-1])
        str_element,/add,s,'SOURCEID', newSOURCEID[1:Nmax-1]
        str_element,/add,s,'START',long(newSTART[1:Nmax-1])
        str_element,/add,s,'STOP',long(newSTOP[1:Nmax-1])
        str_element,/add,s,'FOM',float(newFOM[1:Nmax-1])
        str_element,/add,s,'NSEGS',long(newNsegs)
        str_element,/add,s,'NBUFFS',long(total(newSEGLENGTHS[1:Nmax-1]))
        str_element,/add,s,'COMMENT',newCOMMENT[1:Nmax-1]
        ;str_element,/add,s,'ISPENDING',newISPENDING[1:Nmax-1]
        ;update 'mms_sitl_fomstr'
        D = eva_sitl_strct_read(s,tfom[0])
        store_data,'mms_stlm_fomstr',data=D,lim=lim,dl=dl; update data points
        options,'mms_stlm_fomstr','unix_FOMStr_mod',s ; update structure
        
        ;update 'mms_stlm_output_fom'
        eva_sitl_strct_yrange,'mms_stlm_output_fom'
      endif else begin; No segment
        r = dialog_message("You can't delete all segments.",/center)
      endelse
      end; FOMStr case
    ;----------------------
    ; BAKStr
    ;----------------------
    ; Already validated in 'eva_sitl' so that [segSelect.TS,segSelect.TE] 
    ; (1) does not overlap with any other segment (ADD)
    ; (2) matches exactly with one of the existing segments. (EDIT)
    ; In case of DELETE, simply delete all segments within [segSelect.TS,segSelect.TE]
    -2: begin
      get_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl
      s = lim.UNIX_BAKSTR_MOD
      Nsegs = n_elements(s.FOM)
      matched=0
      for N=0,Nsegs-1 do begin; scan all segment
        rr = segment_overlap([s.START[N],s.STOP[N]],[segSelect.TS,segSelect.TE])
        if (rr eq 3) or (rr eq 0) then begin
          if segSelect.FOM gt 0 then begin;.................. EDIT
            s.FOM[N]    = segSelect.FOM
            s.STATUS[N] = 'MODIFIED'
          endif else begin;............................ DELETE
            s.STATUS[N] = 'DELETED'
          endelse
          matched=1
        endif
      endfor
      if ~matched then begin;..................... ADD
        str_element,/add,s,'START',[s.START, long(segSelect.TS)]
        str_element,/add,s,'STOP', [s.STOP,  long(segSelect.TE)]
        str_element,/add,s,'FOM',  [s.FOM,   segSelect.FOM]
        str_element,/add,s,'SEGLENGTHS',[s.SEGLENGTHS, floor((segSelect.TE-segSelect.TS)/10.d)]
        str_element,/add,s,'CHANGESTATUS',[s.CHANGESTATUS, 1L]
        str_element,/add,s,'DATASEGMENTID',[s.DATASEGMENTID, -1L]
        str_element,/add,s,'PARAMETERSETID',[s.PARAMETERSETID, ''];the revision ID of a BDM configuration file for FOM calculation
        str_element,/add,s,'ISPENDING',[s.ISPENDING,0L]
        str_element,/add,s,'INPLAYLIST',[s.INPLAYLIST,0L]
        str_element,/add,s,'STATUS', [s.STATUS,'NEW']
        ; STATUS should be one or more of the followings:
        ; NEW, DERELILCT, ABORTED, HELD, DEMOTED, INCOMPLETE, REALLOC, MODIFIED, COMPLETE,
        ; DEFERRED, DELETED, FINISHED
        str_element,/add,s,'NUMEVALCYCLES',[s.NUMEVALCYCLES, 0L]; how many times a segment has been evaluated by BDM
        str_element,/add,s,'SOURCEID',[s.SOURCEID,defSourceID]; the SITL responsible for defining the segment
        str_element,/add,s,'CREATETIME',[s.CREATETIME,'']; the UTC time the segment was defined and entered into BDM
        str_element,/add,s,'FINISHTIME',[s.FINISHTIME,'']; the UTC time when the segment was no longer pending any more processing.
      endif
      
      ;update 'mms_sitl_bakstr'
      D = eva_sitl_strct_read(s,min(s.START,/nan))
      store_data,'mms_stlm_bakstr',data=D,lim=lim,dl=dl; update data points
      options,'mms_stlm_bakstr','unix_BAKStr_mod',s ; update structure
      
      ;update 'mms_stlm_output_fom'
      eva_sitl_strct_yrange,'mms_stlm_output_fom'
      
      end; BAKStr
    else: message,'Something is wrong'
  endcase
END
