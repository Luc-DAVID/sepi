{*
  D�finit quelques routines de dates et heures
  @author S�bastien Jean Robert Doeraene
  @version 1.0
*}
unit ScDateTimeUtils;

interface

function GetMonthName(Month : integer; Maj : boolean = True) : string;
// Revoie le nom du mois Month (1 pour Janvier).
// Maj d�termine s'il y a une majuscule

implementation

function GetMonthName(Month : integer; Maj : boolean = True) : string;
begin
  case Month of
    1 : Result := 'janvier';
    2 : Result := 'f�vrier';
    3 : Result := 'mars';
    4 : Result := 'avril';
    5 : Result := 'mai';
    6 : Result := 'juin';
    7 : Result := 'juillet';
    8 : Result := 'ao�t';
    9 : Result := 'septembre';
    10 : Result := 'octobre';
    11 : Result := 'novembre';
    12 : Result := 'd�cembre';
    else Result := '';
  end;
  if Maj and (Result <> '') then
    dec(Result[1], 32);
end;

end.

