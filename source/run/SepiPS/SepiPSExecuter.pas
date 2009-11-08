{-------------------------------------------------------------------------------
Sepi - Object-oriented script engine for Delphi
Copyright (C) 2006-2009  S�bastien Doeraene
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

Linking this library statically or dynamically with other modules is making a
combined work based on this library.  Thus, the terms and conditions of the GNU
General Public License cover the whole combination.

As a special exception, the copyright holders of this library give you
permission to link this library with independent modules to produce an
executable, regardless of the license terms of these independent modules, and
to copy and distribute the resulting executable under terms of your choice,
provided that you also meet, for each linked independent module, the terms and
conditions of the license of that module.  An independent module is a module
which is not derived from or based on this library.  If you modify this
library, you may extend this exception to your version of the library, but you
are not obligated to do so.  If you do not wish to do so, delete this exception
statement from your version.
-------------------------------------------------------------------------------}

{*
  Ex�cuteur d'unit� Sepi-PS
  @author sjrd
  @version 1.0
*}
unit SepiPSExecuter;

interface

procedure SepiPSExecute(const UnitName: string);

implementation

uses
  SepiReflectionCore, SepiMembers, SepiPSLoader;

{*
  Ex�cute un script Sepi-PS
  @param UnitName   Nom de l'unit� � charger pour ex�cution
*}
procedure SepiPSExecute(const UnitName: string);
var
  Root: TSepiRoot;
  Method: TMethod;
  SepiUnit: TSepiUnit;
  SepiMainProc: TSepiMethod;
  MainProc: procedure;
begin
  Root := TSepiRoot.Create;
  try
    Method.Code := @SepiPSLoadUnit;
    Method.Data := nil;
    Root.OnLoadUnit := TSepiLoadUnitEvent(Method);

    SepiUnit := Root.LoadUnit(UnitName);
    SepiMainProc := SepiUnit.GetComponent('$MAIN') as TSepiMethod;

    if SepiMainProc = nil then
      WriteLn('There is no main proc in this unit')
    else
    begin
      @MainProc := SepiMainProc.Code;
      MainProc;
    end;
  finally
    Root.Free;
  end;
end;

end.

