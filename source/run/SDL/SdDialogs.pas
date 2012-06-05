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
  D�finit des routines et composants utilisant des bo�tes de dialogue
  @author sjrd
  @version 1.0
*}
unit SdDialogs;

interface

uses
  Classes, Dialogs, Controls, Graphics
  {$IFDEF FPC}
  , InterfaceBase, Forms
  {$ENDIF}
  ;

{$IFDEF LINUX}
const
  dtCustom = mtCustom;
  dtInformation = mtInformation;
  dtWarning = mtWarning;
  dtError = mtError;
  dtConfirmation = mtConfirmation;

  dbOK = [mbOK];
  dbOKCancel = mbOKCancel;
  dbYesNo = [mbYes, mbNo];
  dbYesNoCancel = mbYesNoCancel;
  dbRetryCancel = [mbRetry, mbCancel];
  dbAbortRetryIgnore = mbAbortRetryIgnore;

  drOK = mrOk;
  drYes = mrYes;
  drNo = mrNo;
  drCancel = mrCancel;
  drAbort = mrAbort;
  drRetry = mrRetry;
  drIgnore = mrIgnore;
{$ENDIF}

type
  {*
    Type d'une bo�te de dialogue
    dtCustom       : Type g�n�rique
    dtInformation  : Information
    dtWarning      : Avertissement
    dtError        : Erreur
    dtConfirmation : Confirmation
  *}
  {$IFDEF MSWINDOWS}
  TDialogType = (dtCustom, dtInformation, dtWarning, dtError,
    dtConfirmation);
  {$ELSE}
  TDialogType = type TMsgDlgType;
  {$ENDIF}

  {*
    Boutons pr�sents dans une bo�te de dialogue
    dbOK               : OK
    dbOKCancel         : OK et Annuler
    dbYesNo            : Oui et Non
    dbYesNoCancel      : Oui, Non et Annuler
    dbRetryCancel      : R�essayer et Annuler
    dbAbortRetryIgnore : Abandonner, R�essayer et Ignorer
  *}
  {$IFDEF MSWINDOWS}
  TDialogButtons = (dbOK, dbOKCancel, dbYesNo, dbYesNoCancel, dbRetryCancel,
    dbAbortRetryIgnore);
  {$ELSE}
  TDialogButtons = type TMsgDlgButtons;
  {$ENDIF}

  {*
    R�sultat de l'affichage d'une bo�te de dialogue
    drOK     : OK
    drYes    : Oui
    drNo     : Non
    drCancel : Annuler
    drAbort  : Abandonner
    drRetry  : R�essayer
    drIgnore : Ignorer
  *}
  {$IFDEF MSWINDOWS}
  TDialogResult = (drOK, drYes, drNo, drCancel, drAbort, drRetry, drIgnore);
  {$ELSE}
  TDialogResult = type Word;
  {$ENDIF}

  {*
    G�re une bo�te de dialogue d'introduction de mot de passe
    @author sjrd
    @version 1.0
  *}
  TSdPasswordDialog = class(TComponent)
  private
    FPassword: string;      /// Mot de passe correct
    FShowErrorMes: Boolean; /// Indique s'il faut notifier sur erreur
  public
    constructor Create(AOwner: TComponent); override;

    function Execute: Boolean; overload;
    function Execute(Password: string;
      ShowErrorMes: Boolean = True): Boolean; overload;
    function Execute(ShowErrorMes: Boolean): Boolean; overload;
  published
    property Password: string read FPassword write FPassword;
    property ShowErrorMes: Boolean read FShowErrorMes write FShowErrorMes
      default True;
  end;

  {*
    G�re une bo�te de dialogue � propos
    @author sjrd
    @version 1.0
  *}
  TSdAboutDialog = class(TComponent)
  private
    FTitle: string;          /// Titre de la bo�te de dialogue
    FProgramIcon: TIcon;     /// Ic�ne du programme
    FProgramName: string;    /// Nom du programme
    FVersion: string;        /// Intitul� de version
    FProgramVersion: string; /// Version du programme
    FAuthor: string;         /// Intitul� d'auteur
    FAuthorName: string;     /// Nom de l'auteur du programme
    FAuthorEMail: string;    /// Adresse e-mail de l'auteur (optionnel)
    FWebSite: string;        /// Site Web du programme (optionnel)

    procedure SetProgramIcon(New: TIcon);

    function IsTitleStored: Boolean;
    function IsVersionStored: Boolean;
    function IsProgramVersionStored: Boolean;
    function IsAuthorStored: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Execute;
  published
    property Title: string read FTitle write FTitle stored IsTitleStored;
    property ProgramIcon: TIcon read FProgramIcon write SetProgramIcon;
    property ProgramName: string read FProgramName write FProgramName;
    property Version: string read FVersion write FVersion
      stored IsVersionStored;
    property ProgramVersion: string read FProgramVersion write FProgramVersion
      stored IsProgramVersionStored;
    property Author: string read FAuthor write FAuthor stored IsAuthorStored;
    property AuthorName: string read FAuthorName write FAuthorName;
    property AuthorEMail: string read FAuthorEMail write FAuthorEMail;
    property WebSite: string read FWebSite write FWebSite;
  end platform;

  {*
    G�re une bo�te de dialogue demandant un nombre � l'utilisateur
    @author sjrd
    @version 1.0
  *}
  TSdNumberDialog = class(TComponent)
  private
    FTitle: string;  /// Titre de la bo�te de dialogue
    FPrompt: string; /// Invite de la bo�te de dialogue
    FValue: Integer; /// Valeur par d�faut, puis celle saisie par l'utilisateur
    FMin: Integer;   /// Valeur minimale que peut choisir l'utilisateur
    FMax: Integer;   /// Valeur maximale que peut choisir l'utilisateur
  public
    constructor Create(AOwner: TComponent); override;

    function Execute(const ATitle, APrompt: string;
      ADefault, AMin, AMax: Integer): Integer; overload;
    function Execute(ADefault, AMin, AMax: Integer): Integer; overload;
    function Execute(const ATitle, APrompt: string;
      AMin, AMax: Integer): Integer; overload;
    function Execute(AMin, AMax: Integer): Integer; overload;
    function Execute: Integer; overload;
  published
    property Title: string read FTitle write FTitle;
    property Prompt: string read FPrompt write FPrompt;
    property Value: Integer read FValue write FValue;
    property Min: Integer read FMin write FMin;
    property Max: Integer read FMax write FMax;
  end;

