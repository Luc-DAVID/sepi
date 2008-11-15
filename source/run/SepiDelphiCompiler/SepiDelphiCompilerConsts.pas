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
  SReturnTypeRequired = 'La fonction exige un type de retour';
  SReturnTypeForbidden = 'La proc�dure ne peut avoir de type de retour';
  SOpenArrayParamCantHaveDefaultValue =
    'Un param�tre tableau ouvert ne peut pas avoir de valeur par d�faut';
  SMultiNameParamCantHaveDefaultValue =
    'Une d�finition de plusieurs param�tres ne peut pas avoir de valeur par '+
    'd�faut';
  SDuplicateModifier = 'Modificateur %s dupliqu�';
  SPropertyNotFoundInBaseClass =
    'La propri�t� n''a pas �t� trouv�e dans la classe de base';
  SFieldOrMethodRequired = 'Champ ou m�thode requis';
  SParametersMismatch = 'Les param�tres ne correspondent pas';
  SArrayOrArrayPropRequired = 'Valeur tableau ou propri�t� tableau requise';
  STooManyArrayIndices = 'Trop d''index pour ce tableau';
  SMethodNotDeclared = 'M�thode %s non d�clar�e';
  SMethodMustBeOverloaded =
    'La m�thode %s doit �tre marqu�e avec la directive overload';
  SPreviousDeclWasNotOverload =
    'La d�claration pr�c�dente de %s n''a pas �t� marqu�e avec la directive '+
    'overload';
  SDeclarationDiffersFromPreviousOne =
    'La d�claration de %s diff�re de la d�claration pr�c�dente';
  SMethodAlreadyImplemented = 'La m�thode %s a d�j� �t� impl�ment�e';
  SLocalVarNameRequired = 'Variable locale requise';

const
  /// Nom des types de liaison de m�thodes
  LinkKindNames: array[TMethodLinkKind] of string = (
    '', 'virtual', 'dynamic', 'message', '', 'override'
  );

  /// Nom des conventions d'appel
  CallingConventionNames: array[TCallingConvention] of string = (
    'register', 'cdecl', 'pascal', 'stdcall', 'safecall'
  );

  /// Nom des visibilit�s
  Visibilities: array[TMemberVisibility] of string = (
    'strict private', 'private', 'strict protected', 'protected', 'public',
    'published'
  );

implementation

end.

