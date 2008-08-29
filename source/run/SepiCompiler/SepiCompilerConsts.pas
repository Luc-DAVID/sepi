unit SepiCompilerConsts;

interface

resourcestring
  // Format des erreurs
  SSepiHintName = 'Conseil';
  SSepiWarningName = 'Avertissement';
  SSepiErrorName = 'Erreur';
  SSepiFatalErrorName = 'Erreur fatale';
  SSepiCompilerErrorFormat = '[%s] %s(%d) : %4:s';

  // Erreurs de compilation g�n�riques
  SSepiThereWereErrors = 'Il y a eu des erreurs � la compilation';
  SIdentifier = 'Identificateur';
  SRedeclaredIdentifier = 'Identificateur red�clar�';
  SIdentifierNotFound = 'Identificateur %s non d�clar�';
  STypeMismatch = 'Types incompatibles : %s attendu mais %s trouv�';
  SNeedConstExpression = 'Expression constante attendue';

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

  // Erreurs d'instructions assembleur
  SMultipleParamsWithSameSepiStackOffset =
    'Plusieurs param�tres ont la m�me valeur de SepiStackOffset';
  SParamsSepiStackOffsetsDontFollow =
    'Les SepiStackOffset des param�tres ne se suivent pas';
  SInvalidDataSize = 'Taille de donn�es invalide';
  SObjectMustHaveASignature = 'L''objet %s n''a pas de signature';

implementation

end.