{$IFDEF MSWINDOWS}
function ShowMes(const Title, Text: string;
  Flags: LongWord): Integer; platform;
{$ENDIF}

function ShowDialog(const Title, Text: string;
  DlgType: TDialogType = dtInformation; DlgButtons: TDialogButtons = dbOK;
  DefButton: Byte = 1; AddFlags: LongWord = 0): TDialogResult;

function ShowDialogRadio(const Title, Text: string; DlgType: TMsgDlgType;
  DlgButtons: TMsgDlgButtons; DefButton: TModalResult;
  const RadioTitles: array of string; var Selected: Integer;
  OverButtons: Boolean = False): Word;

function QueryPassword: string; overload;

function QueryPassWord(Password: string;
  ShowErrorMes: Boolean = True): Boolean; overload;

procedure ShowAbout(Title: string; ProgramIcon: TIcon; ProgramName: string;
  ProgramVersion: string; Author: string; AuthorEMail: string = '';
  WebSite: string = ''); platform;

function QueryNumber(const Title, Prompt: string;
  Default, Min, Max: Integer): Integer;

implementation

uses
  Windows,{ Forms,} StdCtrls, Math, SdPassword, SdAbout, SdNumber, ScConsts;

{-------------------}
{ Routines globales }
{-------------------}

{$IFDEF MSWINDOWS}
{*
  Affiche une bo�te de dialogue modale Windows
  @param Title   Titre de la bo�te de dialogue
  @param Text    Texte de la bo�te de dialogue
  @param Flags   Flags contr�lant le style de bo�te de dialogue
  @return Code de r�sultat du bouton sur lequel a cliqu� l'utilisateur
*}
function ShowMes(const Title, Text: string; Flags: LongWord): Integer;
var
  AText, ATitle: PChar;
  AFlags: LongWord;
begin
  AText := PChar(Text);
  ATitle := PChar(Title);
  AFlags := Flags or MB_APPLMODAL; // Ajout du style Modal
  {$IFDEF FPC}
  Result := MessageBox(WidgetSet.AppHandle, AText, ATitle, AFlags);
  {$ELSE}
  Result := MessageBox(Application.Handle, AText, ATitle, AFlags);
  {$ENDIF}
