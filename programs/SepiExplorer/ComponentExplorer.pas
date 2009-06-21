{-------------------------------------------------------------------------------
SepiExplorer - Example program for Sepi
As an example program, SepiExplorer is free of any usage. It is released in the
public domain.
-------------------------------------------------------------------------------}

{*
  Cadre montrant les informations d'un meta
  @author sjrd
  @version 1.0
*}
unit ComponentExplorer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, 
  Dialogs, StdCtrls, SepiReflectionCore, SepiMembers, SepiRuntime,
  SepiDisassembler, TypesInfo, MembersInfo;

type
  TGetRuntimeMethodEvent = function(
    SepiMethod: TSepiMethod): TSepiRuntimeMethod of object;

  {*
    Cadre montrant les informations d'un meta
    @author sjrd
    @version 1.0
  *}
  TFrameComponentExplorer = class(TFrame)
    MemoInfo: TMemo;
  private
    /// �v�nement d�clench� pour demander la m�thode run-time d'une m�thode Sepi
    FOnGetRuntimeMethod: TGetRuntimeMethodEvent;

    FSepiComponent: TSepiComponent; /// Le meta affich�

    procedure PrintMethodCode(Strings: TStrings; SepiMethod: TSepiMethod);

    procedure SetSepiComponent(Value: TSepiComponent);
  public
    property OnGetRuntimeMethod: TGetRuntimeMethodEvent
      read FOnGetRuntimeMethod write FOnGetRuntimeMethod;

    property SepiComponent: TSepiComponent read FSepiComponent write SetSepiComponent;
  end;

implementation

{$R *.dfm}

{--------------------------}
{ TFrameComponentExplorer class }
{--------------------------}

{*
  Affiche le code d'une m�thode, quand c'est possible
  @param Strings      Liste de cha�nes destination
  @param SepiMethod   M�thode dont afficher le code
*}
procedure TFrameComponentExplorer.PrintMethodCode(Strings: TStrings;
  SepiMethod: TSepiMethod);
var
  Method: TSepiRuntimeMethod;
  Disassembled: TStrings;
  Disassembler: TSepiDisassembler;
  I: Integer;
begin
  // Find run-time method
  if not Assigned(FOnGetRuntimeMethod) then
    Exit;
  Method := FOnGetRuntimeMethod(SepiMethod);
  if Method = nil then
    Exit;

  // Print code
  Strings.Add('');
  Strings.Add(Format('Locals size: %d', [Method.LocalsSize]));
  Strings.Add(Format('Params size: %d', [Method.ParamsSize]));
  Strings.Add('');

  if Method.CodeSize > 0 then
  begin
    Disassembler := nil;
    Disassembled := TStringList.Create;
    try
      Disassembler := TSepiDisassembler.Create;

      Disassembler.Disassemble(Method.Code, Disassembled, Method.RuntimeUnit,
        Method.CodeSize, 0);

      for I := 0 to Disassembled.Count-1 do
      begin
        Strings.Add(IntToHex(Cardinal(Disassembled.Objects[I]), 8) + '  ' +
          Disassembled[I]);
      end;
    finally
      Disassembler.Free;
      Disassembled.Free;
    end;
  end;
end;

{*
  Modifie le meta affich�
  @param Value   Nouveau meta � afficher
*}
procedure TFrameComponentExplorer.SetSepiComponent(Value: TSepiComponent);
var
  Output: TOutputWriter;
begin
  FSepiComponent := Value;

  MemoInfo.Lines.BeginUpdate;
  try
    MemoInfo.Lines.Clear;

    if SepiComponent <> nil then
    begin
      Output := TOutputWriter.Create(MemoInfo.Lines);
      try
        PrintComponentInfo(Output, SepiComponent);
      finally
        Output.Free;
      end;

      if SepiComponent is TSepiMethod then
        PrintMethodCode(MemoInfo.Lines, TSepiMethod(SepiComponent));
    end;
  finally
    MemoInfo.Lines.EndUpdate;
  end;
end;

end.

