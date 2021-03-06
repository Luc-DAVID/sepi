unit Test;

interface

uses
  Types, SysUtils, Classes, ScTypInfo
  {$IF RTLVersion >= 21}, TimeSpan{$IFEND};

type
  TPrintOnAddStrings = class(TStringList)
  public
    constructor Create;

    function Add(const Str: string): Integer; override;
    procedure DynamicMethod; dynamic;

    class procedure ShowClassName;
  end;

implementation

constructor TPrintOnAddStrings.Create;
begin
  inherited Create;
end;

function TPrintOnAddStrings.Add(const Str: string): Integer;
begin
  inherited;
  WriteLn(Str);
end;

procedure TPrintOnAddStrings.DynamicMethod;
begin
  Add('DynamicMethod entered');
end;

class procedure TPrintOnAddStrings.ShowClassName;
begin
  WriteLn(ClassName);
end;

procedure Test(const Str: string; Strings: TStrings);
var
  Line: string;
begin
  Line := Format('%s %d', [Str, Random(5)]);
  Strings.Add(Line);
end;

type
  TShorterInt = 0..15;

var
  IsFirstTitle: Boolean = True;

procedure WriteTitle(const Title: string);
var
  Dashes: string;
  I: Integer;
begin
  if not IsFirstTitle then
    WriteLn('');

  WriteLn(Title);

  Dashes := '';
  for I := 0 to System.Length(Title)-1 do
    Dashes := Dashes + '-';
  WriteLn(Dashes);
  WriteLn('');

  IsFirstTitle := False;
end;

type
  TSomeSet = set of (ssOne, ssTwo, ssThree);

procedure TestSets;
const
  ShorterConst: TShorterInt = 5;
  EmptySet: TSysCharSet = [];
var
  C, D: AnsiChar;
  ShorterVar: TShorterInt;
  SomeSet: TSomeSet;
begin
  WriteTitle('Test set construction and operations');

  ShorterVar := 10;

  C := '0';
  Inc(C);
  D := 'D';
  WriteLn(CharSetToStr(SwitchChars + [C, 'A'..D] - ['B', 'Q'] * ['B'..'E'] +
    [Chr(ShorterConst)..Chr(ShorterVar)] + EmptySet + (['Z']-[])));
  WriteLn(CharSetToStr(['1', '9']));

  SomeSet := [ssOne];
  WriteLn(EnumSetToStr(SomeSet, TypeInfo(TSomeSet)));
  Include(SomeSet, ssTwo);
  WriteLn(EnumSetToStr(SomeSet, TypeInfo(TSomeSet)));
  Exclude(SomeSet, ssOne);
  WriteLn(EnumSetToStr(SomeSet, TypeInfo(TSomeSet)));
end;

procedure TestChangeGlobalVar;
begin
  WriteTitle('Test changing a global variable');

  DecimalSeparator := ',';
  WriteLn(FloatToStr(3.1416));
  DecimalSeparator := '.';
  WriteLn(FloatToStr(2.1416));
end;

procedure TestIfCompilerDirective;
begin
  WriteTitle('Test {$IF} compiler directive');

  {$IF RTLVersion > 15}
    WriteLn('RTLVersion > 15');
  {$IFEND}

  {$IF 3+5 = 6}
    WriteLn('3+5 = 6');
  {$IFEND}

  {$IF Declared(TestSets) and not Defined(SOMETHING)}
    WriteLn('Cool! This beast is working!');
  {$IFEND}

  {$IF Defined(MSWINDOWS)}
    WriteLn('Compiled for Windows');
  {$IFEND}
end;

procedure TestMethodRef;
type
  TStringEvent = function(const Str: string): Integer of object;
  TProc = procedure of object;
var
  Strings: TPrintOnAddStrings;
  Add: TStringEvent;
  DoSomething: TProc;
  I: Integer;
begin
  WriteTitle('Test method references');

  Strings := TPrintOnAddStrings.Create;
  {$IF RTLVersion >= 20}
  TMonitor.Enter(Strings);
  {$IFEND}
  try
    Strings.ShowClassName;

    Add := Strings.Add;

    for I := 1 to 3 do
      if @Add <> nil then
        Add(IntToStr(I));

    DoSomething := Strings.DynamicMethod;
    DoSomething();
  finally
    {$IF RTLVersion >= 20}
    TMonitor.Exit(Strings);
    {$IFEND}
    Strings.Free;
  end;
