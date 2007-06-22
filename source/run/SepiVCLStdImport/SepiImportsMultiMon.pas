{*
  Importe l'unit� MultiMon dans un environnement Sepi
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit SepiImportsMultiMon;

interface

uses
  TypInfo, SepiMetaUnits, SepiOrdTypes, SepiStrTypes, SepiArrayTypes,
  SepiCompTypes, Windows, MultiMon;

implementation

{ You must not localize any of the strings this unit contains! }

{------------------------}
{ tagMONITORINFOA import }
{------------------------}

function SepiImporttagMONITORINFOA(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagMONITORINFOA', False, True);

  with Result do
  begin
    AddField('cbSize', System.TypeInfo(DWORD));
    AddField('rcMonitor', 'TRect');
    AddField('rcWork', 'TRect');
    AddField('dwFlags', System.TypeInfo(DWORD));

    Complete;
  end;
end;

{------------------------}
{ tagMONITORINFOW import }
{------------------------}

function SepiImporttagMONITORINFOW(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagMONITORINFOW', False, True);

  with Result do
  begin
    AddField('cbSize', System.TypeInfo(DWORD));
    AddField('rcMonitor', 'TRect');
    AddField('rcWork', 'TRect');
    AddField('dwFlags', System.TypeInfo(DWORD));

    Complete;
  end;
end;

{--------------------------}
{ tagMONITORINFOEXA import }
{--------------------------}

function SepiImporttagMONITORINFOEXA(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagMONITORINFOEXA', False, True);

  with Result do
  begin
    AddField('cbSize', System.TypeInfo(DWORD));
    AddField('rcMonitor', 'TRect');
    AddField('rcWork', 'TRect');
    AddField('dwFlags', System.TypeInfo(DWORD));
    AddField('szDevice', '$1');

    Complete;
  end;
end;

{--------------------------}
{ tagMONITORINFOEXW import }
{--------------------------}

function SepiImporttagMONITORINFOEXW(Owner : TSepiMetaUnit) : TSepiRecordType;
begin
  Result := TSepiRecordType.Create(Owner, 'tagMONITORINFOEXW', False, True);

  with Result do
  begin
    AddField('cbSize', System.TypeInfo(DWORD));
    AddField('rcMonitor', 'TRect');
    AddField('rcWork', 'TRect');
    AddField('dwFlags', System.TypeInfo(DWORD));
    AddField('szDevice', '$2');

    Complete;
  end;
end;

{-------------}
{ Unit import }
{-------------}

function ImportUnit(Root : TSepiMetaRoot) : TSepiMetaUnit;
begin
  Result := TSepiMetaUnit.Create(Root, 'MultiMon',
    ['Windows']);

  // Constants
  TSepiConstant.Create(Result, 'SM_XVIRTUALSCREEN', SM_XVIRTUALSCREEN);
  TSepiConstant.Create(Result, 'SM_YVIRTUALSCREEN', SM_YVIRTUALSCREEN);
  TSepiConstant.Create(Result, 'SM_CXVIRTUALSCREEN', SM_CXVIRTUALSCREEN);
  TSepiConstant.Create(Result, 'SM_CYVIRTUALSCREEN', SM_CYVIRTUALSCREEN);
  TSepiConstant.Create(Result, 'SM_CMONITORS', SM_CMONITORS);
  TSepiConstant.Create(Result, 'SM_SAMEDISPLAYFORMAT', SM_SAMEDISPLAYFORMAT);
  TSepiConstant.Create(Result, 'SM_CMETRICS', SM_CMETRICS);

  // Types
  TSepiType.LoadFromTypeInfo(Result, TypeInfo(HMONITOR));

  // Constants
  TSepiConstant.Create(Result, 'MONITOR_DEFAULTTONULL', MONITOR_DEFAULTTONULL);
  TSepiConstant.Create(Result, 'MONITOR_DEFAULTTOPRIMARY', MONITOR_DEFAULTTOPRIMARY);
  TSepiConstant.Create(Result, 'MONITOR_DEFAULTTONEAREST', MONITOR_DEFAULTTONEAREST);
  TSepiConstant.Create(Result, 'MONITORINFOF_PRIMARY', MONITORINFOF_PRIMARY);

  // Constants
  TSepiConstant.Create(Result, 'CCHDEVICENAME', CCHDEVICENAME);

  // Types
  SepiImporttagMONITORINFOA(Result);
  SepiImporttagMONITORINFOW(Result);
  TSepiTypeAlias.Create(Result, 'tagMONITORINFO', 'tagMONITORINFOA');
  TSepiTypeAlias.Create(Result, 'MONITORINFOA', 'tagMONITORINFOA');
  TSepiTypeAlias.Create(Result, 'MONITORINFOW', 'tagMONITORINFOW');
  TSepiTypeAlias.Create(Result, 'MONITORINFO', 'MONITORINFOA');
  TSepiPointerType.Create(Result, 'LPMONITORINFOA', 'tagMONITORINFOA', True);
  TSepiPointerType.Create(Result, 'LPMONITORINFOW', 'tagMONITORINFOW', True);
  TSepiTypeAlias.Create(Result, 'LPMONITORINFO', 'LPMONITORINFOA');
  TSepiPointerType.Create(Result, 'PMonitorInfoA', 'tagMONITORINFO', True);
  TSepiPointerType.Create(Result, 'PMonitorInfoW', 'tagMONITORINFO', True);
  TSepiTypeAlias.Create(Result, 'PMonitorInfo', 'PMonitorInfoA');
  TSepiTypeAlias.Create(Result, 'TMonitorInfoA', 'tagMONITORINFO');
  TSepiTypeAlias.Create(Result, 'TMonitorInfoW', 'tagMONITORINFO');
  TSepiTypeAlias.Create(Result, 'TMonitorInfo', 'TMonitorInfoA');
  TSepiArrayType.Create(Result, '$1',
    [0, CCHDEVICENAME], TypeInfo(AnsiChar), True);
  SepiImporttagMONITORINFOEXA(Result);
  TSepiArrayType.Create(Result, '$2',
    [0, CCHDEVICENAME], TypeInfo(WideChar), True);
  SepiImporttagMONITORINFOEXW(Result);
  TSepiTypeAlias.Create(Result, 'tagMONITORINFOEX', 'tagMONITORINFOEXA');
  TSepiTypeAlias.Create(Result, 'MONITORINFOEXA', 'tagMONITORINFOEXA');
  TSepiTypeAlias.Create(Result, 'MONITORINFOEXW', 'tagMONITORINFOEXW');
  TSepiTypeAlias.Create(Result, 'MONITORINFOEX', 'MONITORINFOEXA');
  TSepiPointerType.Create(Result, 'LPMONITORINFOEXA', 'tagMONITORINFOEXA', True);
  TSepiPointerType.Create(Result, 'LPMONITORINFOEXW', 'tagMONITORINFOEXW', True);
  TSepiTypeAlias.Create(Result, 'LPMONITORINFOEX', 'LPMONITORINFOEXA');
  TSepiPointerType.Create(Result, 'PMonitorInfoExA', 'tagMONITORINFOEX', True);
  TSepiPointerType.Create(Result, 'PMonitorInfoExW', 'tagMONITORINFOEX', True);
  TSepiTypeAlias.Create(Result, 'PMonitorInfoEx', 'PMonitorInfoExA');
  TSepiTypeAlias.Create(Result, 'TMonitorInfoExA', 'tagMONITORINFOEX');
  TSepiTypeAlias.Create(Result, 'TMonitorInfoExW', 'tagMONITORINFOEX');
  TSepiTypeAlias.Create(Result, 'TMonitorInfoEx', 'TMonitorInfoExA');
  TSepiMethodRefType.Create(Result, 'TMonitorEnumProc',
    'function(hm: HMONITOR; dc: HDC; r: PRect; l: LPARAM): Boolean', False, ccStdCall);
  TSepiMethodRefType.Create(Result, 'TGetSystemMetrics',
    'function(nIndex: Integer): Integer', False, ccStdCall);
  TSepiMethodRefType.Create(Result, 'TMonitorFromWindow',
    'function(hWnd: HWND; dwFlags: DWORD): HMONITOR', False, ccStdCall);
  TSepiMethodRefType.Create(Result, 'TMonitorFromRect',
    'function(lprcScreenCoords: PRect; dwFlags: DWORD): HMONITOR', False, ccStdCall);
  TSepiMethodRefType.Create(Result, 'TMonitorFromPoint',
    'function(ptScreenCoords: TPoint; dwFlags: DWORD): HMONITOR', False, ccStdCall);
  TSepiMethodRefType.Create(Result, 'TGetMonitorInfoA',
    'function(hMonitor: HMONITOR; lpMonitorInfo: PMonitorInfoA): Boolean', False, ccStdCall);
  TSepiMethodRefType.Create(Result, 'TGetMonitorInfoW',
    'function(hMonitor: HMONITOR; lpMonitorInfo: PMonitorInfoW): Boolean', False, ccStdCall);
  TSepiTypeAlias.Create(Result, 'TGetMonitorInfo', 'TGetMonitorInfoA');
  TSepiMethodRefType.Create(Result, 'TEnumDisplayMonitors',
    'function(hdc: HDC; lprcIntersect: PRect; lpfnEnumProc: TMonitorEnumProc; lData: LPARAM ) : Boolean', False, ccStdCall);

  // Global variables
  TSepiVariable.Create(Result, 'GetSystemMetrics',
     @GetSystemMetrics, 'TGetSystemMetrics');
  TSepiVariable.Create(Result, 'MonitorFromWindow',
     @MonitorFromWindow, 'TMonitorFromWindow');
  TSepiVariable.Create(Result, 'MonitorFromRect',
     @MonitorFromRect, 'TMonitorFromRect');
  TSepiVariable.Create(Result, 'MonitorFromPoint',
     @MonitorFromPoint, 'TMonitorFromPoint');
  TSepiVariable.Create(Result, 'GetMonitorInfo',
     @GetMonitorInfo, 'TGetMonitorInfo');
  TSepiVariable.Create(Result, 'GetMonitorInfoA',
     @GetMonitorInfoA, 'TGetMonitorInfoA');
  TSepiVariable.Create(Result, 'GetMonitorInfoW',
     @GetMonitorInfoW, 'TGetMonitorInfoW');
  TSepiVariable.Create(Result, 'EnumDisplayMonitors',
     @EnumDisplayMonitors, 'TEnumDisplayMonitors');

  Result.Complete;
end;

initialization
  SepiRegisterImportedUnit('MultiMon', ImportUnit);
end.

