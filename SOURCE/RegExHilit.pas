unit RegExHilit;

{ © Electro-Concept Mauricie, 2005-2013 }
{ Implements TRegExHighlighter component, used for regular expression keywords and start-stop keys
  highlighting in a TPlusMemo }

{ TRegExHighlighter is based on TRegExpr class developed by Andrey V. Sorokin (see unit RegExpr.pas).
  Electro-Concept Mauricie grants Mr. Sorokin credit for the regular expressions parsing code used in
  TRegExHighlighter. }

{ Note: to install this component on your palette, add this file to a design time package }

interface

uses
  Classes, ExtHilit, PlusMemo, PMSupport, RegExpr;

type
  TRegExHighlighter = class(TExtHighlighter)
  private
    fKeysRE: array of TRegExpr;
    fSSRE: array of array[0..1] of TRegExpr;
    fKeysAcquired: Boolean;
    fExtendedSyntax: Boolean;
    fGreedyStyle: Boolean;
    fRussianAlphaChars: Boolean;
    fRegExStartStop: Boolean;
    procedure AcquireKeys;
    procedure AcquireSS;
    procedure setExtendedSyntax(const Value: Boolean);
    procedure setRussianAlphaChars(const Value: Boolean);
    procedure setRegExStartStop(const Value: Boolean);
    procedure setGreedyStyle(const Value: Boolean);
    procedure InvalidateKeys;
  protected
    procedure ApplyKeywordsList(Start, Stop: TPlusNavigator; BaseIndex: Integer); override;
    function  FindStart(Start, Stop: TPlusNavigator; BaseIndex: Integer): Boolean; override;
    function  FindStop(Start, Stop: TPlusNavigator; BaseIndex: Integer): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function FixRange(Start, Stop: TPlusNavigator; KeywordBase, SSBase: Integer): Boolean; override;
  published
    property ExtendedSyntax: Boolean read fExtendedSyntax write setExtendedSyntax default False;
    property GreedyStyle: Boolean read fGreedyStyle write setGreedyStyle default True;
    property RussianAlphaChars: Boolean read fRussianAlphaChars write setRussianAlphaChars default False;
    property RegExStartStop: Boolean read fRegExStartStop write setRegExStartStop default False;
  end;

implementation

uses
  SysUtils;

{ TRegExpHighlighter }

constructor TRegExHighlighter.Create(AOwner: TComponent);
begin
  inherited;
  fGreedyStyle := True;
end;

procedure TRegExHighlighter.AcquireKeys;
var i: Integer; sr: TRegExpr;
begin
  for i := Keywords.Count to High(fKeysRE) do
    FreeAndNil(fKeysRE[i]);
  SetLength(fKeysRE, Keywords.Count);
  for i := 0 to High(fKeysRE) do
  begin
    if fKeysRE[i] = nil then
      fKeysRE[i] := TRegExpr.Create;
    sr := fKeysRE[i];
    sr.ModifierI := not(woMatchCase in Keywords.KeyInfos[i].Options);
    sr.ModifierX := ExtendedSyntax;
    sr.ModifierR := RussianAlphaChars;
    sr.ModifierG := GreedyStyle;
    sr.Expression := Keywords[i]
  end;

  { signal that keywords have been acquired by setting KeyLen negative for first keyword;
    TKeywordList sets this field to the keyword length in its EndUpdate processing }
  if Keywords.Count > 0 then
    pKeyInfoLen(Keywords.KeyList[0]).KeyLen := -1;

  fKeysAcquired := True
end;

  {$WARN UNSAFE_CODE OFF}

procedure TRegExHighlighter.ApplyKeywordsList(Start, Stop: TPlusNavigator; BaseIndex: Integer);

type keywfound = record keyw: Integer; Offset: Integer; keylen: Integer end;
var
  pnb: Integer;
  nbkeywtodo: SmallInt;
  keywtodo: array[0..15] of keywfound;
  sposmod: Integer; // min position modified with style

procedure ApplyKwFound;
var ok, inkeyword: Boolean;
  drec: DynInfoRec;
  kinfo: pKeyInfoLen;
  k, m,
  currentlevel,
  currentscope,
  currentpriority: SmallInt;