end;

procedure TestIsAs;
var
  Strings: TStrings;
begin
  WriteTitle('Test is and as operators');

  Strings := TStringList.Create;
  try
    if Strings is TStringList then
      WriteLn('Strings is TStringList')
    else
      WriteLn('Strings is not TStringList');

    (Strings as TStringList).CaseSensitive := True;

    if Strings is TList then
      WriteLn('Strings is TList')
    else
      WriteLn('Strings is not TList');

    try
      (Strings as TList).Add(nil);
    except
      on Error: EInvalidCast do
        WriteLn('Error when (Strings as TList): '+Error.Message);
    end;
  finally
    Strings.Free;
  end;
end;

procedure TestExceptionsAndClassDef;
var
  Strings: TStrings;
  I: Integer;
  Tab: array[0..10] of Integer;
begin
  WriteTitle('Test using a Sepi-defined class and raising exceptions');

  Strings := TPrintOnAddStrings.Create;
  try
    for I := Low(Tab) to High(Tab) do
      Tab[I] := I*I;

    for I := Low(Tab) to High(Tab) do
      Test(IntToStr(Tab[I]), Strings);

    try
      for I := Strings.Count-1 downto 0 do
      begin
        if I = 7 then
          Continue;

        WriteLn(Strings[I]);

        if I < 5 then
          Break;
      end;

      I := Random(3);
      if I = 0 then
        raise EAbort.Create('Exception now!')
      else if I = 1 then
        StrToInt('I am not an Integer!')
      else
        Exit;

      WriteLn('Will not appear');
    except
      on Error: EConvertError do
        WriteLn(Format('Hey, I catched a EConvertError: %s', [Error.Message]));
      {else
        WriteLn('Unknown exception: I reraise it');
        raise;}
    end;
  finally
    Strings.Free;
    WriteLn('Will appear anyway');
  end;
  
  WriteLn('Will appear only if that was a EConvertError, which was catched');
end;

procedure DisplayArray(const Values: array of Integer);
var
  Line: string;
  I: Integer;
begin
  WriteLn(Format('The array has %d elements', [Length(Values)]));

  Line := 'Values are:';
  for I := Low(Values) to High(Values) do
    Line := Line + ' ' + IntToStr(Values[I]);

  WriteLn(Line);
end;

procedure TestOpenArray;
const
  Items: array[1..8] of Integer = (2, 3, 5, 7, 11, 13, 17, 19);
begin
  WriteTitle('Test an open array parameter');

  DisplayArray(Items);
end;

procedure TestSetLengthAndCopy;
var
  I: Integer;
  IntArray, OtherArray: TIntegerDynArray;
  Str: string;
begin
  WriteTitle('Test SetLength and dynamic arrays');

  SetLength(IntArray, 5);
  for I := 0 to Length(IntArray)-1 do
    IntArray[I] := I*I;
  DisplayArray(IntArray);

  WriteLn('');
  OtherArray := IntArray;
  OtherArray[3] := 0;
  DisplayArray(IntArray);
  DisplayArray(OtherArray);

  WriteLn('');
  OtherArray := Copy(IntArray);
  OtherArray[3] := 1;
  DisplayArray(IntArray);
  DisplayArray(OtherArray);

  WriteLn('');
  OtherArray := Copy(IntArray, 1, 3);
  DisplayArray(OtherArray);

  WriteLn('');
  Str := 'Hello world!';
  WriteLn(Copy(Str, 7, MaxInt));
  SetLength(Str, 5);
  WriteLn(Str);

  WriteLn('');
  Str := 'Hello world!';
  Insert('all the ', Str, 7);
  WriteLn(Str);
  Delete(Str, 1, 6);
  WriteLn(Str);
end;

procedure TestStringChars;
var
  Str, Str2: string;
  I: Integer;
begin
  WriteTitle('Test selection of characters of a string');

  Str := 'Hello world!';
  WriteLn(Str);
  WriteLn('Str[1] = ' + Str[1]);

  Str2 := Str;
  Str[3] := '_';
  WriteLn(Str);
  WriteLn(Str2);

  for I := 1 to Length(Str) do
    Write(Str[I] + ', ');
  WriteLn('');
end;

procedure TestSomePseudoRoutines;
var
  I: Integer;
  P: PInteger;
