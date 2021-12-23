unit Util;

interface

uses Windows, Classes, ComCtrls, StdCtrls, SysUtils;

function ExtractName(path: string): string;
function ChangeExt(path: string; const newExt: string): string;
function GetWord(const s: string; p: integer; var w: string): integer;
function PadRight(const s: string; tolen: integer): string;

implementation

function ExtractName(path: string): string;
var
  p: integer;
begin
  p := Pos('>', path);
  if p <> 0 then
    path[p] := '\';
  Result := ExtractFileName(Path);
end;

function ChangeExt(path: string; const newExt: string): string;
var
  p: integer;
begin
  p := Pos('>', path);
  if p <> 0 then
    path[p] := '\';
  Result := ChangeFileExt(Path, newExt);
  if p <> 0 then
    Result[p] := '>';
end;

function GetWord(const s: string; p: integer; var w: string): integer;
var
  b, e: integer;
begin
  if s = '' then
  begin
    w      := '';
    Result := 1;
    exit;
  end;
  b := p;
  while (s[b] in [' ', #9]) and (b <= length(s)) do
    Inc(b);
  e := b;
  while (not (s[e] in [' ', #9])) and (e <= length(s)) do
    Inc(e);
  w := Copy(s, b, e - b);
  GetWord := e;
end;

function PadRight(const s: string; tolen: integer): string;
var
  i, len: integer;
begin
  Result := s;
  len    := length(Result);
  if len < tolen then
    SetLength(Result, toLen);
  for i := len + 1 to tolen do
    Result[i] := ' ';
end;


end.
