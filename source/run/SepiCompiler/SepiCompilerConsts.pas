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
  SCantOpenSourceFile = 'Ne peut ouvrir le fichier source %s';
  SCantOpenDestFile = 'Ne peut ouvrir le fichier de destination %s';
  SSepiInternalError = 'Erreur interne : %s';
  SSepiThereWereErrors = 'Il y a eu des erreurs � la compilation';
  STooManyErrors = 'Trop d''erreurs';
  SIdentifier = 'Identificateur';
  SRedeclaredIdentifier = 'Identificateur red�clar�';
  SIdentifierNotFound = 'Identificateur %s non d�clar�';
  STypeMismatch = 'Types incompatibles : %s et %s';
  SNeedConstExpression = 'Expression constante attendue';

  // Erreurs de l'analyseur lexical
  SBadSourceCharacter = 'Caract�re %s incorrect dans un source';
  SEndOfFile = 'Fin de fichier';
  SStringNotTerminated = 'Cha�ne non termin�e';
  SBookmarksCantPassThroughLexer =
    'Impossible de revenir en arri�re en changeant d''analyseur lexical de '+
    'base.';

  // Erreurs de l'analyseur syntaxique
  SSyntaxError = '%s attendu mais %s trouv�';

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
  SMethodRequired = 'Identificateur de m�thode requis';
  SInheritNeedClassOrObjectMethod =
    'Appel de type inherited invalide hors d''une m�thode d''objet ou de '+
    'classe';
  SCallableRequired = 'Expression invocable requise';
  SExecutableRequired = 'Expression ex�cutable requise';
  SComponentRequired = 'Nom d''objet requis';
  SIdentifierRequired = 'Identificateur requis';

  // Sorte particuli�re de type requise
  STypeIdentifierRequired = 'Identificateur de type requis';
  SStringTypeRequired = 'Type cha�ne requis';
  SPointerTypeRequired = 'Type pointeur requis';
  SArrayTypeRequired = 'Type tableau requis';
  SDynArrayTypeRequired = 'Type tableau dynamique requis';
  SStringOrDynArrayTypeRequired = 'Type cha�ne ou tableau dynamique requis';
  SRecordTypeRequired = 'Type record requis';
  SOrdinalOrArrayTypeRequired = 'Type ordinal ou tableau requis';
  SOrdinalTypeRequired = 'Type ordinal requis';
  SSetTypeRequired = 'Type ensemble requis';
  SClassTypeRequired = 'Type classe requis';
  SInterfaceTypeRequired = 'Type interface requis';
  SMetaClassTypeRequired = 'Type m�ta-classe requis';
  SContainerTypeRequired = 'Type classe, interface ou record requis';
  SCompilerTransientTypeForbidden =
    'Type de valeur sp�cial du compilateur non autoris� ici';
  SOpenArrayRequired = 'Tableau ouvert de type %s requis';
  SInvalidArrayOfConstItem =
    'Type de valeur non autoris� dans un �l�ment de tableau ouvert';
  SStringOrArrayTypeRequired = 'Type cha�ne ou tableau requis';
  SStringTypeOrTypeIdentifierRequired =
    'Type cha�ne ou identificateur de type requis';
  SArrayTypeOrTypeIdentifierRequired =
    'Type tableau ou identificateur de type requis';
  SStringOrArrayTypeOrTypeIdentifierRequired =
    'Type tableau, type cha�ne, ou identificateur de type requis';

  // Erreurs sur les valeurs
  SValueRequired = 'Valeur requise';
  SVarValueRequired = 'Variable requise';
  SValueCantBeRead = 'La valeur ne peut �tre lue';
  SReadableValueRequired = 'Valeur requise';
  SWritableValueRequired = 'La valeur ne peut �tre �crite';
  SAddressableValueRequired = 'Valeur adressable requise';

  // Valeurs particuli�res requise
  SBadStringLength =
    'La taille des cha�nes doit �tre comprise entre 0 et 255 inclus';

  // Erreurs sur les ensembles
  SUntypedEmptySetNotSupported = 'Ensemble vide non typ� non support�';
  SSetRangeTooWide = 'L''ensemble des valeurs est trop �tendu';
  SConstValueOutOfBounds =
    'La valeur constante d�passe les limites de sous-�tendue';
  SCompTypeTooNarrow =
    'Le type d''�l�ment %s est trop petit pour contenir toutes les valeurs '+
    'possibles de cet ensemble';

  // Erreurs sur les signatures
  SReturnTypeRequired = 'La fonction exige un type de retour';
  SReturnTypeForbidden = 'La proc�dure ne peut avoir de type de retour';
  SIntfMethodCantBeOverloaded =
    'Les m�thodes d''interface ne peuvent �tre surcharg�es';
  SIntfMethodCantChangeLinkKind =
    'Type de liaison invalide pour une m�thode d''interface';
  SDuplicatedLinkKind = 'Directive de type de liaison dupliqu�e';
  SDuplicatedAbstractMarker = 'Directive abstract dupliqu�e';
  SDuplicatedOfObjectMarker = 'Directive of object dupliqu�e';
  SVirtualOrDynamicMethodRequired = 'M�thode virtuelle ou dynamique requise';
  SMethodNotFoundInBaseClass = 'M�thode non trouv�e dans la classe de base';

  // Erreurs sur les param�tres
  SVarParamTypeMustBeStrictlyEqual =
    'Les param�tres var originaux et formels doivent avoir le m�me type';
  SNotEnoughActualParameters = 'Pas assez de param�tres r�els';
  STooManyActualParameters = 'Trop de param�tres r�els';
  SNoMatchingOverloadedMethod =
    'Aucune m�thode surcharg�e ne peut �tre invoqu�e avec ces param�tres';
  SCallPatternOnlyOnClassMethod =
    'Forme d''appel autoris�e uniquement sur les m�thodes de classe';
  SOpenArrayParamCantHaveDefaultValue =
    'Un param�tre tableau ouvert ne peut pas avoir de valeur par d�faut';
  SMultiNameParamCantHaveDefaultValue =
    'Une d�finition de plusieurs param�tres ne peut pas avoir de valeur par '+
    'd�faut';
  SByRefParamCantHaveDefaultValue =
    'Un param�tre pass� par r�f�rence ne peut pas avoir de valeur par d�faut';

  // Erreurs sur les propri�t�
  SInvalidStorageValue = 'Sp�cificateur de stockage invalide';

  // Erreurs sur les variables locales
  SLocalVarNameRequired = 'Variable locale requise';

  // Erreurs sur l'impl�mentation des m�thodes
  SMethodNotDeclared = 'M�thode %s non d�clar�e';
  SMethodMustBeOverloaded =
    'La m�thode %s doit �tre marqu�e avec la directive overload';
  SPreviousDeclWasNotOverload =
    'La d�claration pr�c�dente de %s n''a pas �t� marqu�e avec la directive '+
    'overload';
  SDeclarationDiffersFromPreviousOne =
    'La d�claration de %s diff�re de la d�claration pr�c�dente';
  SMethodAlreadyImplemented = 'La m�thode %s a d�j� �t� impl�ment�e';

  // Erreurs sur les indices de tableau
  SArrayOrArrayPropRequired = 'Valeur tableau ou propri�t� tableau requise';
  STooManyArrayIndices = 'Trop d''index pour ce tableau';

  // Erreurs sur des classes ou interfaces
  SClassDoesNotImplementIntf = 'La classe %s n''impl�mente pas l''interface %s';
  SPropertyNotFoundInBaseClass =
    'La propri�t� n''a pas �t� trouv�e dans la classe de base';
  SFieldOrMethodRequired = 'Champ ou m�thode requis';
  SFieldRequired = 'Champ requis';
  SRecordFieldRequired = 'Champ de type record requis';
  SScalarPropertyRequired = 'Propri�t� non-tableau requise';
  SDuplicateDefaultDirective = 'Directive default dupliqu�e';
  SArrayPropertyRequired = 'Propri�t� tableau requise';
  SDuplicateDefaultProperty = 'Ne peut avoir plusieurs propri�t�s par d�faut';
  SParametersMismatch = 'Les param�tres ne correspondent pas';

  // Erreurs sur les jump sp�ciaux
  SContinueAllowedOnlyInLoop =
    'L''instruction Continue n''est autoris�e que dans une boucle';
  SBreakAllowedOnlyInLoop =
    'L''instruction Break n''est autoris�e que dans une boucle';

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

