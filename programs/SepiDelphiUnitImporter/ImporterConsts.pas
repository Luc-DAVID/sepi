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
  Constantes de l'importeur
  @author sjrd
  @version 1.0
*}
unit ImporterConsts;

interface

resourcestring
  // Context errors
  SBDSVersionNotInstalled = 'La version %s de BDS n''est pas install�e';
  SBDSVendorVersionNotInstalled =
    'La version %1:s de BDS de %0:s n''est pas install�e';

  // Options errors
  SOneOrMoreFileNamesRequired = 'Un argument ou plus requis';

  // Importer errors
  SCantFindProgram = 'Ne peut trouver le programme externe %s';
  SCantFindSourceFile = 'Le fichier source %s n''existe pas';
  SCantOpenSourceFile = 'Impossible de cr�er le fichier source %s';
  SBadlyFormedOverloadFile = 'Fichier d''overloading mal form�';
  SCantOpenDestFile = 'Impossible de cr�er le fichier de sortie %s';
  SSepiInternalError = 'Erreur interne : %s';
  SCantCompileRCFile = 'Ne peut compiler le fichier de ressources %s';

  // Warnings
  SOverloadHasMoreLinesThanOriginal =
    'L''overload contient plus de lignes que l''original : les num�ros de '+
    'ligne des erreurs seront probablement fauss�s.';

const // don't localize
  PascalExt = '.pas';
  CompiledIntfExt = '.sci';
  RCExt = '.rc';
  MaxSizeBeforeLazyLoad = 100*1024;

  DefaultTemplatesDir = 'Templates\';
  DefaultCacheDir = 'Cache\';

implementation

end.

