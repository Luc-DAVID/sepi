{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit SepiCompilerLaz;

interface

uses
  SepiAsmInstructions, SepiCompiler, SepiCompilerConsts, SepiCompilerErrors, 
  SepiCompilerUtils, SepiDelphiLikeCompilerUtils, SepiExpressions, 
  SepiInstructions, SepiLexerUtils, SepiLL1ParserUtils, SepiParserUtils, 
  SepiParseTrees, SepiStdCompilerNodes, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('SepiCompilerLaz', @Register);
end.
