{-------------------------------------------------------------------------------
SepiExplorer - Example program for Sepi
As an example program, SepiExplorer is free of any usage. It is released in the
public domain.
-------------------------------------------------------------------------------}

{*
  Fiche principale de l'explorateur
  @author sjrd
  @version 1.0
*}
unit SepiExplorerMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ActnList, ImgList, Menus, VirtualTrees, SdDialogs,
  SepiReflectionCore, SepiMembers, SepiRuntime, ExplorerOptions, ExplorerConsts,
  ExtCtrls, MetaExplorer;

type
  {*
    Fiche principale de l'explorateur
    @author sjrd
    @version 1.0
  *}
  TExplorerForm = class(TForm)
    TreeView: TVirtualStringTree;
    MainMenu: TMainMenu;
    BigMenuFile: TMenuItem;
    MenuLoadUnit: TMenuItem;
    MenuSepFile1: TMenuItem;
    MenuExit: TMenuItem;
    ActionList: TActionList;
    ImageList: TImageList;
    ActionLoadUnit: TAction;
    ActionExit: TAction;
    ActionEditBrowsingPath: TAction;
    BigMenuOptions: TMenuItem;
    MenuEditBrowsingPath: TMenuItem;
    SplitterLeft: TSplitter;
    MetaExplorer: TFrameMetaExplorer;
    procedure TreeViewChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure ActionEditBrowsingPathExecute(Sender: TObject);
    procedure TreeViewInitChildren(Sender: TBaseVirtualTree; Node: PVirtualNode;
      var ChildCount: Cardinal);
    procedure TreeViewInitNode(Sender: TBaseVirtualTree; ParentNode,
      Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
    procedure TreeViewGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: WideString);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ActionLoadUnitExecute(Sender: TObject);
    procedure ActionExitExecute(Sender: TObject);
  private
    FOptions: TExplorerOptions; /// Options de l'explorateur
    FSepiRoot: TSepiRoot;       /// Racine Sepi
    FRuntimeUnits: TStrings;    /// Unit�s de type run-time

    function RootLoadUnit(Sender: TSepiRoot;
      const UnitName: string): TSepiUnit;

    function GetNodeMeta(Node: PVirtualNode): TSepiMeta;

    function GetRuntimeMethod(SepiMethod: TSepiMethod): TSepiRuntimeMethod;

    procedure LoadUnit(const UnitName: string);
  public
    function FindMetaNode(Meta: TSepiMeta): PVirtualNode;

    property Options: TExplorerOptions read FOptions;
    property SepiRoot: TSepiRoot read FSepiRoot;
  end;

var
  /// Form principale
  ExplorerForm: TExplorerForm;

implementation

{$R *.dfm}

type
  PNodeData = ^TSepiMeta;

{---------------------}
{ TExplorerForm class }
{---------------------}

{*
  Cr�ation de la fiche
*}
procedure TExplorerForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  FOptions := TExplorerOptions.Create;

  FSepiRoot := TSepiRoot.Create;
  FSepiRoot.OnLoadUnit := RootLoadUnit;
  FRuntimeUnits := TStringList.Create;

  MetaExplorer.OnGetRuntimeMethod := GetRuntimeMethod;

  // Load all units passed on the command line
  for I := 1 to ParamCount do
  begin
    try
      SepiRoot.LoadUnit(ParamStr(I));
    except
      on Error: ESepiUnitNotFoundError do;
    end;
  end;

  // Tell the treeview how many units there are
  TreeView.RootNodeCount := SepiRoot.UnitCount;
end;

{*
  Destruction de la fiche
*}
procedure TExplorerForm.FormDestroy(Sender: TObject);
begin
  FRuntimeUnits.Free;
  FSepiRoot.Free;

  FOptions.Free;
end;

{*
  Charge une unit�
  @param Sender     Racine Sepi
  @param UnitName   Nom de l'unit� � charger
  @return Unit� charg�e, ou nil si non trouv�e
*}
function TExplorerForm.RootLoadUnit(Sender: TSepiRoot;
  const UnitName: string): TSepiUnit;
var
  UnitFileName: string;
  Stream: TStream;
  LazyLoad: Boolean;
  RuntimeUnit: TSepiRuntimeUnit;
begin
  UnitFileName := Options.SearchFile(UnitName + CompiledIntfExt);

  if UnitFileName <> '' then
  begin
    Stream := TFileStream.Create(UnitFileName, fmOpenRead);
    LazyLoad := Stream.Size > MaxSizeBeforeLazyLoad;
    try
      Result := TSepiUnit.LoadFromStream(Sender, Stream, LazyLoad);
      if LazyLoad then
        Result.AcquireObjResource(Stream);
    finally
      Stream.Free;
    end;
  end else
  begin
    UnitFileName := Options.SearchFile(UnitName + CompiledUnitExt);

    if UnitFileName <> '' then
    begin
      RuntimeUnit := TSepiRuntimeUnit.Create(SepiRoot, UnitFileName);
      FRuntimeUnits.AddObject(RuntimeUnit.SepiUnit.Name, RuntimeUnit);
      Result := RuntimeUnit.SepiUnit;
    end else
      Result := nil;
  end;
