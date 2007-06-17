{*
  Importe l'unit� Windows dans un environnement Sepi
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit SepiImportsWindows;

interface

uses
  TypInfo, SepiMetaUnits, SepiOrdTypes, SepiStrTypes, SepiArrayTypes,
  SepiCompTypes, Windows, Types;

implementation

{ You must not localize any of the strings this unit contains! }

{-----------------------}
{ _LARGE_INTEGER import }
{-----------------------}

function SepiImport_LARGE_INTEGER(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_LARGE_INTEGER', False, True);

  with Result do
  begin
    AddField('LowPart', System.TypeInfo(DWORD), '');
    AddField('HighPart', System.TypeInfo(Longint), 'LowPart');
    AddField('QuadPart', System.TypeInfo(LONGLONG), '');

    Complete;
  end;
end;

{-----------------------}
{ ULARGE_INTEGER import }
{-----------------------}

function SepiImportULARGE_INTEGER(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'ULARGE_INTEGER', False, True);

  with Result do
  begin
    AddField('LowPart', System.TypeInfo(DWORD), '');
    AddField('HighPart', System.TypeInfo(DWORD), 'LowPart');
    AddField('QuadPart', System.TypeInfo(LONGLONG), '');

    Complete;
  end;
end;

{--------------------}
{ _LIST_ENTRY import }
{--------------------}

function SepiImport_LIST_ENTRY(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_LIST_ENTRY', False, True);

  with Result do
  begin
    AddField('Flink', 'PListEntry');
    AddField('Blink', 'PListEntry');

    Complete;
  end;
end;

{------------------------------------}
{ _RTL_CRITICAL_SECTION_DEBUG import }
{------------------------------------}

function SepiImport_RTL_CRITICAL_SECTION_DEBUG(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_RTL_CRITICAL_SECTION_DEBUG', False, True);

  with Result do
  begin
    AddField('Type_18', System.TypeInfo(Word));
    AddField('CreatorBackTraceIndex', System.TypeInfo(Word));
    AddField('CriticalSection', 'PRTLCriticalSection');
    AddField('ProcessLocksList', 'TListEntry');
    AddField('EntryCount', System.TypeInfo(DWORD));
    AddField('ContentionCount', System.TypeInfo(DWORD));
    AddField('Spare', '$1');

    Complete;
  end;
end;

{------------------------------}
{ _RTL_CRITICAL_SECTION import }
{------------------------------}

function SepiImport_RTL_CRITICAL_SECTION(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_RTL_CRITICAL_SECTION', False, True);

  with Result do
  begin
    AddField('DebugInfo', 'PRTLCriticalSectionDebug');
    AddField('LockCount', System.TypeInfo(Longint));
    AddField('RecursionCount', System.TypeInfo(Longint));
    AddField('OwningThread', System.TypeInfo(THandle));
    AddField('LockSemaphore', System.TypeInfo(THandle));
    AddField('Reserved', System.TypeInfo(DWORD));

    Complete;
  end;
end;

{--------------------}
{ _OVERLAPPED import }
{--------------------}

function SepiImport_OVERLAPPED(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_OVERLAPPED', False, True);

  with Result do
  begin
    AddField('Internal', System.TypeInfo(DWORD));
    AddField('InternalHigh', System.TypeInfo(DWORD));
    AddField('Offset', System.TypeInfo(DWORD));
    AddField('OffsetHigh', System.TypeInfo(DWORD));
    AddField('hEvent', System.TypeInfo(THandle));

    Complete;
  end;
end;

{-----------------------------}
{ _SECURITY_ATTRIBUTES import }
{-----------------------------}

function SepiImport_SECURITY_ATTRIBUTES(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_SECURITY_ATTRIBUTES', False, True);

  with Result do
  begin
    AddField('nLength', System.TypeInfo(DWORD));
    AddField('lpSecurityDescriptor', 'Pointer');
    AddField('bInheritHandle', System.TypeInfo(BOOL));

    Complete;
  end;
end;

{-----------------------------}
{ _PROCESS_INFORMATION import }
{-----------------------------}

function SepiImport_PROCESS_INFORMATION(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_PROCESS_INFORMATION', False, True);

  with Result do
  begin
    AddField('hProcess', System.TypeInfo(THandle));
    AddField('hThread', System.TypeInfo(THandle));
    AddField('dwProcessId', System.TypeInfo(DWORD));
    AddField('dwThreadId', System.TypeInfo(DWORD));

    Complete;
  end;
end;

{------------------}
{ _FILETIME import }
{------------------}

function SepiImport_FILETIME(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_FILETIME', False, True);

  with Result do
  begin
    AddField('dwLowDateTime', System.TypeInfo(DWORD));
    AddField('dwHighDateTime', System.TypeInfo(DWORD));

    Complete;
  end;
end;

{--------------------}
{ _SYSTEMTIME import }
{--------------------}

function SepiImport_SYSTEMTIME(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_SYSTEMTIME', False, True);

  with Result do
  begin
    AddField('wYear', System.TypeInfo(Word));
    AddField('wMonth', System.TypeInfo(Word));
    AddField('wDayOfWeek', System.TypeInfo(Word));
    AddField('wDay', System.TypeInfo(Word));
    AddField('wHour', System.TypeInfo(Word));
    AddField('wMinute', System.TypeInfo(Word));
    AddField('wSecond', System.TypeInfo(Word));
    AddField('wMilliseconds', System.TypeInfo(Word));

    Complete;
  end;
end;

{--------------------------}
{ _WIN32_FIND_DATAA import }
{--------------------------}

function SepiImport_WIN32_FIND_DATAA(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_WIN32_FIND_DATAA', False, True);

  with Result do
  begin
    AddField('dwFileAttributes', System.TypeInfo(DWORD));
    AddField('ftCreationTime', 'TFileTime');
    AddField('ftLastAccessTime', 'TFileTime');
    AddField('ftLastWriteTime', 'TFileTime');
    AddField('nFileSizeHigh', System.TypeInfo(DWORD));
    AddField('nFileSizeLow', System.TypeInfo(DWORD));
    AddField('dwReserved0', System.TypeInfo(DWORD));
    AddField('dwReserved1', System.TypeInfo(DWORD));
    AddField('cFileName', '$2');
    AddField('cAlternateFileName', '$3');

    Complete;
  end;
end;

{--------------------------}
{ _WIN32_FIND_DATAW import }
{--------------------------}

function SepiImport_WIN32_FIND_DATAW(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_WIN32_FIND_DATAW', False, True);

  with Result do
  begin
    AddField('dwFileAttributes', System.TypeInfo(DWORD));
    AddField('ftCreationTime', 'TFileTime');
    AddField('ftLastAccessTime', 'TFileTime');
    AddField('ftLastWriteTime', 'TFileTime');
    AddField('nFileSizeHigh', System.TypeInfo(DWORD));
    AddField('nFileSizeLow', System.TypeInfo(DWORD));
    AddField('dwReserved0', System.TypeInfo(DWORD));
    AddField('dwReserved1', System.TypeInfo(DWORD));
    AddField('cFileName', '$4');
    AddField('cAlternateFileName', '$5');

    Complete;
  end;
end;

{-----------------------------------}
{ _WIN32_FILE_ATTRIBUTE_DATA import }
{-----------------------------------}

function SepiImport_WIN32_FILE_ATTRIBUTE_DATA(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, '_WIN32_FILE_ATTRIBUTE_DATA', False, True);

  with Result do
  begin
    AddField('dwFileAttributes', System.TypeInfo(DWORD));
    AddField('ftCreationTime', 'TFileTime');
    AddField('ftLastAccessTime', 'TFileTime');
    AddField('ftLastWriteTime', 'TFileTime');
    AddField('nFileSizeHigh', System.TypeInfo(DWORD));
    AddField('nFileSizeLow', System.TypeInfo(DWORD));

    Complete;
  end;
end;

{------------------}
{ tagBITMAP import }
{------------------}

function SepiImporttagBITMAP(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagBITMAP', True, True);

  with Result do
  begin
    AddField('bmType', System.TypeInfo(Longint));
    AddField('bmWidth', System.TypeInfo(Longint));
    AddField('bmHeight', System.TypeInfo(Longint));
    AddField('bmWidthBytes', System.TypeInfo(Longint));
    AddField('bmPlanes', System.TypeInfo(Word));
    AddField('bmBitsPixel', System.TypeInfo(Word));
    AddField('bmBits', 'Pointer');

    Complete;
  end;
end;

{----------------------------}
{ tagBITMAPINFOHEADER import }
{----------------------------}

function SepiImporttagBITMAPINFOHEADER(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagBITMAPINFOHEADER', True, True);

  with Result do
  begin
    AddField('biSize', System.TypeInfo(DWORD));
    AddField('biWidth', System.TypeInfo(Longint));
    AddField('biHeight', System.TypeInfo(Longint));
    AddField('biPlanes', System.TypeInfo(Word));
    AddField('biBitCount', System.TypeInfo(Word));
    AddField('biCompression', System.TypeInfo(DWORD));
    AddField('biSizeImage', System.TypeInfo(DWORD));
    AddField('biXPelsPerMeter', System.TypeInfo(Longint));
    AddField('biYPelsPerMeter', System.TypeInfo(Longint));
    AddField('biClrUsed', System.TypeInfo(DWORD));
    AddField('biClrImportant', System.TypeInfo(DWORD));

    Complete;
  end;
end;

{----------------------------}
{ tagBITMAPFILEHEADER import }
{----------------------------}

function SepiImporttagBITMAPFILEHEADER(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagBITMAPFILEHEADER', True, True);

  with Result do
  begin
    AddField('bfType', System.TypeInfo(Word));
    AddField('bfSize', System.TypeInfo(DWORD));
    AddField('bfReserved1', System.TypeInfo(Word));
    AddField('bfReserved2', System.TypeInfo(Word));
    AddField('bfOffBits', System.TypeInfo(DWORD));

    Complete;
  end;
end;

{-------------------------}
{ tagFONTSIGNATURE import }
{-------------------------}

function SepiImporttagFONTSIGNATURE(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagFONTSIGNATURE', True, True);

  with Result do
  begin
    AddField('fsUsb', '$6');
    AddField('fsCsb', '$7');

    Complete;
  end;
end;

{-----------------------}
{ tagTEXTMETRICA import }
{-----------------------}

function SepiImporttagTEXTMETRICA(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagTEXTMETRICA', False, True);

  with Result do
  begin
    AddField('tmHeight', System.TypeInfo(Longint));
    AddField('tmAscent', System.TypeInfo(Longint));
    AddField('tmDescent', System.TypeInfo(Longint));
    AddField('tmInternalLeading', System.TypeInfo(Longint));
    AddField('tmExternalLeading', System.TypeInfo(Longint));
    AddField('tmAveCharWidth', System.TypeInfo(Longint));
    AddField('tmMaxCharWidth', System.TypeInfo(Longint));
    AddField('tmWeight', System.TypeInfo(Longint));
    AddField('tmOverhang', System.TypeInfo(Longint));
    AddField('tmDigitizedAspectX', System.TypeInfo(Longint));
    AddField('tmDigitizedAspectY', System.TypeInfo(Longint));
    AddField('tmFirstChar', System.TypeInfo(AnsiChar));
    AddField('tmLastChar', System.TypeInfo(AnsiChar));
    AddField('tmDefaultChar', System.TypeInfo(AnsiChar));
    AddField('tmBreakChar', System.TypeInfo(AnsiChar));
    AddField('tmItalic', System.TypeInfo(Byte));
    AddField('tmUnderlined', System.TypeInfo(Byte));
    AddField('tmStruckOut', System.TypeInfo(Byte));
    AddField('tmPitchAndFamily', System.TypeInfo(Byte));
    AddField('tmCharSet', System.TypeInfo(Byte));

    Complete;
  end;
end;

{-----------------------}
{ tagTEXTMETRICW import }
{-----------------------}

function SepiImporttagTEXTMETRICW(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagTEXTMETRICW', False, True);

  with Result do
  begin
    AddField('tmHeight', System.TypeInfo(Longint));
    AddField('tmAscent', System.TypeInfo(Longint));
    AddField('tmDescent', System.TypeInfo(Longint));
    AddField('tmInternalLeading', System.TypeInfo(Longint));
    AddField('tmExternalLeading', System.TypeInfo(Longint));
    AddField('tmAveCharWidth', System.TypeInfo(Longint));
    AddField('tmMaxCharWidth', System.TypeInfo(Longint));
    AddField('tmWeight', System.TypeInfo(Longint));
    AddField('tmOverhang', System.TypeInfo(Longint));
    AddField('tmDigitizedAspectX', System.TypeInfo(Longint));
    AddField('tmDigitizedAspectY', System.TypeInfo(Longint));
    AddField('tmFirstChar', System.TypeInfo(WideChar));
    AddField('tmLastChar', System.TypeInfo(WideChar));
    AddField('tmDefaultChar', System.TypeInfo(WideChar));
    AddField('tmBreakChar', System.TypeInfo(WideChar));
    AddField('tmItalic', System.TypeInfo(Byte));
    AddField('tmUnderlined', System.TypeInfo(Byte));
    AddField('tmStruckOut', System.TypeInfo(Byte));
    AddField('tmPitchAndFamily', System.TypeInfo(Byte));
    AddField('tmCharSet', System.TypeInfo(Byte));

    Complete;
  end;
end;

{--------------------------}
{ tagNEWTEXTMETRICA import }
{--------------------------}

function SepiImporttagNEWTEXTMETRICA(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagNEWTEXTMETRICA', False, True);

  with Result do
  begin
    AddField('tmHeight', System.TypeInfo(Longint));
    AddField('tmAscent', System.TypeInfo(Longint));
    AddField('tmDescent', System.TypeInfo(Longint));
    AddField('tmInternalLeading', System.TypeInfo(Longint));
    AddField('tmExternalLeading', System.TypeInfo(Longint));
    AddField('tmAveCharWidth', System.TypeInfo(Longint));
    AddField('tmMaxCharWidth', System.TypeInfo(Longint));
    AddField('tmWeight', System.TypeInfo(Longint));
    AddField('tmOverhang', System.TypeInfo(Longint));
    AddField('tmDigitizedAspectX', System.TypeInfo(Longint));
    AddField('tmDigitizedAspectY', System.TypeInfo(Longint));
    AddField('tmFirstChar', System.TypeInfo(AnsiChar));
    AddField('tmLastChar', System.TypeInfo(AnsiChar));
    AddField('tmDefaultChar', System.TypeInfo(AnsiChar));
    AddField('tmBreakChar', System.TypeInfo(AnsiChar));
    AddField('tmItalic', System.TypeInfo(Byte));
    AddField('tmUnderlined', System.TypeInfo(Byte));
    AddField('tmStruckOut', System.TypeInfo(Byte));
    AddField('tmPitchAndFamily', System.TypeInfo(Byte));
    AddField('tmCharSet', System.TypeInfo(Byte));
    AddField('ntmFlags', System.TypeInfo(DWORD));
    AddField('ntmSizeEM', System.TypeInfo(UINT));
    AddField('ntmCellHeight', System.TypeInfo(UINT));
    AddField('ntmAvgWidth', System.TypeInfo(UINT));

    Complete;
  end;
end;

{--------------------------}
{ tagNEWTEXTMETRICW import }
{--------------------------}

function SepiImporttagNEWTEXTMETRICW(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagNEWTEXTMETRICW', False, True);

  with Result do
  begin
    AddField('tmHeight', System.TypeInfo(Longint));
    AddField('tmAscent', System.TypeInfo(Longint));
    AddField('tmDescent', System.TypeInfo(Longint));
    AddField('tmInternalLeading', System.TypeInfo(Longint));
    AddField('tmExternalLeading', System.TypeInfo(Longint));
    AddField('tmAveCharWidth', System.TypeInfo(Longint));
    AddField('tmMaxCharWidth', System.TypeInfo(Longint));
    AddField('tmWeight', System.TypeInfo(Longint));
    AddField('tmOverhang', System.TypeInfo(Longint));
    AddField('tmDigitizedAspectX', System.TypeInfo(Longint));
    AddField('tmDigitizedAspectY', System.TypeInfo(Longint));
    AddField('tmFirstChar', System.TypeInfo(WideChar));
    AddField('tmLastChar', System.TypeInfo(WideChar));
    AddField('tmDefaultChar', System.TypeInfo(WideChar));
    AddField('tmBreakChar', System.TypeInfo(WideChar));
    AddField('tmItalic', System.TypeInfo(Byte));
    AddField('tmUnderlined', System.TypeInfo(Byte));
    AddField('tmStruckOut', System.TypeInfo(Byte));
    AddField('tmPitchAndFamily', System.TypeInfo(Byte));
    AddField('tmCharSet', System.TypeInfo(Byte));
    AddField('ntmFlags', System.TypeInfo(DWORD));
    AddField('ntmSizeEM', System.TypeInfo(UINT));
    AddField('ntmCellHeight', System.TypeInfo(UINT));
    AddField('ntmAvgWidth', System.TypeInfo(UINT));

    Complete;
  end;
end;

{----------------------------}
{ tagNEWTEXTMETRICEXA import }
{----------------------------}

function SepiImporttagNEWTEXTMETRICEXA(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagNEWTEXTMETRICEXA', True, True);

  with Result do
  begin
    AddField('ntmTm', 'TNewTextMetricA');
    AddField('ntmFontSig', 'TFontSignature');

    Complete;
  end;
end;

{----------------------------}
{ tagNEWTEXTMETRICEXW import }
{----------------------------}

function SepiImporttagNEWTEXTMETRICEXW(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagNEWTEXTMETRICEXW', True, True);

  with Result do
  begin
    AddField('ntmTm', 'TNewTextMetricW');
    AddField('ntmFontSig', 'TFontSignature');

    Complete;
  end;
end;

{------------------------}
{ tagPALETTEENTRY import }
{------------------------}

function SepiImporttagPALETTEENTRY(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagPALETTEENTRY', True, True);

  with Result do
  begin
    AddField('peRed', System.TypeInfo(Byte));
    AddField('peGreen', System.TypeInfo(Byte));
    AddField('peBlue', System.TypeInfo(Byte));
    AddField('peFlags', System.TypeInfo(Byte));

    Complete;
  end;
end;

{----------------------}
{ tagLOGPALETTE import }
{----------------------}

function SepiImporttagLOGPALETTE(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagLOGPALETTE', True, True);

  with Result do
  begin
    AddField('palVersion', System.TypeInfo(Word));
    AddField('palNumEntries', System.TypeInfo(Word));
    AddField('palPalEntry', '$8');

    Complete;
  end;
end;

{-----------------------}
{ TMaxLogPalette import }
{-----------------------}

function SepiImportTMaxLogPalette(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'TMaxLogPalette', True, True);

  with Result do
  begin
    AddField('palVersion', System.TypeInfo(Word));
    AddField('palNumEntries', System.TypeInfo(Word));
    AddField('palPalEntry', '$9');

    Complete;
  end;
end;

{----------------------}
{ tagDIBSECTION import }
{----------------------}

function SepiImporttagDIBSECTION(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagDIBSECTION', True, True);

  with Result do
  begin
    AddField('dsBm', 'TBitmap');
    AddField('dsBmih', 'TBitmapInfoHeader');
    AddField('dsBitfields', '$10');
    AddField('dshSection', System.TypeInfo(THandle));
    AddField('dsOffset', System.TypeInfo(DWORD));

    Complete;
  end;
end;

{---------------}
{ tagMSG import }
{---------------}

function SepiImporttagMSG(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagMSG', True, True);

  with Result do
  begin
    AddField('hwnd', System.TypeInfo(HWND));
    AddField('message', System.TypeInfo(UINT));
    AddField('wParam', System.TypeInfo(WPARAM));
    AddField('lParam', System.TypeInfo(LPARAM));
    AddField('time', System.TypeInfo(DWORD));
    AddField('pt', 'TPoint');

    Complete;
  end;
end;

{-------------}
{ Unit import }
{-------------}

function ImportUnit(Root : TSepiMetaRoot) : TSepiMetaUnit;
begin
  Result := TSepiMetaUnit.Create(Root, 'Windows',
    ['Types']);

  // Types
  TSepiTypeAlias.Create(Result, 'WCHAR', TypeInfo(WideChar));
  TSepiTypeAlias.Create(Result, 'PWChar', 'PWideChar');
  TSepiTypeAlias.Create(Result, 'LPSTR', 'PAnsiChar');
  TSepiPointerType.Create(Result, 'PLPSTR', 'LPSTR', True);
  TSepiTypeAlias.Create(Result, 'LPCSTR', 'PAnsiChar');
  TSepiTypeAlias.Create(Result, 'LPCTSTR', 'PAnsiChar');
  TSepiTypeAlias.Create(Result, 'LPTSTR', 'PAnsiChar');
  TSepiTypeAlias.Create(Result, 'LPWSTR', 'PWideChar');
  TSepiPointerType.Create(Result, 'PLPWSTR', 'LPWSTR', True);
  TSepiTypeAlias.Create(Result, 'LPCWSTR', 'PWideChar');
  TSepiTypeAlias.Create(Result, 'DWORD', TypeInfo(Types.DWORD));
  TSepiTypeAlias.Create(Result, 'BOOL', TypeInfo(LongBool));
  TSepiPointerType.Create(Result, 'PBOOL', TypeInfo(BOOL), True);
  TSepiTypeAlias.Create(Result, 'PByte', 'System.PByte');
  TSepiPointerType.Create(Result, 'PINT', TypeInfo(Integer), True);
  TSepiPointerType.Create(Result, 'PSingle', TypeInfo(Single), True);
  TSepiPointerType.Create(Result, 'PWORD', TypeInfo(Word), True);
  TSepiPointerType.Create(Result, 'PDWORD', TypeInfo(DWORD), True);
  TSepiTypeAlias.Create(Result, 'LPDWORD', 'PDWORD');
  TSepiTypeAlias.Create(Result, 'UCHAR', TypeInfo(Byte));
  TSepiPointerType.Create(Result, 'PUCHAR', TypeInfo(Byte), True);
  TSepiTypeAlias.Create(Result, 'SHORT', TypeInfo(Smallint));
  TSepiTypeAlias.Create(Result, 'UINT', TypeInfo(LongWord));
  TSepiPointerType.Create(Result, 'PUINT', TypeInfo(UINT), True);
  TSepiTypeAlias.Create(Result, 'ULONG', TypeInfo(Cardinal));
  TSepiPointerType.Create(Result, 'PULONG', TypeInfo(ULONG), True);
  TSepiTypeAlias.Create(Result, 'LCID', TypeInfo(DWORD));
  TSepiTypeAlias.Create(Result, 'LANGID', TypeInfo(Word));
  TSepiPointerType.Create(Result, 'PHandle', TypeInfo(THandle), True);

  // Constants
  TSepiConstant.Create(Result, 'MAX_PATH', MAX_PATH);

  // Types
  TSepiTypeAlias.Create(Result, 'LONGLONG', TypeInfo(Int64));
  TSepiTypeAlias.Create(Result, 'PSID', 'Pointer');
  TSepiPointerType.Create(Result, 'PLargeInteger', 'TLargeInteger', True);
  SepiImport_LARGE_INTEGER(Result);
  TSepiTypeAlias.Create(Result, 'TLargeInteger', TypeInfo(Int64));
  TSepiTypeAlias.Create(Result, 'LARGE_INTEGER', '_LARGE_INTEGER');
  SepiImportULARGE_INTEGER(Result);
  TSepiPointerType.Create(Result, 'PULargeInteger', 'TULargeInteger', True);
  TSepiTypeAlias.Create(Result, 'TULargeInteger', 'ULARGE_INTEGER');
  TSepiPointerType.Create(Result, 'PListEntry', 'TListEntry', True);
  SepiImport_LIST_ENTRY(Result);
  TSepiTypeAlias.Create(Result, 'TListEntry', '_LIST_ENTRY');
  TSepiTypeAlias.Create(Result, 'LIST_ENTRY', '_LIST_ENTRY');

  // Types
  TSepiPointerType.Create(Result, 'PRTLCriticalSection', 'TRTLCriticalSection', True);
  TSepiPointerType.Create(Result, 'PRTLCriticalSectionDebug', 'TRTLCriticalSectionDebug', True);
  TSepiArrayType.Create(Result, '$1',
    [0, 1], TypeInfo(DWORD), True);
  SepiImport_RTL_CRITICAL_SECTION_DEBUG(Result);
  TSepiTypeAlias.Create(Result, 'TRTLCriticalSectionDebug', '_RTL_CRITICAL_SECTION_DEBUG');
  TSepiTypeAlias.Create(Result, 'RTL_CRITICAL_SECTION_DEBUG', '_RTL_CRITICAL_SECTION_DEBUG');
  SepiImport_RTL_CRITICAL_SECTION(Result);
  TSepiTypeAlias.Create(Result, 'TRTLCriticalSection', '_RTL_CRITICAL_SECTION');
  TSepiTypeAlias.Create(Result, 'RTL_CRITICAL_SECTION', '_RTL_CRITICAL_SECTION');

  // Types
  TSepiTypeAlias.Create(Result, 'WPARAM', TypeInfo(Longint));
  TSepiTypeAlias.Create(Result, 'LPARAM', TypeInfo(Longint));
  TSepiTypeAlias.Create(Result, 'LRESULT', TypeInfo(Longint));

  // Types
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HWND));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HHOOK));
  TSepiTypeAlias.Create(Result, 'ATOM', TypeInfo(Word));
  TSepiTypeAlias.Create(Result, 'TAtom', TypeInfo(Word));
  TSepiTypeAlias.Create(Result, 'HGLOBAL', TypeInfo(THandle));
  TSepiTypeAlias.Create(Result, 'HLOCAL', TypeInfo(THandle));
  TSepiTypeAlias.Create(Result, 'FARPROC', 'Pointer');
  TSepiTypeAlias.Create(Result, 'TFarProc', 'Pointer');
  TSepiTypeAlias.Create(Result, 'PROC_22', 'Pointer');
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HGDIOBJ));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HACCEL));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HBITMAP));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HBRUSH));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HCOLORSPACE));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HDC));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HGLRC));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HDESK));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HENHMETAFILE));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HFONT));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HICON));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HMENU));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HMETAFILE));
  TSepiTypeAlias.Create(Result, 'HINST', TypeInfo(System.HINST));
  TSepiTypeAlias.Create(Result, 'HMODULE', TypeInfo(System.HMODULE));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HPALETTE));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HPEN));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HRGN));
  TSepiTypeAlias.Create(Result, 'HRSRC', TypeInfo(System.HRSRC));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HSTR));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HTASK));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HWINSTA));
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HKL));
  TSepiTypeAlias.Create(Result, 'HFILE', TypeInfo(LongWord));
  TSepiTypeAlias.Create(Result, 'HCURSOR', TypeInfo(HICON));
  TSepiTypeAlias.Create(Result, 'COLORREF', TypeInfo(DWORD));
  TSepiTypeAlias.Create(Result, 'TColorRef', TypeInfo(DWORD));

  // Routines
  TSepiMetaMethod.Create(Result, 'MoveMemory', @MoveMemory,
    'procedure(Destination: Pointer; Source: Pointer; Length: DWORD)');
  TSepiMetaMethod.Create(Result, 'CopyMemory', @CopyMemory,
    'procedure(Destination: Pointer; Source: Pointer; Length: DWORD)');
  TSepiMetaMethod.Create(Result, 'FillMemory', @FillMemory,
    'procedure(Destination: Pointer; Length: DWORD; Fill: Byte)');
  TSepiMetaMethod.Create(Result, 'ZeroMemory', @ZeroMemory,
    'procedure(Destination: Pointer; Length: DWORD)');

  // Types
  TSepiPointerType.Create(Result, 'POverlapped', 'TOverlapped', True);
  SepiImport_OVERLAPPED(Result);
  TSepiTypeAlias.Create(Result, 'TOverlapped', '_OVERLAPPED');
  TSepiTypeAlias.Create(Result, 'OVERLAPPED', '_OVERLAPPED');
  TSepiPointerType.Create(Result, 'PSecurityAttributes', 'TSecurityAttributes', True);
  SepiImport_SECURITY_ATTRIBUTES(Result);
  TSepiTypeAlias.Create(Result, 'TSecurityAttributes', '_SECURITY_ATTRIBUTES');
  TSepiTypeAlias.Create(Result, 'SECURITY_ATTRIBUTES', '_SECURITY_ATTRIBUTES');
  TSepiPointerType.Create(Result, 'PProcessInformation', 'TProcessInformation', True);
  SepiImport_PROCESS_INFORMATION(Result);
  TSepiTypeAlias.Create(Result, 'TProcessInformation', '_PROCESS_INFORMATION');
  TSepiTypeAlias.Create(Result, 'PROCESS_INFORMATION', '_PROCESS_INFORMATION');
  TSepiPointerType.Create(Result, 'PFileTime', 'TFileTime', True);
  SepiImport_FILETIME(Result);
  TSepiTypeAlias.Create(Result, 'TFileTime', '_FILETIME');
  TSepiTypeAlias.Create(Result, 'FILETIME', '_FILETIME');
  TSepiPointerType.Create(Result, 'PSystemTime', 'TSystemTime', True);
  SepiImport_SYSTEMTIME(Result);
  TSepiTypeAlias.Create(Result, 'TSystemTime', '_SYSTEMTIME');
  TSepiTypeAlias.Create(Result, 'SYSTEMTIME', '_SYSTEMTIME');
  TSepiPointerType.Create(Result, 'PWin32FindDataA', 'TWin32FindDataA', True);
  TSepiPointerType.Create(Result, 'PWin32FindDataW', 'TWin32FindDataW', True);
  TSepiTypeAlias.Create(Result, 'PWin32FindData', 'PWin32FindDataA');
  TSepiArrayType.Create(Result, '$2',
    [0, MAX_PATH - 1], TypeInfo(AnsiChar), True);
  TSepiArrayType.Create(Result, '$3',
    [0, 13], TypeInfo(AnsiChar), True);
  SepiImport_WIN32_FIND_DATAA(Result);
  TSepiArrayType.Create(Result, '$4',
    [0, MAX_PATH - 1], TypeInfo(WideChar), True);
  TSepiArrayType.Create(Result, '$5',
    [0, 13], TypeInfo(WideChar), True);
  SepiImport_WIN32_FIND_DATAW(Result);
  TSepiTypeAlias.Create(Result, '_WIN32_FIND_DATA', '_WIN32_FIND_DATAA');
  TSepiTypeAlias.Create(Result, 'TWin32FindDataA', '_WIN32_FIND_DATAA');
  TSepiTypeAlias.Create(Result, 'TWin32FindDataW', '_WIN32_FIND_DATAW');
  TSepiTypeAlias.Create(Result, 'TWin32FindData', 'TWin32FindDataA');
  TSepiTypeAlias.Create(Result, 'WIN32_FIND_DATAA', '_WIN32_FIND_DATAA');
  TSepiTypeAlias.Create(Result, 'WIN32_FIND_DATAW', '_WIN32_FIND_DATAW');
  TSepiTypeAlias.Create(Result, 'WIN32_FIND_DATA', 'WIN32_FIND_DATAA');
  TSepiPointerType.Create(Result, 'PWin32FileAttributeData', 'TWin32FileAttributeData', True);
  SepiImport_WIN32_FILE_ATTRIBUTE_DATA(Result);
  TSepiTypeAlias.Create(Result, 'TWin32FileAttributeData', '_WIN32_FILE_ATTRIBUTE_DATA');
  TSepiTypeAlias.Create(Result, 'WIN32_FILE_ATTRIBUTE_DATA', '_WIN32_FILE_ATTRIBUTE_DATA');

  // Types
  TSepiPointerType.Create(Result, 'PBitmap', 'TBitmap', True);
  SepiImporttagBITMAP(Result);
  TSepiTypeAlias.Create(Result, 'TBitmap', 'tagBITMAP');
  TSepiTypeAlias.Create(Result, 'BITMAP', 'tagBITMAP');
  TSepiPointerType.Create(Result, 'PBitmapInfoHeader', 'TBitmapInfoHeader', True);
  SepiImporttagBITMAPINFOHEADER(Result);
  TSepiTypeAlias.Create(Result, 'TBitmapInfoHeader', 'tagBITMAPINFOHEADER');
  TSepiTypeAlias.Create(Result, 'BITMAPINFOHEADER', 'tagBITMAPINFOHEADER');
  TSepiPointerType.Create(Result, 'PBitmapFileHeader', 'TBitmapFileHeader', True);
  SepiImporttagBITMAPFILEHEADER(Result);
  TSepiTypeAlias.Create(Result, 'TBitmapFileHeader', 'tagBITMAPFILEHEADER');
  TSepiTypeAlias.Create(Result, 'BITMAPFILEHEADER', 'tagBITMAPFILEHEADER');
  TSepiPointerType.Create(Result, 'PFontSignature', 'TFontSignature', True);
  TSepiArrayType.Create(Result, '$6',
    [0, 3], TypeInfo(DWORD), True);
  TSepiArrayType.Create(Result, '$7',
    [0, 1], TypeInfo(DWORD), True);
  SepiImporttagFONTSIGNATURE(Result);
  TSepiTypeAlias.Create(Result, 'TFontSignature', 'tagFONTSIGNATURE');
  TSepiTypeAlias.Create(Result, 'FONTSIGNATURE', 'tagFONTSIGNATURE');

  // Types
  TSepiPointerType.Create(Result, 'PTextMetricA', 'TTextMetricA', True);
  TSepiPointerType.Create(Result, 'PTextMetricW', 'TTextMetricW', True);
  TSepiTypeAlias.Create(Result, 'PTextMetric', 'PTextMetricA');
  SepiImporttagTEXTMETRICA(Result);
  SepiImporttagTEXTMETRICW(Result);
  TSepiTypeAlias.Create(Result, 'tagTEXTMETRIC', 'tagTEXTMETRICA');
  TSepiTypeAlias.Create(Result, 'TTextMetricA', 'tagTEXTMETRICA');
  TSepiTypeAlias.Create(Result, 'TTextMetricW', 'tagTEXTMETRICW');
  TSepiTypeAlias.Create(Result, 'TTextMetric', 'TTextMetricA');
  TSepiTypeAlias.Create(Result, 'TEXTMETRICA', 'tagTEXTMETRICA');
  TSepiTypeAlias.Create(Result, 'TEXTMETRICW', 'tagTEXTMETRICW');
  TSepiTypeAlias.Create(Result, 'TEXTMETRIC', 'TEXTMETRICA');

  // Constants
  TSepiConstant.Create(Result, 'NTM_REGULAR', NTM_REGULAR);
  TSepiConstant.Create(Result, 'NTM_BOLD', NTM_BOLD);
  TSepiConstant.Create(Result, 'NTM_ITALIC', NTM_ITALIC);

  // Types
  TSepiPointerType.Create(Result, 'PNewTextMetricA', 'TNewTextMetricA', True);
  TSepiPointerType.Create(Result, 'PNewTextMetricW', 'TNewTextMetricW', True);
  TSepiTypeAlias.Create(Result, 'PNewTextMetric', 'PNewTextMetricA');
  SepiImporttagNEWTEXTMETRICA(Result);
  SepiImporttagNEWTEXTMETRICW(Result);
  TSepiTypeAlias.Create(Result, 'tagNEWTEXTMETRIC', 'tagNEWTEXTMETRICA');
  TSepiTypeAlias.Create(Result, 'TNewTextMetricA', 'tagNEWTEXTMETRICA');
  TSepiTypeAlias.Create(Result, 'TNewTextMetricW', 'tagNEWTEXTMETRICW');
  TSepiTypeAlias.Create(Result, 'TNewTextMetric', 'TNewTextMetricA');
  TSepiTypeAlias.Create(Result, 'NEWTEXTMETRICA', 'tagNEWTEXTMETRICA');
  TSepiTypeAlias.Create(Result, 'NEWTEXTMETRICW', 'tagNEWTEXTMETRICW');
  TSepiTypeAlias.Create(Result, 'NEWTEXTMETRIC', 'NEWTEXTMETRICA');
  TSepiPointerType.Create(Result, 'PNewTextMetricExA', 'TNewTextMetricExA', True);
  SepiImporttagNEWTEXTMETRICEXA(Result);
  TSepiTypeAlias.Create(Result, 'TNewTextMetricExA', 'tagNEWTEXTMETRICEXA');
  TSepiTypeAlias.Create(Result, 'NEWTEXTMETRICEXA', 'tagNEWTEXTMETRICEXA');
  TSepiPointerType.Create(Result, 'PNewTextMetricExW', 'TNewTextMetricExW', True);
  SepiImporttagNEWTEXTMETRICEXW(Result);
  TSepiTypeAlias.Create(Result, 'TNewTextMetricExW', 'tagNEWTEXTMETRICEXW');
  TSepiTypeAlias.Create(Result, 'NEWTEXTMETRICEXW', 'tagNEWTEXTMETRICEXW');
  TSepiTypeAlias.Create(Result, 'PNewTextMetricEx', 'PNewTextMetricExA');
  TSepiPointerType.Create(Result, 'PPaletteEntry', 'TPaletteEntry', True);
  SepiImporttagPALETTEENTRY(Result);
  TSepiTypeAlias.Create(Result, 'TPaletteEntry', 'tagPALETTEENTRY');
  TSepiTypeAlias.Create(Result, 'PALETTEENTRY', 'tagPALETTEENTRY');
  TSepiPointerType.Create(Result, 'PLogPalette', 'TLogPalette', True);
  TSepiArrayType.Create(Result, '$8',
    [0, 0], 'TPaletteEntry', True);
  SepiImporttagLOGPALETTE(Result);
  TSepiTypeAlias.Create(Result, 'TLogPalette', 'tagLOGPALETTE');
  TSepiTypeAlias.Create(Result, 'LOGPALETTE', 'tagLOGPALETTE');
  TSepiPointerType.Create(Result, 'PMaxLogPalette', 'TMaxLogPalette', True);
  TSepiArrayType.Create(Result, '$9',
    [Integer(Low(Byte)), Integer(High(Byte))], 'TPaletteEntry', True);
  SepiImportTMaxLogPalette(Result);

  // Types
  TSepiPointerType.Create(Result, 'PDIBSection', 'TDIBSection', True);
  TSepiArrayType.Create(Result, '$10',
    [0, 2], TypeInfo(DWORD), True);
  SepiImporttagDIBSECTION(Result);
  TSepiTypeAlias.Create(Result, 'TDIBSection', 'tagDIBSECTION');
  TSepiTypeAlias.Create(Result, 'DIBSECTION', 'tagDIBSECTION');
  TSepiPointerType.Create(Result, 'PMsg', 'TMsg', True);
  SepiImporttagMSG(Result);
  TSepiTypeAlias.Create(Result, 'TMsg', 'tagMSG');
  TSepiTypeAlias.Create(Result, 'MSG', 'tagMSG');

  // Routines
  TSepiMetaMethod.Create(Result, 'SmallPointToPoint', @SmallPointToPoint,
    'function(const P: TSmallPoint): TPoint');
  TSepiMetaMethod.Create(Result, 'PointToSmallPoint', @PointToSmallPoint,
    'function(const P: TPoint): TSmallPoint');
  TSepiMetaMethod.Create(Result, 'MakeWParam', @MakeWParam,
    'function(l, h: Word): WPARAM');
  TSepiMetaMethod.Create(Result, 'MakeLParam', @MakeLParam,
    'function(l, h: Word): LPARAM');
  TSepiMetaMethod.Create(Result, 'MakeLResult', @MakeLResult,
    'function(l, h: Word): LRESULT');

  // Types
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HKEY));
  TSepiPointerType.Create(Result, 'PHKEY', TypeInfo(HKEY), True);

  // Constants
  TSepiConstant.Create(Result, 'HKEY_CLASSES_ROOT', HKEY_CLASSES_ROOT);
  TSepiConstant.Create(Result, 'HKEY_CURRENT_USER', HKEY_CURRENT_USER);
  TSepiConstant.Create(Result, 'HKEY_LOCAL_MACHINE', HKEY_LOCAL_MACHINE);
  TSepiConstant.Create(Result, 'HKEY_USERS', HKEY_USERS);
  TSepiConstant.Create(Result, 'HKEY_PERFORMANCE_DATA', HKEY_PERFORMANCE_DATA);
  TSepiConstant.Create(Result, 'HKEY_CURRENT_CONFIG', HKEY_CURRENT_CONFIG);
  TSepiConstant.Create(Result, 'HKEY_DYN_DATA', HKEY_DYN_DATA);

  Result.Complete;
end;

initialization
  SepiRegisterImportedUnit('Windows', ImportUnit);
end.

