
// THIS INCLUDE FILE IS FOR FPC ONLY

{$IFDEF FPC}

 {$MODE DELPHI}
 {$ASMMODE INTEL}

// TODO - CHECK COMPILER DIRECTIVES

// GENERAL COMPILER DIRECTIVES
 {$H+}   {+ Use ANSI LongStrings }
 {$T+}   {+ Typed @ operator }

// DEBUGGING VERSION
{$IFDEF DEBUG_SEPI}
 {$Q+}  {+ Overflow-Checking }
 {$R+}  {+ Range-Checking }
 {$O-}  {- Optimisation }
 {$D+}  {+ Debug info }

// RELEASE VERSION
{$ELSE}
 {$B-}  {- Complete Boolean Evaluation }
 {$Q-}  {- Overflow-Checking }
 {$R-}  {- Range-Checking }
 {$V-}  {- Var-String Checking }
 {$T-}  {- Typed @ operator }
 {$X+}  {+ Extended syntax }
 {$P+}  {+ Open string params }
 {$O+}  {+ Optimisation }
{$ENDIF}

{$ENDIF}

