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
  D�finit les diff�rentes constantes de la SCL
  @author sjrd
  @version 1.0
*}
unit ScConsts;

interface

resourcestring
  sScLanguage = 'Fran�ais (Belgique)';

  // Common consts
  sScYes = 'Oui';
  sScNo = 'Non';
  sScColon = ' :';
  sScSemiColon = ' ;';
  sScAbout = '� propos';
  sScVersion = 'Version';
  sScAuthor = 'Auteur';
  sScWrongPassword = 'Mot de passe incorrect';

  // Months consts
  sJanuary = 'janvier';
  sFebruary = 'f�vrier';
  sMarch = 'mars';
  sApril = 'avril';
  sMay = 'mai';
  sJune = 'juin';
  sJuly = 'juillet';
  sAugust = 'ao�t';
  sSeptember = 'septembre';
  sOctober = 'octobre';
  sNovember = 'novembre';
  sDecember = 'd�cembre';

  // Lists errors
  sScNotInMustPairsOfChars = 'NotIn doit contenir des paires de caract�res';
  sScDelimMustDifferentThanNotIn =
    'Delim et NotIn ne peuvent contenir un m�me caract�re';
  sScIndexOutOfRange = 'Index liste hors bornes (%d)';
  sScWrongIntSize = 'Taille d''entier incorrecte : %d';
  sScWrongLongWord =
    '''%s'' n''est pas une valeur enti�re non sign�e correcte';
  sScListIsNotEmpty = 'La liste n''est pas vide';

  // Extra errors
  sScWrongBase = 'La base %d est incorrecte';
  sScWrongInteger = 'Impossible de convertir "%s" en entier';
  sScWrongFloat = 'Impossible de convertir "%s" en valeur � virgule flottante';
  sScWrongString = 'Impossible de convertir "%s" en cha�ne de caract�res';
  sSjrdWrongChar = 'Impossible de convertir "%s" en caract�re';
  sScWrongCharSet = 'Impossible de convertir "%s" en ensemble de caract�res';
  sScSetOf = 'ensemble de %s';
  sScWrongEnumSet = 'Impossible de convertir "%s" en %s';

  // Maths errors
  sScErrorMaths = 'Erreur de math�matiques :'+#10;
  sScErrorDegree = 'Erreur avec le degr� %s';
  sScErrorNotDegreeZero = '%s n''est pas de degr� 0';
  sScErrorInteger = 'Erreur d''entier avec le nombre %f';
  sScErrorNotInteger = '%f n''est pas un nombre entier';
  sScErrorNatural = 'Erreur de naturel avec le nombre %d';
  sScErrorNotNatural = '%d n''est pas un nombre naturel';
  sScErrorDivision = 'Impossible de diviser %s par %s';
  sScErrorDivByZero = 'Division par 0 de %s impossible';
  sSjrdErrorAbortDivision = 'La division de %s par %s semble impossible';
  sScErrorRoot = 'Impossible de calculer la racine %s de %s';
  sScErrorEval = 'Erreur lors de l''�valuation de l''expression %s :'+#10;
  sScErrorWrongExpression = 'Expression erron�e';
  sScErrorWrongCharacter = 'Caract�re non autoris� : %s';
  sScErrorOperation = 'Erreur avec l''op�rateur %s';
  sScErrorOpNotExists = 'L''op�rateur %s n''existe pas';
  sScErrorOpIsNotBinary = 'L''op�rateur %s n''est pas un op�rateur binaire';
  sScErrorOpIsNotUnary = 'L''op�rateur %s n''est pas un op�rateur binaire';
  sScErrorOpRequestsDegreeZero =
    'L''op�rateur %s requiert un monome de degr� 0 (%s est de degr� %d)';
  sScErrorOpRequestsInteger =
    'L''op�rateur %s requiert un entier (%f n''est pas un entier)';
  sScErrorOpRequestsNatural =
    'L''op�rateur %s requiert un naturel (%d n''est pas un naturel)';
  sScErrorOpRequestsCorrectIndex =
    'L''op�rateur %s requiert un index de liste correct (%d n''est pas valable)';
  sScErrorBrackets = 'Erreur de parenth�ses';
  sScErrorTooManyBrackets = '%d parenth�ses %s en trop';

implementation

end.