end;
{$ENDIF}

{*
  Affiche une bo�te de dialogue modale Windows ou QT (selon la VCL utilis�e)
  @param Title        Titre de la bo�te de dialogue
  @param Text         Texte de la bo�te de dialogue
  @param DlgType      Type de bo�te de dialogue
  @param DlgButtons   Boutons � placer dans la bo�te de dialogue
  @param DefButton    Num�ro du bouton s�lectionn� par d�faut (� partir de 1)
  @param AddFlags     Flags additionnels contr�lant de style de bo�te (Win32)
  @return Bouton sur lequel a cliqu� l'utilisateur
*}

{$IFDEF MSWINDOWS}
function ShowDialog(const Title, Text: string;
  DlgType: TDialogType = dtInformation; DlgButtons: TDialogButtons = dbOK;
  DefButton: Byte = 1; AddFlags: LongWord = 0): TDialogResult;
var
  TypeFlags, BtnsFlags, DefBtnFlags, Flags: LongWord;
begin
  // Transformation du param�tre DlgType en flag de type
  case DlgType of
    dtCustom: TypeFlags := 0;
    dtInformation: TypeFlags := MB_ICONINFORMATION;
    dtWarning: TypeFlags := MB_ICONEXCLAMATION;
    dtError: TypeFlags := MB_ICONERROR;
    dtConfirmation: TypeFlags := MB_ICONQUESTION;
  else
    TypeFlags := 0;
  end;

  // Transformation du param�tre DlgButtons en flag de boutons
  case DlgButtons of
    dbOK: BtnsFlags := MB_OK;
    dbOKCancel: BtnsFlags := MB_OKCANCEL;
    dbYesNo: BtnsFlags := MB_YESNO;
    dbYesNoCancel: BtnsFlags := MB_YESNOCANCEL;
    dbRetryCancel: BtnsFlags := MB_RETRYCANCEL;
    dbAbortRetryIgnore: BtnsFlags := MB_AbortRetryIgnore;
  else
    BtnsFlags := MB_OK;
  end;

  // Transformation du param�tre DefButton en flag de bouton par d�faut
  case DefButton of
    1: DefBtnFlags := MB_DEFBUTTON1;
    2: DefBtnFlags := MB_DEFBUTTON2;
    3: DefBtnFlags := MB_DEFBUTTON3;
  else
    DefBtnFlags := 0;
  end;

  // Appel de ShowMes et transformation du retour Word en TDialogResult
  Flags := TypeFlags or BtnsFlags or DefBtnFlags or AddFlags;
  case ShowMes(Title, Text, Flags) of
    idOk: Result := drOK;
    idYes: Result := drYes;
    idNo: Result := drNo;
    idCancel: Result := drCancel;
    idAbort: Result := drAbort;
    idRetry: Result := drRetry;
    idIgnore: Result := drIgnore;
  else
    Result := drCancel;
  end;
end;
{$ENDIF}

{$IFDEF LINUX}
function ShowDialog(const Title, Text: string;
  DlgType: TDialogType = dtInformation; DlgButtons: TDialogButtons = dbOK;
  DefButton: Byte = 1; AddFlags: LongWord = 0): TDialogResult;
var
  NbBtns: Integer;
  MsgDefButton: TMsgDlgBtn;
begin
  // D�termination du nombre de boutons
  case DlgButtons of
    dbOK: NbBtns := 1;
    dbOKCancel: NbBtns := 2;
    dbYesNo: NbBtns := 2;
    dbYesNoCancel: NbBtns := 3;
    dbRetryCancel: NbBtns := 2;
    dbAbortRetryIgnore: NbBtns := 3;
  else
    NbBtns := 1;
  end;

  MsgDefButton := mbNone;
  if (DefButton < 1) or (DefButton > NbBtns) then
    DefButton := 1;

  // D�termination du bouton par d�faut
  case DefButton of
    1:
    begin
      if DlgButtons = [dbOK, dbOKCancel] then
        MsgDefButton := mbOK
      else if DlgButtons = [dbYesNo, dbYesNoCancel] then
        MsgDefButton := mbYes
      else if DlgButtons = dbRetryCancel then
        MsgDefButton := mbRetry
      else if DlgButtons = dbAbortRetryIgnore then
        MsgDefButton := mbAbort;
    end;
    2:
    begin
      if DlgButtons = [dbOKCancel, dbRetryCancel] then
        MsgDefButton := mbCancel
      else if DlgButtons = [dbYesNo, dbYesNoCancel] then
        MsgDefButton := mbNo
      else if DlgButtons = dbAbortRetryIgnore then
        MsgDefButton := mbRetry;
    end;
    3:
    begin
      if DlgButtons = dbYesNoCancel then
        MsgDefButton := mbCancel
      else if DlgButtons = dbAbortRetryIgnore then
        MsgDefButton := mbIgnore;
    end;
  end;

  // Appel de MessageDlg et renvoi de la valeur renvoy�e par celle-ci
  Result := MessageDlg(Title, Text, DlgType, DlgButtons, 0, MsgDefBtn);