end;

{*
  Obtient le meta repr�sent� par un noeud donn�
  @param Node   Noeud de l'arbre
  @return Meta repr�sent� par ce noeud
*}
function TExplorerForm.GetNodeMeta(Node: PVirtualNode): TSepiMeta;
begin
  Result := PNodeData(TreeView.GetNodeData(Node))^;
end;

{*
  Trouve la m�thode run-time correspondant � une m�thode Sepi
  @param SepiMethod   M�thode Sepi
  @return M�thode run-time correspondante, ou nil si non trouv�e
*}
function TExplorerForm.GetRuntimeMethod(
  SepiMethod: TSepiMethod): TSepiRuntimeMethod;
var
  Index, I: Integer;
  RuntimeUnit: TSepiRuntimeUnit;
begin
  Index := FRuntimeUnits.IndexOf(SepiMethod.OwningUnit.Name);
  if Index < 0 then
    Result := nil
  else
  begin
    RuntimeUnit := TSepiRuntimeUnit(FRuntimeUnits.Objects[Index]);

    for I := 0 to RuntimeUnit.MethodCount-1 do
    begin
      Result := RuntimeUnit.Methods[I];
      if Result.SepiMethod = SepiMethod then
        Exit;
    end;

    Result := nil;
  end;
end;

{*
  Trouve le noeud de l'arbre correspondant � un meta donn�
  Il n'y a aucun test de v�rification d'erreur
  @param Meta   Meta recherch�
  @return Noeud correspondant
*}
function TExplorerForm.FindMetaNode(Meta: TSepiMeta): PVirtualNode;
begin
  Result := PVirtualNode(Meta.Tag);
  Assert(GetNodeMeta(Result) = Meta);
end;

{*
  Charge une unit� et l'affiche dans l'arbre
  @param UnitName   Nom de l'unit� � charger
*}
procedure TExplorerForm.LoadUnit(const UnitName: string);
begin
  try
    SepiRoot.LoadUnit(UnitName);
    TreeView.RootNodeCount := SepiRoot.UnitCount;
  except
    on Error: ESepiUnitNotFoundError do
      ShowDialog('Unit� non trouv�e', Error.Message, dtError);
  end;
end;

{*
  Initialise un noeud
*}
procedure TExplorerForm.TreeViewInitNode(Sender: TBaseVirtualTree;
  ParentNode, Node: PVirtualNode; var InitialStates: TVirtualNodeInitStates);
var
  Index: Integer;
  Parent: TSepiMeta;
  Meta: TSepiMeta;
begin
  if ParentNode = nil then
    Parent := SepiRoot
  else
    Parent := GetNodeMeta(ParentNode);

  Index := Node.Index;
  Meta := Parent.Children[Index];
  PNodeData(Sender.GetNodeData(Node))^ := Meta;
  Meta.Tag := Integer(Node);

  if Meta.ChildCount > 0 then
    Include(Node.States, vsHasChildren);

  if Pos('$', Meta.Name) > 0 then
    Exclude(Node.States, vsVisible);
end;

{*
  Initialise le nombre d'enfants d'un noeud
*}
procedure TExplorerForm.TreeViewInitChildren(Sender: TBaseVirtualTree;
  Node: PVirtualNode; var ChildCount: Cardinal);
begin
  ChildCount := GetNodeMeta(Node).ChildCount;
end;

{*
  R�cup�rer le nom d'un noeud
*}
procedure TExplorerForm.TreeViewGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: WideString);
var
  Meta: TSepiMeta;
begin
  Meta := GetNodeMeta(Node);
  CellText := Meta.Name;
end;

{*
  Changement de s�lection dans le treeview
*}
procedure TExplorerForm.TreeViewChange(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
begin
  if Node = nil then
    MetaExplorer.SepiMeta := nil
  else
    MetaExplorer.SepiMeta := GetNodeMeta(Node);
end;

{*
  Action Charger une unit�
*}
procedure TExplorerForm.ActionLoadUnitExecute(Sender: TObject);
var
  UnitName: string;
begin
  // Load unit
  if InputQuery('Charger une unit�',
    'Veuillez entrer le nom de l''unit� � charger', UnitName) then
    LoadUnit(UnitName);
end;

{*
  Action Quitter
*}
procedure TExplorerForm.ActionExitExecute(Sender: TObject);
begin
  Close;
end;

{*
  Action Modifier le chemin de recherche
*}
procedure TExplorerForm.ActionEditBrowsingPathExecute(Sender: TObject);
var
  BrowsingPath: string;
begin
  BrowsingPath := Options.BrowsingPath;
  if InputQuery('Chemin de recherche', 'Chemin de recherche', BrowsingPath) then
    Options.BrowsingPath := BrowsingPath;
end;

end.

