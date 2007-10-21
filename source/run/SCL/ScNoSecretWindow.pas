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
  Emp�che la cr�ation par Delphi de sa fen�tre secr�te
  Ins�rez cette unit� en toute premi�re position de la clause uses de l'unit�
  program (avant Forms). Vous vous d�barrasserez ainsi de la fen�tre secr�te.
  @author sjrd
  @version 1.0
*}
unit ScNoSecretWindow;

interface

implementation

initialization
  // Simule une DLL
  IsLibrary := True;
end.

