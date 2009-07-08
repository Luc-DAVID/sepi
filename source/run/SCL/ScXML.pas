unit ScXML;

interface

uses
  SysUtils, Classes, msxml, ActiveX, ScConsts;

const
  /// Caract�res de la base 64
  Base64Chars: AnsiString =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  /// Caract�re sp�cial d'absence de donn�es en fin de base 64
  Base64NoDataChar: AnsiChar = '=';

procedure Base64Encode(Input, Output: TStream);
procedure Base64Decode(Input, Output: TStream);

function LoadXMLDocumentFromStream(Stream: TStream): IXMLDOMDocument;
procedure SaveXMLDocumentToStream(const Document: IXMLDOMDocument;
  Stream: TStream);

function LoadXMLDocumentFromFile(const FileName: TFileName): IXMLDOMDocument;
procedure SaveXMLDocumentToFile(const Document: IXMLDOMDocument;
  const FileName: TFileName);

implementation

var
  ByteToBase64: array[Byte] of Byte;
  Base64ToByte: array[Byte] of Byte;
  Base64NoDataByte: Byte;

procedure InitGlobalVars;
var
  I: Integer;
begin
  for I := 0 to 63 do
  begin
    ByteToBase64[I] := Ord(Base64Chars[I+1]);
    Base64ToByte[ByteToBase64[I]] := I;
  end;

  Base64NoDataByte := Ord(Base64NoDataChar);
end;

function Base64EncodeChunk(InChunk: LongWord; ChunkSize: Integer = 3): LongWord;
var
  InRec: LongRec absolute InChunk;
  OutRec: LongRec absolute Result;
  Temp: Byte;
  I: Integer;
begin
  Temp := InRec.Bytes[0];
  InRec.Bytes[0] := InRec.Bytes[2];
  InRec.Bytes[2] := Temp;

  for I := 0 to 3 do
  begin
    OutRec.Bytes[3-I] := ByteToBase64[InChunk and 63];
    InChunk := InChunk shr 6;
  end;

  for I := ChunkSize+1 to 3 do
    OutRec.Bytes[I] := Base64NoDataByte;
end;

function Base64DecodeChunk(InChunk: LongWord; out ChunkSize: Integer): LongWord;
var
  InRec: LongRec absolute InChunk;
  OutRec: LongRec absolute Result;
  Temp: Byte;
  I: Integer;
begin
  if InRec.Bytes[2] = Base64NoDataByte then
    ChunkSize := 1
  else if InRec.Bytes[3] = Base64NoDataByte then
    ChunkSize := 2
  else
    ChunkSize := 3;

  Result := 0;
  for I := 3 downto 0 do
  begin
    Result := Result shl 6;
    Result := Result or Base64ToByte[InRec.Bytes[3-I]];
  end;

  Temp := OutRec.Bytes[0];
  OutRec.Bytes[0] := OutRec.Bytes[2];
  OutRec.Bytes[2] := Temp;
end;

{*
  Encode un flux en base 64
  @param Input    Flux � encoder
  @param Output   En sortie : flux encod� en base 64
*}
procedure Base64Encode(Input, Output: TStream);
var
  ChunkSize: Integer;
  InChunk, OutChunk: LongWord;
begin
  while True do
  begin
    InChunk := 0;
    ChunkSize := Input.Read(InChunk, 3);
    if ChunkSize = 0 then
      Break;
    OutChunk := Base64EncodeChunk(InChunk, ChunkSize);
    Output.WriteBuffer(OutChunk, 4);
  end;
end;

{*
  D�code un flux en base 64
  @param Input    Flux � d�coder
  @param Output   En sortie : flux d�cod�
*}
procedure Base64Decode(Input, Output: TStream);
var
  ChunkSize: Integer;
  InChunk, OutChunk: LongWord;
begin
  while Input.Read(InChunk, 4) > 0 do
  begin
    OutChunk := Base64DecodeChunk(InChunk, ChunkSize);
    Output.WriteBuffer(OutChunk, ChunkSize);
  end;
end;

{*
  Charge un document XML depuis un flux
  @param Stream   Flux source
  @return Document XML charg�
*}
function LoadXMLDocumentFromStream(Stream: TStream): IXMLDOMDocument;
var
  StreamAdapter: IStream;
begin
  Result := CoDOMDocument.Create;
  Result.async := False;

  StreamAdapter := TStreamAdapter.Create(Stream);
  if not Result.load(StreamAdapter) then
    raise EInOutError.Create(SCantLoadXMLDocument);
end;

{*
  Enregistre un document XML dans un flux
  @param Document   Document XML � enregistrer
  @param Stream     Flux dans lequel enregistrer le document
*}
procedure SaveXMLDocumentToStream(const Document: IXMLDOMDocument;
  Stream: TStream);
const
  XMLHeader: AnsiString = '<?xml version="1.0" encoding="UTF-8"?>'#13#10;
var
  StreamAdapter: IStream;
begin
  Stream.WriteBuffer(XMLHeader[1], Length(XMLHeader));

  StreamAdapter := TStreamAdapter.Create(Stream);
  Document.save(StreamAdapter);
end;

{*
  Charge un document XML depuis un fichier
  @param FileName   Nom du fichier source
  @return Document XML charg�
*}
function LoadXMLDocumentFromFile(const FileName: TFileName): IXMLDOMDocument;
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmOpenRead);
  try
    Result := LoadXMLDocumentFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

{*
  Enregistre un document XML dans un fichier
  @param Document   Document XML � enregistrer
  @param FileName   Nom du fichier destination
*}
procedure SaveXMLDocumentToFile(const Document: IXMLDOMDocument;
  const FileName: TFileName);
var
  Stream: TStream;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveXMLDocumentToStream(Document, Stream);
  finally
    Stream.Free;
  end;
end;

initialization
  InitGlobalVars;
end.

