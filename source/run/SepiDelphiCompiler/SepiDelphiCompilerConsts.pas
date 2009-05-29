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
  Constantes pour la compilation d'unit� unit� Delphi en Sepi
  @author sjrd
  @version 1.0
*}
unit SepiDelphiCompilerConsts;

interface

uses
  SepiReflectionCore, SepiMembers;

resourcestring
  SWrongSetCompType =
    'Les �l�ments d''un ensemble doivent �tre des ordinaux avec maximum 256 '+
    'valeurs';
  SUnknownMethodRefModifier =
    'Modificateur de r�f�rence de m�thode %s inconnu';
  SUnknownMethodModifier = 'Modificateur de m�thode %s inconnu';
  SUnknownPropertyModifier = 'Modificateur de propri�t� %s inconnu';
  SIntfMethodCantBeOverloaded =
    'Les m�thodes d''interface ne peuvent �tre surcharg�es';
  SArrayValueRequired = 'Type tableau requis';
  SRecordValueRequired = 'Type record requis';
  SElementCountMismatch =
    'Le nombre d''�l�ments (%1:d) diff�re de la d�claration (%0:d)';
  STypeIdentifierRequired = 'Identificateur de type requis';
  SOneParamRequiredForCast = 'Un param�tre requis pour un transtypage';
  SOpenArrayParamCantHaveDefaultValue =
    'Un param�tre tableau ouvert ne peut pas avoir de valeur par d�faut';
  SMultiNameParamCantHaveDefaultValue =
    'Une d�finition de plusieurs param�tres ne peut pas avoir de valeur par '+
    'd�faut';
  SDuplicateModifier = 'Modificateur %s dupliqu�';
  SPropertyNotFoundInBaseClass =
    'La propri�t� n''a pas �t� trouv�e dans la classe de base';
  SFieldOrMethodRequired = 'Champ ou m�thode requis';
  SArrayPropertyRequired = 'Propri�t� tableau requise';
  SDuplicateDefaultProperty = 'Ne peut avoir plusieurs propri�t�s par d�faut';
  SParametersMismatch = 'Les param�tres ne correspondent pas';
  SMethodNotDeclared = 'M�thode %s non d�clar�e';
  SMethodMustBeOverloaded =
    'La m�thode %s doit �tre marqu�e avec la directive overload';
  SPreviousDeclWasNotOverload =
    'La d�claration pr�c�dente de %s n''a pas �t� marqu�e avec la directive '+
    'overload';
  SDeclarationDiffersFromPreviousOne =
    'La d�claration de %s diff�re de la d�claration pr�c�dente';
  SMethodAlreadyImplemented = 'La m�thode %s a d�j� �t� impl�ment�e';

implementation

end.

