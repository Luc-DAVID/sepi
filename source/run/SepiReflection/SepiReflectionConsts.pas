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

resourcestring
  SSepiMetaAlreadyCreated = 'Le meta de nom ''%s'' a d�j� �t� cr��';
  SSepiMetaAlreadyExists = 'Un meta de  nom ''%s'' existe d�j�';
  SSepiMetaAlreadyAssigned = 'L''objet meta � la position %d est d�j� assign�';
  SSepiObjectNotFound = 'Objet %s non trouv�';
  SSepiUnitNotFound = 'Impossible de trouver l''unit� %s';
  SSepiNoRegisterTypeInfo = 'Ce type n''impl�mente pas RegisterTypeInfo';
  SCantCloneType = 'Ne peut cloner le type %s';
  SSepiBadConstType = 'Impossible de cr�er une constante de type variant %d';

  SSepiUnsupportedIntfCallConvention =
    'La convention d''appel %s n''est pas encore support�e pour les interfaces';

implementation

end.

