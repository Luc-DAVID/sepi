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
  Composants de type Image
  @author sjrd
  @version 1.0
*}
unit SvImages;

interface

uses
  Windows, Forms, Classes, Controls, ExtCtrls;

type
  {*
    Type de l'�v�nement TSvDropImage.OnDrop
    @param Sender   Objet qui a d�clench� l'�v�nement
    @param X        Coordonn�e X de d�p�t de l'image
    @param Y        Coordonn�e Y de d�p�t de l'image
  *}
  TDropImageEvent = procedure(Sender: TObject; X, Y: Integer) of object;

  {*
    Image pouvant �tre � prise � et d�pos�e
    TSvDropImage est une image qui peut �tre � prise � au moyen d'un clic de
    souris et d�pos�e par glisser-d�poser soit sur le parent, soit sur un autre
    contr�le. Ce composant permet de constituer de fa�on tr�s simple une palette
    de glisser-d�poser.
    @author sjrd
    @version 1.0
  *}
  TSvDropImage = class(TImage)
  private
    ImageBis: TImage;         /// Copie de l'image en train d'�tre gliss�e
    FDropControl: TControl;   /// Contr�le sur lequel il faut d�poser l'image
    FOnDrop: TDropImageEvent; /// Ex�cut� lorsque l'image a �t� d�pos�e

    procedure MoveBisAt(X, Y: Integer);
  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
      X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property DropControl: TControl
      read FDropControl write FDropControl;
    property OnDrop: TDropImageEvent read FOnDrop write FOnDrop;
  end;

implementation

{---------------------}
{ Classe TScDropImage }
{---------------------}

{*
  Cr�e une instance de TSvDropImage
  @param AOwner   Propri�taire
*}
constructor TSvDropImage.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csCaptureMouse];
  ImageBis := nil;
  FDropControl := nil;
  FOnDrop := nil;
end;

{*
  D�place la copie en d�placement de l'image � des coordonn�es sp�cifi�es
  @param X   Coordonn�e X du point sur lequel centrer la copie de l'image
  @param Y   Coordonn�e Y du point sur lequel centrer la copie de l'image
*}
procedure TSvDropImage.MoveBisAt(X, Y: Integer);
var
  L, T, ParentWidth, ParentHeight: Integer;
begin
  if Parent is TForm then
  begin
    ParentWidth := (Parent as TForm).ClientWidth;
    ParentHeight := (Parent as TForm).ClientHeight;
  end else
  begin
    ParentWidth := Parent.Width;
    ParentHeight := Parent.Height;
  end;

  L := Left + X - Width  div 2;
  T := Top  + Y - Height div 2;

  if L > (ParentWidth -Width) then
    L := ParentWidth -Width;
  if L < 0 then
    L := 0;
  if T > (ParentHeight-Height) then
    T := ParentHeight-Height;
  if T < 0 then
    T := 0;

  ImageBis.Left := L;
  ImageBis.Top := T;
end;

{*
  Ex�cut� lorsque l'utilisateur enfonce le bouton de la souris
  @param Button   Bouton de souris enfonc�
  @param Shift    �tat des touches syst�me et des boutons de souris
  @param X        Coordonn�e X du point de clic
  @param Y        Coordonn�e Y du point de clic
*}
procedure TSvDropImage.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if not Enabled then
    Exit;
  if (Button <> mbLeft) or Assigned(ImageBis) then
    Exit;

  ImageBis := TImage.Create(Self);
  ImageBis.Parent := Parent;
  ImageBis.Width := Width;
  ImageBis.Height := Height;
  ImageBis.Stretch := Stretch;
  ImageBis.Picture.Assign(Picture);
  MoveBisAt(X, Y);
end;

{*
  Ex�cut� lorsque l'utilisateur d�place la souris
  @param Shift    �tat des touches syst�me et des boutons de souris
  @param X        Coordonn�e X de la souris
  @param Y        Coordonn�e Y de la souris
*}
procedure TSvDropImage.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Assigned(ImageBis) then
    MoveBisAt(X, Y);
end;

{*
  Ex�cut� lorsque l'utilisateur rel�che le bouton de la souris
  @param Button   Bouton de souris rel�ch�
  @param Shift    �tat des touches syst�me et des boutons de souris
  @param X        Coordonn�e X du point de rel�che
  @param Y        Coordonn�e Y du point de rel�che
*}
procedure TSvDropImage.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  PutPoint: TPoint;
begin
  inherited;
  if (Button <> mbLeft) or (not Assigned(ImageBis)) then
    Exit;

  ImageBis.Free;
  ImageBis := nil;

  if not Assigned(FOnDrop) then
    Exit;
  if Assigned(FDropControl) then
    PutPoint := FDropControl.ScreenToClient(ClientToScreen(Point(X, Y)))
  else
    PutPoint := ClientToParent(Point(X, Y));
  FOnDrop(Self, PutPoint.X, PutPoint.Y);
end;

end.

