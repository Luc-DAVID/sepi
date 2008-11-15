unit SDCConsts;

interface

resourcestring
  // Compiler errors
  SCantFindSourceFile = 'Le fichier source %s n''existe pas';
  SCantOpenSourceFile = 'Impossible de cr�er le fichier source %s';
  SCantOpenDestFile = 'Impossible de cr�er le fichier de sortie %s';
  SSepiInternalError = 'Erreur interne : %s';
  SCantCompileRCFile = 'Ne peut compiler le fichier de ressources %s';

  // Options errors
  SOneOrMoreFileNamesRequired = 'Un argument ou plus requis';

const // don't localize
  DefaultOutputDir = 'Output\';

const // don't localize
  PascalExt = '.pas';
  CompiledIntfExt = '.sci';
  CompiledUnitExt = '.scu';
  RCExt = '.rc';
  TextExt = '.txt';
  MaxSizeBeforeLazyLoad = 100*1024;

implementation

end.