end;
{$ENDIF}

{*
  Affiche une bo�te de dialogue avec des boutons radio
  ShowDialogRadio est une variante de ShowDialog qui affiche des boutons radio
  pour chaque choix possible.
  @param Title         Titre de la bo�te de dialogue
  @param Text          Texte de la bo�te de dialogue
  @param DlgType       Type de bo�te de dialogue
  @param DlgButtons    Boutons pr�sents dans la bo�te de dialogue
  @param DefButton     Bouton s�lectionn� par d�faut
  @param RadioTitles   Libell�s des diff�rents boutons radio
  @param Selected      Bouton radio s�lectionn�
  @param OverButtons   Boutons radio plac�s au-dessus des boutons si True
  @return Bouton sur lequel a cliqu� l'utilisateur
*}
function ShowDialogRadio(const Title, Text: string; DlgType: TMsgDlgType;
  DlgButtons: TMsgDlgButtons; DefButton: TModalResult;
  const RadioTitles: array of string; var Selected: Integer;
  OverButtons: Boolean = False): Word;
var
  Form: TForm;
  I, MaxWidth, OldWidth: Integer;
  Button: TButton;
begin
  // Cr�ation de la bo�te de dialogue
  Form := CreateMessageDialog(Text, DlgType, DlgButtons);

  with Form do
    try
      Caption := Title;
      // On augmente la taille de la bo�te de dialogue
      Height := Height + Length(RadioTitles) * 25;

      // Cr�ation des boutons radio et d�termination de la largeur minimale
      MaxWidth := 0;
      for I := High(RadioTitles) downto Low(RadioTitles) do
        with TRadioButton.Create(Form) do
        begin
          FreeNotification(Form);
          Parent := Form;
          Width := Canvas.TextWidth(RadioTitles[I]) + 20;
          MaxWidth := Max(MaxWidth, Width-20);
          Caption := RadioTitles[I];
          Checked := I = Selected;
          Tag := I;
          Left := 8;

          // OverButtons indique si les RadioBox sont au-dessus ou en-dessous des
          // boutons
          if OverButtons then
            Top := Form.Height - 90 - (High(RadioTitles) - I) * 25
          else
            Top := Form.Height - 50 - (High(RadioTitles) - I) * 25;
        end;

      // Il faut aussi v�rifier que la fiche peut afficher les textes des RadioBox
      // en entier
      OldWidth := 0;
      if (MaxWidth + 40) > Width then
      begin
        OldWidth := Width;
        Width := MaxWidth +40;
      end;

      for I := 0 to ComponentCount-1 do
      begin
        // On r�cup�re chaque bouton
        if Components[I] is TButton then
        begin
          Button := TButton(Components[I]);

          // On met le bon bouton par d�faut et on le s�lectionne
          Button.Default := Button.ModalResult = DefButton;
          if Button.Default then
            ActiveControl := Button;

          // S'il le faut, d�caler tous les boutons vers le bas
          if OverButtons then
            Button.Top := Button.Top + Length(RadioTitles) * 25;

          // S'il le faut, d�caler tous les boutons vers la droite
          if OldWidth > 0 then
            Button.Left := Button.Left + (Width - OldWidth) div 2;
        end;
      end;

      // On centre la bo�te de dialogue
      Position := poScreenCenter;

      // Affichage de la bo�te de dialogue
      Result := ShowModal;

      // R�cup�ration du choix de l'utilisateur
      Selected := -1;
      for I := 0 to ControlCount-1 do
      begin
        if (Controls[I] is TRadioButton) and
          TRadioButton(Controls[I]).Checked then
          Selected := Controls[I].Tag;
      end;
    finally
      Free;
    end;
