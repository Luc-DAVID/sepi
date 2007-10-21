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
  D�finit les constantes g�n�rales de Sepi
  @author sjrd
  @version 1.0
*}
unit SepiConsts;

interface

const
  SepiMajVersion = 1; /// Version majeure de Sepi
  SepiMinVersion = 0; /// Version mineure de Sepi

  /// Dossier racine de Sepi dans la base de registre
  regSepiBase = '\Software\SJRDoeraene\Sepi\'; {don't localize}

resourcestring
  sSepiName = 'Projet Sepi';
  sSepiAuthor = 'L''�quipe Sepi';
  sSepiAuthorEMail = 'sjrd@redaction-developpez.com';
  sSepiWebSite = 'http://sjrd.developpez.com/sepi/';
  sSepiCopyright = 'Sepi v%d.%d - Copyright � 2005-2006 SJRDoeraene';
  sSepiAbout = '� propos de Sepi';

  sSepiInstanceAlreadyExists = 'Seule une instance de TSepi peut �tre cr��e';
  sSepiDifferentVersion =
    'Versions majeures diff�rentes : incompatibilit� de format';
  sSepiUnexistingFile = 'Le fichier sp�cifi� n''existe pas';

implementation

end.

