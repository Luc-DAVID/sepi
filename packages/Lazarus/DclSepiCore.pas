{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit DclSepiCore;

interface

uses
  SepiCoreReg, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('SepiCoreReg', @SepiCoreReg.Register);
end;

initialization
  RegisterPackage('DclSepiCore', @Register);
end.
