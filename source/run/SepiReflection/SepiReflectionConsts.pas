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
  D�finit les constantes du package SepiBinaries
  @author sjrd
  @version 1.0
*}
unit SepiReflectionConsts;

interface

const
  SUntypedTypeName = '$Untyped'; /// Nom du type non typ�

resourcestring
  SSepiComponentAlreadyCreated = 'Le meta de nom ''%s'' a d�j� �t� cr��';
  SSepiComponentAlreadyExists = 'Un meta de  nom ''%s'' existe d�j�';
  SSepiComponentAlreadyAssigned = 'L''objet meta � la position %d est d�j� assign�';
  SSepiComponentNotFound = 'Composant %s non trouv�';
  SSepiUnitNotFound = 'Impossible de trouver l''unit� %s';
  SSepiCantSaveLazyLoadUnit =
    'Impossible d''enregistrer une unit� en mode lazy-load';
  SSepiNoRegisterTypeInfo = 'Ce type n''impl�mente pas RegisterTypeInfo';
  SCantCloneType = 'Ne peut cloner le type %s';
  SSepiBadConstType = 'Impossible de cr�er une constante de type variant %d';
  SSignatureAlreadyCompleted = 'La signature est d�j� compl�t�e';

  SSepiUnsupportedIntfCallConvention =
    'La convention d''appel %s n''est pas encore support�e pour les interfaces';

  SUntypedTypeDescription = '(non typ�)';

implementation

end.