begin
  WriteTitle('Test Inc and Dec');

  I := 1;
  WriteLn(IntToStr(I));
  Inc(I);
  WriteLn(IntToStr(I));

  Inc(I, 5);
  WriteLn(IntToStr(I));
  Dec(I);
  WriteLn(IntToStr(I));

  P := @I;
  WriteLn(IntToStr(P^));
  Inc(P);
  Inc(P, 2);
  Dec(P, 3);
  WriteLn(IntToStr(P^));
end;

{$IF RTLVersion >= 21}
procedure TestTimeSpan;
var
  Span: TTimeSpan;
begin
  WriteTitle('Test TimeSpan');

  Span.Create(1, 2, 3);
  WriteLn(IntToStr(Span.Minutes));
end;
{$IFEND}

{$IF CompilerVersion >= 20}
type
  TIntegerCallback = reference to procedure(Value: Integer);
  TIntegerMethod = procedure(Value: Integer) of object;
  TIntegerProc = procedure(Value: Integer);

  TComplicatedCallback = reference to procedure(S: Single;
    A, B, C, D, E: Integer);
  TComplicatedProc = procedure(S: Single; A, B, C, D, E: Integer);

  THelperClass = class
  public
    procedure DisplayValue(Value: Integer);
  end;

procedure THelperClass.DisplayValue(Value: Integer);
begin
  WriteLn(IntToStr(Value));
end;

procedure DisplayValue(Value: Integer);
begin
  WriteLn(IntToStr(Value));
end;

procedure Complicated(S: Single; A, B, C, D, E: Integer);
begin
  WriteLn(Format('%f %d %d %d %d %d', [S, A, B, C, D, E]));
end;

procedure OneToFive(const Callback: TIntegerCallback);
var
  OtherCallback: TIntegerCallback;
  I: Integer;
begin
  OtherCallback := Callback;

  for I := 1 to 5 do
    OtherCallback(I);
end;

procedure CallComplicated(const Callback: TComplicatedCallback);
begin
  Callback(Pi, 1, 2, 4, 8, 16);
end;

procedure TestRoutineReferences;
var
  Obj: THelperClass;
begin
  WriteTitle('Test routine reference');

  OneToFive(DisplayValue);
  WriteLn('');

  Obj := THelperClass.Create;
  try
    OneToFive(Obj.DisplayValue);
  finally
    Obj.Free;
  end;

  WriteLn('');
  CallComplicated(Complicated);
end;
{$IFEND}

procedure TestVariants;
var
  I: Integer;
  Str: string;
  V: Variant;
  Cur: Currency;
begin
  WriteTitle('Test Variant type');

  I := 5;
  V := I;
  V := V + 7;
  V := '5 + 7 = ' + string(V);
  WriteLn(V);

  Str := V;
  WriteLn(Str);

  Cur := 40.3399; // EUR to BEF conversion
  V := Cur;
  WriteLn(Format('1 � = %s BEF', [V]));
end;

type
  IIntfTest = interface(IInterface)
    ['{4E823C1B-7852-42FE-A0E0-8AA5CD6FA1F2}']
    procedure Display(Value: Integer);
  end;

  TIntfTestObject = class(TInterfacedObject, IIntfTest)
  protected
    procedure Display(Value: Integer);
  public
    constructor Create;
    destructor Destroy; override;
  end;

procedure TestInterfaces;
var
  Intf: IIntfTest;
begin
  WriteTitle('Test interfaces');

  Intf := TIntfTestObject.Create;

  Intf.Display(151189);
end;

procedure Main;
begin
  Randomize;

  TestSets;
  TestChangeGlobalVar;
  TestIfCompilerDirective;
  TestMethodRef;
  TestIsAs;
  TestOpenArray;
  TestSetLengthAndCopy;
  TestStringChars;
  TestSomePseudoRoutines;

{$IF RTLVersion >= 21}
  TestTimeSpan;
{$IFEND}

{$IF CompilerVersion >= 20}
  TestRoutineReferences;
{$IFEND}

  TestVariants;
  TestInterfaces;
  TestExceptionsAndClassDef;
end;

{ TIntfTestObject }

constructor TIntfTestObject.Create;
begin
  inherited;

  WriteLn(ClassName + ' created');
end;

destructor TIntfTestObject.Destroy;
begin
  WriteLn(ClassName + ' destroyed');

  inherited;
end;

procedure TIntfTestObject.Display(Value: Integer);
begin
  WriteLn('Display: '+IntToStr(Value));
end;

end.

