{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit SCLLaz;

interface

uses
  ScClasses, ScCompilerMagic, ScConsoleUtils, ScConsts, ScCoroutines, 
  ScDateTimeUtils, ScEnumerators, ScIntegerSets, ScInterfaces, ScLists, 
  ScLOGFile, ScLowLevel, ScMD5, ScNoSecretWindow, ScPipes, ScSerializer, 
  ScStrUtils, ScSyncObjs, ScTypInfo, ScUtils, ScWindows, ScXML, ScZLib, 
  LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('SCLLaz', @Register);
end.