end;

{*
  Demande un mot de passe � l'utilisateur
  @return Le mot de passe qu'a saisi l'utilisateur
*}
function QueryPassword: string;
begin
  Result := TSdPasswordForm.QueryPassword;
end;

{*
  Demande un mot de passe � l'utilisateur
  @param Password       Mot de passe correct
  @param ShowErrorMes   Indique s'il faut notifier sur erreur
  @return True si l'utilisateur a saisi le bon mot de passe, False sinon
*}
function QueryPassWord(Password: string;
  ShowErrorMes: Boolean = True): Boolean;
begin
  Result := TSdPasswordForm.QueryPassword(Password, ShowErrorMes);
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
procedure ShowAbout(Title: string; ProgramIcon: TIcon; ProgramName: string;
  ProgramVersion: string; Author: string; AuthorEMail: string = '';
  WebSite: string = '');
begin
  TSdAboutForm.ShowAbout(Title, ProgramIcon, ProgramName, ProgramVersion,
    Author, AuthorEMail, WebSite);
end;

{*
  Demande un nombre � l'utilisateur
  @param Title     Titre de la bo�te de dialogue
  @param Prompt    Invite de la bo�te de dialogue
  @param Default   Valeur par d�faut
  @param Min       Valeur minimum que peut choisir l'utilisateur
  @param Max       Valeur maximum que peut choisir l'utilisateur
  @return Nombre qu'a choisi l'utilisateur
*}
function QueryNumber(const Title, Prompt: string;
  Default, Min, Max: Integer): Integer;
begin
  Result := TSdNumberForm.QueryNumber(Title, Prompt, Default, Min, Max);
end;

{--------------------------}
{ Classe TSdPasswordDialog }
{--------------------------}

{*
  Cr�e une instance de TSdPasswordDialog
  @param AOwner   Propri�taire
*}
constructor TSdPasswordDialog.Create(AOwner: TComponent);
begin
  inherited;
  FPassword := '';
  FShowErrorMes := True;
end;

{*
  Demande un mot de passe � l'utilisateur
  @return True si l'utilisateur a saisi le bon mot de passe, False sinon
*}
function TSdPasswordDialog.Execute: Boolean;
begin
  Result := Execute(Password, ShowErrorMes);
end;

{*
  Demande un mot de passe � l'utilisateur
  @param Password       Mot de passe correct
  @param ShowErrorMes   Indique s'il faut notifier sur erreur
  @return True si l'utilisateur a saisi le bon mot de passe, False sinon
*}
function TSdPasswordDialog.Execute(Password: string;
  ShowErrorMes: Boolean = True): Boolean;
begin
  Result := TSdPassWordForm.QueryPassword(Password, ShowErrorMes);
end;

{*
  Demande un mot de passe � l'utilisateur
  @param ShowErrorMes   Indique s'il faut notifier sur erreur
  @return True si l'utilisateur a saisi le bon mot de passe, False sinon
*}
function TSdPasswordDialog.Execute(ShowErrorMes: Boolean): Boolean;
begin
  Result := Execute(Password, ShowErrorMes);
end;

{-----------------------}
{ Classe TSdAboutDialog }
{-----------------------}

