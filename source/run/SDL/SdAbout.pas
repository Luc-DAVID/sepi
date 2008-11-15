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
  Bo�te de dialogue � propos
  @author sjrd
  @version 1.0
*}
unit SdAbout;

interface

uses
{$IFDEF MSWINDOWS}
  Forms, Graphics, StdCtrls, ExtCtrls, Controls,
{$ENDIF}
{$IFDEF LINUX}
  QForms, QGraphics, QStdCtrls, QExtCtrls, QControls,
{$ENDIF}
  ScStrUtils, SvLabels, Classes;

type
  {*
    Bo�te de dialogue � propos
    @author sjrd
    @version 1.0
  *}
  TSdAboutForm = class(TForm)
    ImageProgramIcon: TImage;    /// Image pour l'ic�ne
    LabelProgramName: TLabel;    /// Label pour le nom du programme
    LabelProgramVersion: TLabel; /// Label pour la version
    LabelAuthor: TLabel;         /// Label pour l'auteur
    ButtonOK: TButton;           /// Bouton OK
    procedure FormCreate(Sender: TObject);
  private
    { D�clarations priv�es }
  public
    { Composants non disponibles dans Turbo Explorer }
    URLLabelEMail: TSvURLLabel;   /// Label pour l'e-mail de l'auteur
    URLLabelWebSite: TSvURLLabel; /// Label pour le site Web

    { D�clarations publiques }
    class procedure ShowAbout(Title: string; ProgramIcon: TGraphic;
      ProgramName: string; ProgramVersion: string; Author: string;
      AuthorEMail: string = ''; WebSite: string = '');
  end;

implementation

{$R *.dfm}

{---------------------}
{ Classe TSdAboutForm }
{---------------------}

{*
  Gestionnaire d'�v�nement OnCreate
  @param Sender   Objet qui a d�clench� l'�v�nement
*}
procedure TSdAboutForm.FormCreate(Sender: TObject);
begin
  // Cr�ation des composants non disponibles dans Turbo Explorer

  URLLabelEMail := TSvURLLabel.Create(Self);
  with URLLabelEMail do
  begin
    Name := 'URLLabelEMail'; {don't localize}
    Parent := Self;
    Left := 16;
    Top := 112;
  end;

  URLLabelWebSite := TSvURLLabel.Create(Self);
  with URLLabelWebSite do
  begin
    Name := 'URLLabelWebSite'; {don't localize}
    Parent := Self;
    Left := 16;
    Top := 136;
  end;
end;

{*
  Affiche une bo�te de dialogue � propos
  @param Title            Titre de la bo�te de dialogue
  @param ProgramIcon      Ic�ne du programme
  @param ProgramName      Nom du programme
  @param ProgramVersion   Version du programme
  @param Author           Auteur du programme
  @param AuthorEMail      Adresse e-mail de l'auteur (optionnel)
  @param WebSite          Site Web du programme (optionnel)
*}
class procedure TSdAboutForm.ShowAbout(Title: string; ProgramIcon: TGraphic;
  ProgramName: string; ProgramVersion: string; Author: string;
  AuthorEMail: string; WebSite: string);
begin
  with Create(nil) do
    try
      Caption := Title;
      ImageProgramIcon.Picture.Assign(ProgramIcon);
      LabelProgramName.Caption := ProgramName;
      LabelProgramVersion.Caption := ProgramVersion;
      LabelAuthor.Caption := Author;
      if AuthorEMail = '' then
        URLLabelEMail.Visible := False
      else
      begin
        URLLabelEMail.Caption := GetFirstToken(AuthorEMail, '?');
        {don't localize}
        URLLabelEMail.URL := 'mailto:'+AuthorEMail; {don't localize}
      end;
      if WebSite = '' then
        URLLabelWebSite.Visible := False
      else
        URLLabelWebSite.Caption := WebSite;
      ShowModal;
    finally
      Free;
    end;
end;

end.

