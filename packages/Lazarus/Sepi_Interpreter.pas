{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit Sepi_Interpreter;

interface

uses
  SepiDisassembler, SepiInCalls, SepiOpCodes, SepiRuntime, 
  SepiRuntimeOperations, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('Sepi_Interpreter', @Register);
end.
