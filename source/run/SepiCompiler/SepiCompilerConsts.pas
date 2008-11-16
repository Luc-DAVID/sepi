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
  Constantes utilis�es dans un compilateur Sepi
  @author sjrd
  @version 1.0
*}
unit SepiCompilerConsts;

interface

resourcestring
  // Format des erreurs
  SSepiHintName = 'Conseil';
  SSepiWarningName = 'Avertissement';
  SSepiErrorName = 'Erreur';
  SSepiFatalErrorName = 'Erreur fatale';
  SSepiCompilerErrorFormat = '[%s] %s(%d, %d) : %s';

  // Erreurs de compilation g�n�riques
  SSepiThereWereErrors = 'Il y a eu des erreurs � la compilation';
  STooManyErrors = 'Trop d''erreurs';
  SIdentifier = 'Identificateur';
  SRedeclaredIdentifier = 'Identificateur red�clar�';
  SIdentifierNotFound = 'Identificateur %s non d�clar�';
  STypeMismatch = 'Types incompatibles : %s et %s';
  SNeedConstExpression = 'Expression constante attendue';

  // Erreurs de compilation sur les expressions
  SSepiErroneousTypeName = 'type erron�';
  STypeIsNotBaseType =
    'Le type %s n''est pas un type de base pour l''interpr�teur Sepi';
  SInvalidCast = 'Transtypage invalide de %s en %s';
  SOperationNotApplicableToType =
    'Op�ration non applicable � ce type d''op�rande';
  STypeHasNoTypeInfo = 'Ce type n''a pas d''informations de type';
  STestValueIsAlways = 'La condition est toujours �valu�e � %s';
  SConstExpressionRequired = 'Expression constante attendue';
  SCallableRequired = 'Expression invocable requise';

  // Sorte particuli�re de type requise
  STypeIdentifierRequired = 'Identificateur de type requis';
  SPointerTypeRequired = 'Type pointeur requis';
  SOrdinalOrArrayTypeRequired = 'Type ordinal ou tableau requis';
  SArrayTypeRequired = 'Type tableau requis';
  SOrdinalTypeRequired = 'Type ordinal requis';
  SClassTypeRequired = 'Type classe requis';
  SInterfaceTypeRequired = 'Type interface requis';

  // Erreurs sur les valeurs
  SValueRequired = 'Valeur requise';
  SVarValueRequired = 'Variable requise';
  SValueCantBeRead = 'La valeur ne peut �tre lue';
  SReadableValueRequired = 'Valeur requise';
  SWritableValueRequired = 'La valeur ne peut �tre �crite';
  SAddressableValueRequired = 'Valeur adressable requise';

  // Erreurs sur les param�tres
  SVarParamTypeMustBeStrictlyEqual =
    'Les param�tres var originaux et formels doivent avoir le m�me type';
  SNotEnoughActualParameters = 'Pas assez de param�tres r�els';
  STooManyActualParameters = 'Trop de param�tres r�els';
  SNoMatchingOverloadedMethod =
    'Aucune m�thode surcharg�e ne peut �tre invoqu�e avec ces param�tres';
  SCallPatternOnlyOnClassMethod =
    'Forme d''appel autoris�e uniquement sur les m�thodes de classe';

  // Erreurs sur des classes ou interfaces
  SClassDoesNotImplementIntf = 'La classe %s n''impl�mente pas l''interface %s';

  // Erreurs de compilateur
  SLabelAlreadyExists = 'Le label ''%s'' existe d�j�';
  SLabelNotFound = 'Label ''%s'' non trouv�';
  SMemoryRefIsSealed = 'La r�f�rence m�moire est scell�e';
  SMemoryCantBeZero = 'La r�f�rence m�moire ne peut �tre z�ro';
  SMemoryCantBeConstant = 'La r�f�rence m�moire ne peut �tre constante';
  SMemoryCantBeTrueConst =
    'La r�f�rence m�moire ne peut �tre une vraie constante';
  SMemorySpaceOffsetMustBeWord =
    'L''offset d''espace m�moire doit �tre contenu dans un Word';
  SMemoryCantAccessObject = 'Impossible d''acc�der � l''objet %s';
  STooManyOperations =
    'Une r�f�rence m�moire ne peut avoir que 15 op�rations maximum';
  SZeroMemoryCantHaveOperations =
    'Une r�f�rence m�moire vers des 0 ne peut avoir d''op�rations';
  SConstArgMustBeShort =
    'L''argument constant doit �tre contenu dans un Shortint';
  SCantRemoveDereference = 'Ne peut retirer de d�r�f�rencement';
  SParamsAlreadyCompleted = 'Les param�tres ont d�j� �t� compl�t�s';
  SSignatureAlreadyKnown = 'La signature est d�j� connue';

  // Erreurs d'instructions assembleur
  SMultipleParamsWithSameSepiStackOffset =
    'Plusieurs param�tres ont la m�me valeur de SepiStackOffset';
  SParamsSepiStackOffsetsDontFollow =
    'Les SepiStackOffset des param�tres ne se suivent pas';
  SInvalidDataSize = 'Taille de donn�es invalide';
  SObjectMustHaveASignature = 'L''objet %s n''a pas de signature';

  // Erreurs de parser LL1
  STopOfStackIsNotASymbol = 'Le sommet de la pile n''est pas un symbole';
  STopOfStackIsNotATry = 'Le sommet de la pile n''est pas un try';
  SNotInTry = 'La pile n''est pas dans un try';

implementation

end.
