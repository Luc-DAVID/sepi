{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit DclSVCL;

interface

uses
  SVCLReg, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('SVCLReg', @SVCLReg.Register);
end;

initialization
  RegisterPackage('DclSVCL', @Register);
end.