begin
  fNav1.fPMemo := Start.fPMemo;
  fNav2.fPMemo := Start.fPMemo;
  fNav1.ParNumber := pnb;

  for k := 0 to nbkeywtodo - 1 do
    with keywtodo[k] do
    begin
      fNav1.ParOffset := offset;
      fNav1.RightOfDyn;
      currentlevel := DynToLevel(fNav1.pDynAttr^);
      currentscope := DynToContext(fNav1.pDynAttr^);
      currentpriority := GetPriority(fNav1.pDynAttr^, BaseIndex);
      kinfo := Keywords.KeyList[keyw];

      // Determine delimiter based acceptance
      ok := not(woWholeWordsOnly in kinfo.BasicPart.Options) or
        (((offset = 0) or (pmChar(fNav1.fPar.ParText[offset - 1]) in Delimiters)) and
          (((offset + keylen >= GetParLength(fNav1.fPar^)) or (pmChar(fNav1.fPar.ParText[offset + keylen]) in Delimiters))));

      // Determine scope based acceptance
      ok := ok and (currentlevel < 15) and
        ((kinfo^.Priority = QueryPriority) or
          (((kinfo^.Scope = 0) and (kinfo^.Priority > currentpriority)) or (kinfo^.Scope = currentscope)));
      if ok then
      begin
        fNav2.Assign(fNav1);
        fNav2.Pos := fNav2.Pos + keylen;
        ok := True;
        inkeyword := False;
        if fNav2.DynNb > fNav1.fDynNb then
        begin
          m := fNav1.fDynNb + 1;
          while (m <= fNav2.fDynNb) and ok do
            with fNav1.fPar^.ParExtra.DynCodes[m] do
            begin
              if DynStyle and $C0 <> $C0 then
              begin
                ok := inkeyword;
                inkeyword := False end else if Level < currentlevel then
                  ok := False
                else if KeyIndex[Level] < 0 then
                  ok := False
                else
                  inkeyword := True;
              Inc(m)
            end;
          if inkeyword then
            ok := False
        end
      end;

      // determine positional info acceptance
      if ok and (kinfo.BasicPart.Options * [woFirstParWord, woFirstNonBlank, woStartPar] <> []) then
        if woStartPar in kinfo.BasicPart.Options then
          ok := fNav1.fOffset = 0
        else if woFirstNonBlank in kinfo.BasicPart.Options then
          for m := 0 to fNav1.fOffset - 1 do
          begin
            if not(pmChar(fNav1.fPar.ParText[m]) in [' ', #9]) then
            begin
              ok := False;
              Break
            end
          end else
            for m := 0 to fNav1.fOffset - 1 do
              if not(pmChar(fNav1.fPar.ParText[m]) in Delimiters) then
              begin
                ok := False;
                Break
              end;

      if ok and Assigned(OnKeyword) then
        OnKeyword(Self, fNav1, fNav2, keyw, ok);
      if ok then
      begin
        if sposmod < 0 then
          sposmod := fNav1.Pos
        else if sposmod > fNav1.Pos then
          sposmod := fNav1.Pos;
        with drec do
        begin
          KeyIndex := fNav1.DynAttr.KeyIndex;
          DynStyle := Byte(kinfo.BasicPart.Style) or $C0;
          Backgnd := kinfo.BasicPart.Backgnd;
          Foregnd := kinfo.BasicPart.Foregnd;
          Context := kinfo.BasicPart.ContextNumber;
          CollpsState := [];
          Cursor := kinfo.BasicPart.Cursor;
          StartKLen := keylen;
          StopKLen := StartKLen;
          Level := CurrentLevel + 1;
          KeyIndex[Level] := keyw + BaseIndex;
        end;

        SetDynStyleP(TPlusMemo(fNav1.fPMemo).IParList, fNav1, fNav2, drec, True, False);
      end
    end;
  // k loop over keyword

  fNav1.fPMemo := nil;
  fNav2.fPMemo := nil;
  nbkeywtodo := 0;
end; { local proc. applykwfound }

var i: Integer; spar: string; sreg: TRegExpr;
begin
  if Active and (Keywords.Count > 0) then
  begin
    if (not fKeysAcquired) or (pKeyInfoLen(Keywords.KeyList[0]).KeyLen >= 0) then
      AcquireKeys;
    spar := Start.Par.ParText;
    nbkeywtodo := 0;
    sposmod := -1;
    // flag as not set

    for pnb := Start.fParNb to Stop.ParNumber do
    begin
      if pnb > Start.fParNb then
        spar := TPlusMemo(Start.fPMemo).IParList.Items[pnb].ParText;
      if Length(spar) > 0 then
      begin
        for i := 0 to High(fKeysRE) do
        begin
          sreg := fKeysRE[i];
          if sreg.Exec(spar) then
            repeat
              if nbkeywtodo = 16 then
                ApplyKwFound;
              with keywtodo[nbkeywtodo] do
              begin
                Offset := sreg.MatchPos[0] - 1;
                keyw := i;
                keylen := sreg.MatchLen[0]
              end;
              Inc(nbkeywtodo);
            until not sreg.ExecNext
        end;
        if nbkeywtodo > 0 then
          ApplyKwFound
      end
    end;

    if sposmod >= 0 then
      InvalidateNavs(TPlusMemo(Start.fPMemo).INavigators, sposmod, Stop.fParNb)
  end;
  // if Active

  if SubHighlighter <> nil then
    TRegExHighlighter(SubHighlighter).ApplyKeywordsList(Start, Stop, BaseIndex + Keywords.Count)
end;

destructor TRegExHighlighter.Destroy;
var i: Integer;
begin
  for i := 0 to High(fKeysRE) do
    FreeAndNil(fKeysRE[i]);
  for i := 0 to High(fSSRE)do
  begin
    FreeAndNil(fSSRE[i][0]);
    FreeAndNil(fSSRE[i][1])
  end;
  inherited;
end;

function TRegExHighlighter.FixRange(Start, Stop: TPlusNavigator; KeywordBase, SSBase: Integer): Boolean;
begin
  Start.ParOffset := 0;
  Stop.ParOffset := GetParLength(Stop.Par^);
  Result := True
end;

procedure TRegExHighlighter.InvalidateKeys;
begin
  fKeysAcquired := False;
  if fRegExStartStop and (StartStopKeys <> nil) then
    StartStopKeys.DelChecked := False;
  if (csDesigning in ComponentState) and not(csLoading in ComponentState) then
    ReApplyKeys
end;

procedure TRegExHighlighter.setExtendedSyntax(const Value: Boolean);
begin
  if fExtendedSyntax <> Value then
  begin
    fExtendedSyntax := Value;
    InvalidateKeys
  end
end;

procedure TRegExHighlighter.setRussianAlphaChars(const Value: Boolean);
begin
  if fRussianAlphaChars <> Value then
  begin
    fRussianAlphaChars := Value;
    InvalidateKeys
  end
end;

procedure TRegExHighlighter.setGreedyStyle(const Value: Boolean);
begin
  if Value <> fGreedyStyle then
  begin
    fGreedyStyle := Value;
    InvalidateKeys
  end
end;

procedure TRegExHighlighter.AcquireSS;
  procedure SetRegEx(sr: TRegExpr; Value: string; MatchCase: Boolean);
  begin
    sr.ModifierI := not MatchCase;
    sr.ModifierX := ExtendedSyntax;
    sr.ModifierG := GreedyStyle;
    sr.ModifierR := RussianAlphaChars;
    sr.Expression := Value
  end;

var i: Integer; sp: pStartStopInfo;
begin
  if StartStopKeys = nil then
    Exit;
  for i := StartStopKeys.Count to High(fSSRE) do
  begin
    FreeAndNil(fSSRE[i][0]);
    FreeAndNil(fSSRE[i][1])
  end;
  SetLength(fSSRE, StartStopKeys.Count);
  for i := 0 to High(fSSRE) do
  begin
    sp := StartStopKeys.Pointers[i];
    if fSSRE[i][0] = nil then
      fSSRE[i][0] := TRegExpr.Create;
    SetRegEx(fSSRE[i][0], sp.StartKeyStr, woMatchCase in sp.Attributes.Options);

    if fSSRE[i][1] = nil then
      fSSRE[i][1] := TRegExpr.Create;
    SetRegEx(fSSRE[i][1], sp.StopKeyStr, woMatchCase in sp.Attributes.Options)
  end;

  { signal that start-stop keys have been acquired by setting DelChecked;
    this property is set False by TStartStopKeyList modification methods }
  StartStopKeys.DelChecked := True
end;

procedure TRegExHighlighter.setRegExStartStop(const Value: Boolean);
begin
  if fRegExStartStop <> Value then
  begin
    fRegExStartStop := Value;
    if fRegExStartStop and (StartStopKeys <> nil) then
      StartStopKeys.DelChecked := False;
    if (csDesigning in ComponentState) and not(csLoading in ComponentState) then
      ReApplyKeys
  end
end;

function TRegExHighlighter.FindStart(Start, Stop: TPlusNavigator; BaseIndex: Integer): Boolean;

  function CheckPosOk(Pt: PChar; Ofs: Integer; WO: TWordOptions): Boolean;
  var i: Integer;
  begin
    Result := True;
    if woStartPar in WO then
      Result := Ofs = 0
    else if woFirstNonBlank in WO then
    begin
      for i := 0 to Ofs - 1 do
        if (Pt[i] <> ' ') and (Pt[i] <> #9) then
        begin
          Result := False;
          Break
        end
    end else if woFirstParWord in WO then
    begin
      for i := 0 to Ofs - 1 do
        if not(pmChar(Pt[i]) in Delimiters) then
        begin
          Result := False;
          Break
        end
    end
  end;

var
  slen: Integer;
  i: Integer;
  j, jlim, jadd: SmallInt;
  jssinfo: pStartStopInfo;
  m, mlim: Integer;
  dinfo: DynInfoRec;
  sdyns: TDynInfoArray;
  pdyn: pDynInfoRec;
  currentdyn: DynInfoRec;
  currentpriority, currentscope: SmallInt;
  plen: Integer;

label jContinue, FindHStart;

begin
  if not fRegExStartStop then
  begin
    Result := inherited FindStart(Start, Stop, BaseIndex);
    Exit
  end;

  Start.RightOfDyn;
  Result := False;
  sdyns := nil;
  // to avoid a warning
  if DynToLevel(Start.pDynAttr^) >= 15 then
    Exit;

  if StartStopKeys = nil then
    jlim := 0
  else
    jlim := StartStopKeys.Count;

  if (not Active) or (jlim = 0) then
    goto FindHStart;

  if not StartStopKeys.DelChecked then
    AcquireSS;

  plen := GetParLength(Stop.fPar^);
  for i := 0 to High(fSSRE) do
  begin
    fSSRE[i][0].InputString := Copy(Start.Par.ParText, Start.ParOffset + 1, plen - Start.ParOffset);
    fSSRE[i][0].ExecPos(1)
  end;

  fNav1.fPMemo := Start.fPMemo;
  fNav1.Assign(Start);

  m := fNav1.DynNb;
  mlim := GetDynCount(Start.fPar^);

  jadd := StartStopKeys.ElementSpace;

  sdyns := GetDynArray(Start.fPar^);
  currentdyn := fNav1.DynAttr;
  currentpriority := getpriority(currentdyn, BaseIndex);
  currentscope := DynToContext(currentdyn);

  for i := Start.fOffset to plen - 1 do
  begin
    while (m < mlim) and (sdyns[m].DynOffset <= i) do
    begin
      currentdyn := sdyns[m];
      Inc(m);
      currentpriority := GetPriority(currentdyn, BaseIndex);
      currentscope := DynToContext(currentdyn)
    end;

    jssinfo := StartStopKeys.Pointers[0];
    j := 0;
    while j < jlim do
    begin
      if (jssinfo^.Priority = QueryPriority) or
        ((jssinfo^.Scope = 0) and (jssinfo^.Priority > currentpriority)) or
        ((jssinfo^.Scope = currentscope) and ((jssinfo^.Scope <> 0) or (currentdyn.DynStyle and $80 = 0))) then
      begin
        if (fSSRE[j][0].MatchPos[0] = i + 1) and // could be improved with Match boolean
          CheckPosOk(Start.fPar.ParText, i, jssinfo^.Attributes.Options) then
        begin
          Result := True;
          Break
        end
      end;
      // scope, priority is ok
      jContinue:
      Inc(PAnsiChar(jSSInfo), jadd);
      Inc(j)
    end;
    // j loop over start/stop keys

    if Result then
    begin
      fNav1.ParOffset := i;
      fNav1.RightOfDyn;
      if Assigned(OnStart) then
        OnStart(Self, fNav1, nil, j, Result);
      if not Result then
      begin
        fNav1.ParOffset := Start.ParOffset;
        goto jContinue
      end;

      pdyn := fNav1.pDynAttr;
      dinfo.Level := DynToLevel(pdyn^) + 1;
      dinfo.CollpsLevel := DynToCollapseLevel(pdyn^);
      { check whether we are nesting within the same kind of start-stop key,
            which must be avoided if stopkey=startkey }
      if dinfo.Level - 1 >= 0 then
        if (fNav1.DynAttr.KeyIndex[dinfo.Level - 1] = j or SmallInt($8000)) and
          ((jssinfo^.StartLen = jssinfo^.StopLen) and
            (StrComp(jssinfo^.StartKey, jssinfo^.StopKey) = 0)) then
        begin
          //Inc(i);
          Result := False;
          Continue
        end;
      Stop.Assign(fNav1);
      if dinfo.Level > 0 then
        with Stop do
        begin
          if BackToDyn(0) then
            Par^.ParExtra.DynCodes[DynNb].StopKLen := 0;
          Assign(fNav1);
          RightOfDyn
        end;

      { remove stray dyn codes }
      slen := fSSRE[j][0].MatchLen[0];
      while Stop.ForwardToDyn(fNav1.Pos + slen) do
        Stop.RemoveDyn;

      with dinfo do
      begin
        DynOffset := fNav1.ParOffset;
        KeyIndex := Stop.DynAttr.KeyIndex;
        DynStyle := Byte(jssinfo^.Attributes.Style) or $C0;
        KeyIndex[Level] := -32768 + j + BaseIndex;
        if ssoCollapsible in jssinfo^.ssOptions then
        begin
          Inc(CollpsLevel);
          CollpsState := [pmdCollapsible]
        end else
          CollpsState := [];
        Cursor := jssinfo^.Attributes.Cursor;
        Backgnd := jssinfo^.Attributes.Backgnd;
        Foregnd := jssinfo^.Attributes.Foregnd;
        Context := jssinfo^.Attributes.ContextNumber;
        StartKlen := slen;
        StopKLen := jssinfo^.StopLen;
        //if jssinfo^.StartRightCheck then Inc(StartKLen)
      end;
      with fNav1 do
        if (fDynNb < Length(sdyns)) and (sdyns[fDynNb].DynOffset = fOffset) then
          sdyns[fDynNb] := dinfo
        else
          AddDyn(dinfo);
      Stop.Pos := fNav1.Pos + slen;
      Stop.RightOfDyn;
      Break
    end // found start key

  end;
  // iloop in text buffer

  FindHStart:
  fNav1.fPMemo := nil;
  if SubHighlighter <> nil then
    Result := Result or TRegExHighlighter(SubHighlighter).FindStart(Start, Stop, jlim + BaseIndex)
end; // FindStart

function TRegExHighlighter.FindStop(Start, Stop: TPlusNavigator; BaseIndex: Integer): Boolean;
var
  skeyindex: SmallInt;
  sssindex: SmallInt;
  slen: Integer;
  keyfound: PChar;
  backstart,
  eoff: LongInt;
  i: Integer;
  dinfo: DynInfoRec;
  plen: Integer;

  otherindex: Integer;
  otherssinfo,
  pssinfo: pStartStopInfo;

  slevel: SmallInt;
  scount: Integer;
  spstartdyn: pDynInfoRec;
  sr: TRegExpr;

begin
  if not fRegExStartStop then
  begin
    Result := inherited FindStop(Start, Stop, BaseIndex);
    Exit
  end;

  Result := False;
  spstartdyn := Start.pDynAttr;
  slevel := DynToLevel(spstartdyn^);
  if slevel < 0 then
    Exit;
  skeyindex := spstartdyn^.KeyIndex[slevel];
  sssindex := (skeyindex and $7FFF) - BaseIndex;
  if sssindex < 0 then
    Exit;

  if (not Active) or (skeyindex > 0) or (StartStopKeys = nil) or (sssindex >= StartStopKeys.Count) then
  begin
    if StartStopKeys = nil then
      scount := 0
    else
      scount := StartStopKeys.Count;
    if SubHighlighter <> nil then
      Result := TRegExHighlighter(SubHighlighter).FindStop(Start, Stop, scount + BaseIndex);
    Exit
  end;

  plen := GetParLength(Start.fPar^);
  pSSInfo := StartStopKeys.Pointers[sssindex];
  sr := fSSRE[sssindex][1];

  { go past the start key }
  backstart := 0;
  slen := 0;
  // to avoid a warning

  if Start.fDynNb > 0 then
    with spstartdyn^ do
      if Start.fOffset < DynOffset + StartKLen then
      begin
        backstart := Start.fOffset - (DynOffset + StartKLen);
      end;

  keyfound := Start.fPar.ParText + Start.fOffset - backstart;
  while (not Result) and (keyfound <> nil) do
  begin
    if ssoDelStop in pSSInfo^.ssOptions then
    begin
      while (keyfound^ <> #0) and (not(pmChar(keyfound^) in Delimiters)) do
        Inc(keyfound);
      Result := keyfound^ <> #0;
      if not Result then
        keyfound := nil
    end else
    begin
      sr.InputString := Start.fPar.ParText;
      if sr.ExecPos(Start.fOffset - backstart + 1) then
      begin
        keyfound := Start.fPar.ParText + sr.MatchPos[0] - 1;
        slen := sr.MatchLen[0];
        Result := True
      end else
      begin
        keyfound := nil;
        slen := 0
      end
    end;

    if Result or ((ssoParStop in PSSInfo^.ssOptions) and (Stop.ParOffset = plen)) then
    begin
      Result := True;
      fNav1.fPMemo := Start.fPMemo;
      fNav1.Assign(Stop);
      if keyfound <> nil then
      begin
        eoff := Start.Pos - backstart + (keyfound - Start.fPar.ParText - Start.ParOffset) + slen;
        Stop.Pos := eoff - slen;
        Stop.RightOfDyn;
        while Stop.ForwardToDyn(eoff) do
          Stop.RemoveDyn;
        Stop.Pos := eoff
      end;
      if Assigned(OnStop) then
        OnStop(Self, Start, Stop, sssIndex, Result);
      if not Result then
      begin
        if keyfound <> nil then
          Inc(keyfound);
        Stop.Assign(fNav1)
      end
    end;
  end;

  if Result then
  begin
    fNav1.Assign(Start);
    fNav1.BackToDyn(0);
    fNav1.Par^.ParExtra.DynCodes[fNav1.fDynNb].StopKLen := slen;

    { check whether another identical start key exists }
    otherindex := -1;
    with StartStopKeys do
      for i := (skeyindex and $7FFF) + 1 to Count - 1 do
        with pStartStopInfo(Pointers[i])^ do
          if (Previous = skeyindex and $7FFF) and (Scope = PSSInfo^.Scope) and (Priority = PSSInfo^.Priority) then
          begin
            otherindex := i;
            Break
          end;

    if otherindex = -1 then
    begin
      fNav1.Assign(Start);
      while DynToLevel(fNav1.pDynAttr^) >= spstartdyn.Level do
        fNav1.BackToDyn(0);
      dinfo := fNav1.DynAttr
    end else
      with dinfo, StartStopKeys do
      begin
        otherssinfo := Pointers[otherindex];
        KeyIndex := spstartdyn.KeyIndex;
        CollpsState := spstartdyn.CollpsState;
        CollpsLevel := spstartdyn.CollpsLevel;
        Level := spstartdyn.Level;
        DynStyle := Byte(otherssinfo^.Attributes.Style) or $C0;
        KeyIndex[Level] := -32768 + otherindex;
        Cursor := otherssinfo^.Attributes.Cursor;
        Backgnd := otherssinfo^.Attributes.Backgnd;
        Foregnd := otherssinfo^.Attributes.Foregnd
      end;

    dinfo.StartKLen := 0;
    Stop.AddDyn(dinfo);
    if keyfound = nil then
      Stop.Pos := Stop.Pos + 1;
    // an end at par stop: advance this nav for parser to behave correctly
    fNav1.fPMemo := nil;
  end;
end; { FindStop }

end.

