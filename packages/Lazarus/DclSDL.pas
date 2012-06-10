{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit DclSDL;

interface

uses
  SDLReg, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('SDLReg', @SDLReg.Register);
end;

initialization
  RegisterPackage('DclSDL', @Register);
end.
