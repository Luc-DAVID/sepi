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
  D�finit le composant � � propos � de Sepi
  @author sjrd
  @version 1.0
*}
unit SepiAbout;

interface

uses
  Classes, SysUtils, SepiCore, SepiConsts, SdDialogs;

type
  {*
    Bo�te de dialogue � � propos � de Sepi
    @author sjrd
    @version 1.0
  *}
  TSepiAboutDialog = class(TComponent)
  private
    FDialog: TSdAboutDialog; /// Bo�te de dialogue g�n�rique
  public
    constructor Create(AOwner: TComponent); override;

    procedure Execute;
  end;

implementation

{*
  Cr�e une instance de TSepiAboutDialog
  @param AOwner   Propri�taire
*}
constructor TSepiAboutDialog.Create(AOwner: TComponent);
begin
  inherited;
  FDialog := TSdAboutDialog.Create(Self);
  FDialog.Title := sSepiAbout;
  try
    FDialog.ProgramIcon.LoadFromFile(Sepi.Path+'Sepi.ico'); {don't localize}
  except
  end;
  FDialog.ProgramName := Sepi.Name;
  FDialog.ProgramVersion := Format('%d.%d', {don't localize}
    [Sepi.Version.MajVersion, Sepi.Version.MinVersion]);
  FDialog.AuthorName := Sepi.Author;
  FDialog.AuthorEMail := Sepi.AuthorEMail;
  FDialog.WebSite := Sepi.WebSite;
end;

{*
  Affiche la bo�te de dialogue
*}
procedure TSepiAboutDialog.Execute;
begin
  FDialog.Execute;
end;

end.

