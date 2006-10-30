{*
  D�finit des routines et composants utilisant des bo�tes de dialogue
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit SdDialogs;

interface

uses
  Classes, Graphics, SdPassword, SdAbout, ScConsts;

type
  {*
    G�re une bo�te de dialogue d'introduction de mot de passe
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSdPasswordDialog = class(TComponent)
  private
    FPassword : string;      /// Mot de passe correct
    FShowErrorMes : boolean; /// Indique s'il faut notifier sur erreur
  public
    constructor Create(AOwner : TComponent); override;

    function Execute : boolean; overload;
    function Execute(Password : string;
      ShowErrorMes : boolean = True) : boolean; overload;
    function Execute(ShowErrorMes : boolean) : boolean; overload;
  published
    property Password : string read FPassword write FPassword;
    property ShowErrorMes : boolean read FShowErrorMes write FShowErrorMes
      default True;
  end;

  {*
    G�re une bo�te de dialogue � propos
    @author S�bastien Jean Robert Doeraene
    @version 1.0
  *}
  TSdAboutDialog = class(TComponent)
  private
    FTitle : string;          /// Titre de la bo�te de dialogue
    FProgramIcon : TIcon;     /// Ic�ne du programme
    FProgramName : string;    /// Nom du programme
    FVersion : string;        /// Intitul� de version
    FProgramVersion : string; /// Version du programme
    FAuthor : string;         /// Intitul� d'auteur
    FAuthorName : string;     /// Nom de l'auteur du programme
    FAuthorEMail : string;    /// Adresse e-mail de l'auteur (optionnel)
    FWebSite : string;        /// Site Web du programme (optionnel)

    procedure SetProgramIcon(New : TIcon);

    function IsTitleStored : boolean;
    function IsVersionStored : boolean;
    function IsProgramVersionStored : boolean;
    function IsAuthorStored : boolean;
  public
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;

    procedure Execute;
  published
    property Title : string read FTitle write FTitle stored IsTitleStored;
    property ProgramIcon : TIcon read FProgramIcon write SetProgramIcon;
    property ProgramName : string read FProgramName write FProgramName;
    property Version : string read FVersion write FVersion
      stored IsVersionStored;
    property ProgramVersion : string read FProgramVersion write FProgramVersion
      stored IsProgramVersionStored;
    property Author : string read FAuthor write FAuthor stored IsAuthorStored;
    property AuthorName : string read FAuthorName write FAuthorName;
    property AuthorEMail : string read FAuthorEMail write FAuthorEMail;
    property WebSite : string read FWebSite write FWebSite;
  end platform;

function QueryPassword : string; overload;

function QueryPassWord(Password : string;
  ShowErrorMes : boolean = True) : boolean; overload;

procedure ShowAbout(Title : string; ProgramIcon : TIcon; ProgramName : string;
  ProgramVersion : string; Author : string; AuthorEMail : string = '';
  WebSite : string = ''); platform;

implementation

{-------------------}
{ Routines globales }
{-------------------}

{*
  Demande un mot de passe � l'utilisateur
  @return Le mot de passe qu'a saisi l'utilisateur
*}
function QueryPassword : string;
begin
  Result := TSdPasswordForm.QueryPassword;
end;

{*
  Demande un mot de passe � l'utilisateur
  @param Password       Mot de passe correct
  @param ShowErrorMes   Indique s'il faut notifier sur erreur
  @return True si l'utilisateur a saisi le bon mot de passe, False sinon
*}
function QueryPassWord(Password : string;
  ShowErrorMes : boolean = True) : boolean;
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
procedure ShowAbout(Title : string; ProgramIcon : TIcon; ProgramName : string;
  ProgramVersion : string; Author : string; AuthorEMail : string = '';
  WebSite : string = '');
begin
  TSdAboutForm.ShowAbout(Title, ProgramIcon, ProgramName, ProgramVersion,
    Author, AuthorEMail, WebSite);
end;

{--------------------------}
{ Classe TSdPasswordDialog }
{--------------------------}

{*
  Cr�e une instance de TSdPasswordDialog
  @param AOwner   Propri�taire
*}
constructor TSdPasswordDialog.Create(AOwner : TComponent);
begin
  inherited;
  FPassword := '';
  FShowErrorMes := True;
end;

{*
  Demande un mot de passe � l'utilisateur
  @return True si l'utilisateur a saisi le bon mot de passe, False sinon
*}
function TSdPasswordDialog.Execute : boolean;
begin
  Result := Execute(Password, ShowErrorMes);
end;

{*
  Demande un mot de passe � l'utilisateur
  @param Password       Mot de passe correct
  @param ShowErrorMes   Indique s'il faut notifier sur erreur
  @return True si l'utilisateur a saisi le bon mot de passe, False sinon
*}
function TSdPasswordDialog.Execute(Password : string;
  ShowErrorMes : boolean = True) : boolean;
begin
  Result := TSdPassWordForm.QueryPassword(Password, ShowErrorMes);
end;

{*
  Demande un mot de passe � l'utilisateur
  @param ShowErrorMes   Indique s'il faut notifier sur erreur
  @return True si l'utilisateur a saisi le bon mot de passe, False sinon
*}
function TSdPasswordDialog.Execute(ShowErrorMes : boolean) : boolean;
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
constructor TSdAboutDialog.Create(AOwner : TComponent);
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
procedure TSdAboutDialog.SetProgramIcon(New : TIcon);
begin
  FProgramIcon.Assign(New);
end;

{*
  Indique si le titre doit �tre stock� dans un flux dfm
  @return True si le titre est diff�rent de celui par d�faut, False sinon
*}
function TSdAboutDialog.IsTitleStored : boolean;
begin
  Result := FTitle <> sScAbout;
end;

{*
  Indique si l'intitul� de version doit �tre stock� dans un flux dfm
  @return True si l'intitul� est diff�rent de celui par d�faut, False sinon
*}
function TSdAboutDialog.IsVersionStored : boolean;
begin
  Result := FVersion <> sScVersion+sScColon;
end;

{*
  Indique si la version du programme doit �tre stock�e dans un flux dfm
  @return True si la version est '1.0', False sinon
*}
function TSdAboutDialog.IsProgramVersionStored : boolean;
begin
  Result := FProgramVersion <> '1.0'; {don't localize}
end;

{*
  Indique si l'intitul� d'auteur doit �tre stock� dans un flux dfm
  @return True si l'intitul� est diff�rent de celui par d�faut, False sinon
*}
function TSdAboutDialog.IsAuthorStored : boolean;
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

end.

