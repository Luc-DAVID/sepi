{-------------------------------------------------------------------------------
Sepi - Object-oriented script engine for Delphi
Copyright (C) 2006-2007  S�bastien Doeraene
All Rights Reserved

This file is part of Sepi.

Sepi is free software: you can redistribute it and/or modify it under the terms
of the GNU General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version.

Sepi is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
Sepi.  If not, see <http://www.gnu.org/licenses/>.
-------------------------------------------------------------------------------}

{*
  Propose une s�rie d'alias aux routines cach�es de System
  Ces routines sont celles connues sous le nom de "compiler magic".
  @author sjrd
  @version 1.0
*}
unit ScCompilerMagic;

interface

uses
  TypInfo;

procedure AbstractError;

procedure Initialize(var Value; TypeInfo: PTypeInfo; Count: Cardinal = 1);
procedure Finalize(var Value; TypeInfo: PTypeInfo; Count: Cardinal = 1);

procedure CopyArray(Dest, Source, TypeInfo: Pointer; Count: Integer);
procedure CopyRecord(Dest, Source, TypeInfo: Pointer);
procedure DynArrayCopy(Source: Pointer; TypeInfo: Pointer;
  var Dest: Pointer);
procedure DynArrayCopyRange(Source: Pointer; TypeInfo: Pointer;
  Index, Count: Integer; var Dest: Pointer);

function CompilerMagicRoutineAddress(
  CompilerMagicRoutineAlias: Pointer): Pointer;

implementation

{*
  D�clenche une erreur abstraite - alias de @AbstractError
*}
procedure AbstractError;
asm
        JMP     System.@AbstractError
end;

{*
  Initialise une variable - alias de @InitializeArray
  @param Value      Variable � initialiser
  @param TypeInfo   RTTI du type de la variable
  @param Count      Nombre d'�l�ments dans la variable
*}
procedure Initialize(var Value; TypeInfo: PTypeInfo; Count: Cardinal = 1);
asm
        JMP     System.@InitializeArray
end;

{*
  Finalise une variable - alias de @FinalizeArray
  @param Value      Variable � finaliser
  @param TypeInfo   RTTI du type de la variable
  @param Count      Nombre d'�l�ments dans la variable
*}
procedure Finalize(var Value; TypeInfo: PTypeInfo; Count: Cardinal = 1);
asm
        JMP     System.@FinalizeArray
end;

{*
  Copie un tableau statique - alias de @CopyArray
  @param Dest       Pointeur sur le tableau destination
  @param Source     Pointeur sur le tableau source
  @param TypeInfo   RTTI du type des �l�ments du tableau
  @param Count      Nombre d'�l�ments dans le tableau
*}
procedure CopyArray(Dest, Source, TypeInfo: Pointer; Count: Integer);
asm
        JMP     System.@CopyArray
end;

{*
  Copie un record - alias de @CopyRecord
  @param Dest       Pointeur sur le record destination
  @param Source     Pointeur sur le record source
  @param TypeInfo   RTTI du type record
*}
procedure CopyRecord(Dest, Source, TypeInfo: Pointer);
asm
        JMP     System.@CopyRecord
end;

{*
  Copie un tableau dynamique - alias de @DynArrayCopy
  @param Source     Tableau source sous forme de pointeur
  @param TypeInfo   RTTI du type tableau dynamique
  @param Dest       Tableau destination sous forme de pointeur
*}
procedure DynArrayCopy(Source: Pointer; TypeInfo: Pointer;
  var Dest: Pointer);
asm
        JMP     System.@DynArrayCopy
end;

{*
  Copie une partie d'un tableau dynamique - alias de @DynArrayCopyRange
  @param Source     Tableau source sous forme de pointeur
  @param TypeInfo   RTTI du type tableau dynamique
  @param Index      Index du premier �l�ment � copier
  @param Count      Nombre d'�l�ments � copier
  @param Dest       Tableau destination sous forme de pointeur
*}
procedure DynArrayCopyRange(Source: Pointer; TypeInfo: Pointer;
  Index, Count: Integer; var Dest: Pointer);
asm
        JMP     System.@DynArrayCopyRange
end;

{*
  D�termine l'adresse r�elle d'une routine de "compiler magic"
  Cette routine n'est valide qu'avec les alias de l'unit� ScCompilerMagic, ou �
  d�faut avec d'autres alias se contentant d'un JMP sur la v�ritable routine.
  @param CompilerMagicRoutineAlias   Pointeur sur le code d'un alias de routine
  @return Pointeur sur le code de la routine r�elle
*}
function CompilerMagicRoutineAddress(
  CompilerMagicRoutineAlias: Pointer): Pointer;
begin
  // Handle an optional module redirector
  if PWord(CompilerMagicRoutineAlias)^ = $25FF then // JMP dword ptr [] op code
  begin
    Inc(Integer(CompilerMagicRoutineAlias), 2);
    CompilerMagicRoutineAlias := PPointer(CompilerMagicRoutineAlias)^;
    CompilerMagicRoutineAlias := PPointer(CompilerMagicRoutineAlias)^;
  end;

  // Handle the actual alias
  Assert(PByte(CompilerMagicRoutineAlias)^ = $E9); // JMP op code
  Inc(Integer(CompilerMagicRoutineAlias));
  Result := Pointer(Integer(CompilerMagicRoutineAlias) +
    PInteger(CompilerMagicRoutineAlias)^ + 4);
end;

end.

