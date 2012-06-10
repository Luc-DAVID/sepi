{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit Sepi_Compiler;

interface

uses
  SepiCompilerConsts, SepiCompilerErrors, SepiCompilerUtils, 
  SepiDelphiLikeCompilerUtils, SepiExpressions, SepiInstructions, 
  SepiLexerUtils, SepiLL1ParserUtils, SepiParserUtils, SepiParseTrees, 
  SepiStdCompilerNodes, SepiAsmInstructions, SepiCompiler, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('Sepi_Compiler', @Register);
end.