{*
  Cr�e une instance de TSdAboutDialog
  @param AOwner   Propri�taire
*}
constructor TSdAboutDialog.Create(AOwner: TComponent);
begin
  inherited;
  FTitle := sScAbout;
  FProgramIcon := TIcon.Create;
  FProgramName := '';
  FVersion := sScVersion+sScColon;
  FProgramVersion := '1.0'; {don't localize}
  FAuthor := sScAuthor+sScColon;
  FAuthorName := '';
  FAuthorEMail := '';
  FWebSite := '';
end;

{*
  D�truit l'instance
*}
destructor TSdAboutDialog.Destroy;
begin
  FProgramIcon.Free;
  inherited;
end;

{*
  Modifie l'ic�ne du programme
  @param New   Nouvelle ic�ne
*}
procedure TSdAboutDialog.SetProgramIcon(New: TIcon);
begin
  FProgramIcon.Assign(New);
end;

{*
  Indique si le titre doit �tre stock� dans un flux dfm
  @return True si le titre est diff�rent de celui par d�faut, False sinon
*}
function TSdAboutDialog.IsTitleStored: Boolean;
begin
  Result := FTitle <> sScAbout;
end;

{*
  Indique si l'intitul� de version doit �tre stock� dans un flux dfm
  @return True si l'intitul� est diff�rent de celui par d�faut, False sinon
*}
function TSdAboutDialog.IsVersionStored: Boolean;
begin
  Result := FVersion <> sScVersion+sScColon;
end;

{*
  Indique si la version du programme doit �tre stock�e dans un flux dfm
  @return True si la version est '1.0', False sinon
*}
function TSdAboutDialog.IsProgramVersionStored: Boolean;
begin
  Result := FProgramVersion <> '1.0'; {don't localize}
end;

{*
  Indique si l'intitul� d'auteur doit �tre stock� dans un flux dfm
  @return True si l'intitul� est diff�rent de celui par d�faut, False sinon
*}
function TSdAboutDialog.IsAuthorStored: Boolean;
begin
  Result := FAuthor <> sScAuthor+sScColon;
end;

{*
  Affiche la bo�te de dialogue
*}
procedure TSdAboutDialog.Execute;
begin
  TSdAboutForm.ShowAbout(Title, ProgramIcon, ProgramName,
    Version+' '+ProgramVersion, Author+' '+AuthorName, AuthorEMail, WebSite);
end;

{------------------------}
{ Classe TSdNumberDialog }
{------------------------}

{*
  Cr�e une instance de TSdNumberDialog
  @param AOwner   Propri�taire
*}
constructor TSdNumberDialog.Create(AOwner: TComponent);
begin
  inherited;

  FTitle := '';
  FPrompt := '';
  FValue := 0;
  FMin := 0;
  FMax := 0;
end;

{*
  Affiche la bo�te de dialogue
  @param ATitle     Titre de la bo�te de dialogue
  @param APrompt    Invite
  @param ADefault   Valeur par d�faut
  @param AMin       Valeur minimale
  @param AMax       Valeur maximale
  @return Valeur s�lectionn�e par l'utilisateur
*}
function TSdNumberDialog.Execute(const ATitle, APrompt: string;
  ADefault, AMin, AMax: Integer): Integer;
begin
  FValue := QueryNumber(ATitle, APrompt, ADefault, AMin, AMax);
  Result := FValue;
end;

{*
  Affiche la bo�te de dialogue
  @param ADefault   Valeur par d�faut
  @param AMin       Valeur minimale
  @param AMax       Valeur maximale
  @return Valeur s�lectionn�e par l'utilisateur
*}
function TSdNumberDialog.Execute(
  ADefault, AMin, AMax: Integer): Integer;
begin
  Result := Execute(Title, Prompt, ADefault, AMin, AMax);
end;

{*
  Affiche la bo�te de dialogue
  Cette variante utilise comme valeur par d�faut la valeur s�lectionn�e par
  l'utilisateur lors de la pr�c�dent invocation.
  @param ATitle    Titre de la bo�te de dialogue
  @param APrompt   Invite
  @param AMin      Valeur minimale
  @param AMax      Valeur maximale
  @return Valeur s�lectionn�e par l'utilisateur
*}
function TSdNumberDialog.Execute(const ATitle, APrompt: string;
  AMin, AMax: Integer): Integer;
begin
  Result := Execute(Title, Prompt, Value, AMin, AMax);
end;

{*
  Affiche la bo�te de dialogue
  Cette variante utilise comme valeur par d�faut la valeur s�lectionn�e par
  l'utilisateur lors de la pr�c�dent invocation.
  @param AMin   Valeur minimale
  @param AMax   Valeur maximale
  @return Valeur s�lectionn�e par l'utilisateur
*}
function TSdNumberDialog.Execute(AMin, AMax: Integer): Integer;
begin
  Result := Execute(Title, Prompt, Value, AMin, AMax);
end;

{*
  Affiche la bo�te de dialogue
  Cette variante utilise comme valeur par d�faut la valeur s�lectionn�e par
  l'utilisateur lors de la pr�c�dent invocation.
  @return Valeur s�lectionn�e par l'utilisateur
*}
function TSdNumberDialog.Execute: Integer;
begin
  Result := Execute(Title, Prompt, Value, Min, Max);
end;

end.

