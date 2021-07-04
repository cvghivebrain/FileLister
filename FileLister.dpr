program FileLister;

{$APPTYPE CONSOLE}

uses
  Windows, SysUtils, StrUtils;

var
  outfile: textfile;
  rec: TSearchRec;
  s, t: string;
  u: TSystemTime;
  a, b: integer;
  folders: array of string;
  crctable: array[0..255] of longint;
  datafile: file;
  dataarray: array of byte;

label endnow;

  { Functions. }

{ Left rotate bits in longword. }
function rol(l: longword; i: integer): longword;
begin
  Result := (l shl i)+(l shr (32-i));
end;

{ Get CRC of data in array. }
function CRCData: string;
var i, x: integer;
  r: longint;
begin
  r := -1;
  for i := 0 to Length(dataarray)-1 do
    begin
    x := (dataarray[i] xor r) and $FF;
    r := (r shr 8) xor crctable[x];
    end;
  Result := AnsiLowerCase(InttoHex(not r,8));
end;

{ Get CRC32 of file. }
function CRCFile(fi: string): string;
begin
  { Open file and copy to array. }
  AssignFile(datafile,fi); // Get file.
  FileMode := fmOpenRead; // Read only.
  Reset(datafile,1);
  SetLength(dataarray,FileSize(datafile));
  BlockRead(datafile,dataarray[0],FileSize(datafile)); // Copy file to memory.
  CloseFile(datafile); // Close file.

  Result := CRCData();
end;

{ Get SHA-1 of data in array. }
function SHA1Data: string;
var h0,h1,h2,h3,h4,aa,bb,c,d,e,f,k,tt: longword;
  w: array[0..79] of longword;
  i, j: integer;
begin
  h0 := $67452301; // Initialise variables.
  h1 := $EFCDAB89;
  h2 := $98BADCFE;
  h3 := $10325476;
  h4 := $C3D2E1F0;
  for j := 0 to ((Length(dataarray) div 64)-1) do
    begin
    for i := 0 to 15 do // Copy chunk into array.
      w[i] := (dataarray[(j*64)+(i*4)] shl 24)+(dataarray[(j*64)+(i*4)+1] shl 16)+(dataarray[(j*64)+(i*4)+2] shl 8)+dataarray[(j*64)+(i*4)+3];
    for i := 16 to 79 do // Extend chunk data.
      w[i] := rol((w[i-3] xor w[i-8] xor w[i-14] xor w[i-16]),1);
    aa := h0;
    bb := h1;
    c := h2;
    d := h3;
    e := h4;
    for i := 0 to 79 do
      begin
      if i < 20 then
        begin
        f := (bb and c) or ((not bb) and d);
        k := $5A827999;
        end
      else if i < 40 then
        begin
        f := bb xor c xor d;
        k := $6ED9EBA1;
        end
      else if i < 60 then
        begin
        f := (bb and c) or (bb and d) or (c and d);
        k := $8F1BBCDC;
        end
      else
        begin
        f := bb xor c xor d;
        k := $CA62C1D6;
        end;
      tt := rol(aa,5) + f + e + k + w[i];
      e := d;
      d := c;
      c := rol(bb,30);
      bb := aa;
      aa := tt;
      end;
    h0 := h0 + aa; // Add chunk result.
    h1 := h1 + bb;
    h2 := h2 + c;
    h3 := h3 + d;
    h4 := h4 + e;
    end;

  Result := AnsiLowerCase(InttoHex(h0)+InttoHex(h1)+InttoHex(h2)+InttoHex(h3)+InttoHex(h4));
end;

{ Get SHA-1 of file. }
function SHA1File(fi: string): string;
var i: integer;
  ml: int64;
begin
  { Open file and copy to array. }
  AssignFile(datafile,fi); // Get file.
  FileMode := fmOpenRead; // Read only.
  Reset(datafile,1);
  SetLength(dataarray,FileSize(datafile)+9+64-((FileSize(datafile)+9) mod 64)); // Pad data to multiple of 64.
  BlockRead(datafile,dataarray[0],FileSize(datafile)); // Copy file to array.
  dataarray[FileSize(datafile)] := $80;
  ml := FileSize(datafile)*8; // File size in bits.
  for i := 0 to 7 do
    dataarray[Length(dataarray)-1-i] := (ml shr (i*8)) and $ff; // Copy ml to end of array.
  CloseFile(datafile); // Close file.

  Result := SHA1Data();
end;


  { Program start. }
begin

  if ParamStr(1) = '' then goto endnow; // End program if run without parameters.

  { Create CRC32 lookup table. }
  for a := 0 to 255 do
    begin
    crctable[a] := a;
    for b := 0 to 7 do if Odd(crctable[a]) then
      crctable[a] := (crctable[a] shr 1) xor $EDB88320
      else crctable[a] := crctable[a] shr 1;
    end;

  { Generate a list of all folders (and subfolders) in folders array. }
  SetLength(folders,1);
  a := 0;
  while a < Length(folders) do
    begin
    if (FindFirst(ParamStr(1)+'\'+folders[a]+'*.*', faDirectory, rec) = 0) then
      begin
      repeat
      if (rec.Name<>'.') and (rec.Name<>'..') and ((rec.attr and faDirectory)=faDirectory) then
        begin
        SetLength(folders,Length(folders)+1); // add 1 slot for folder name.
        folders[Length(folders)-1] := folders[a]+rec.Name+'\'; // add folder name to array.
        end;
      until FindNext(rec) <>0;
      FindClose(rec);
      end;
    inc(a);
    end;

  AssignFile(outfile,ParamStr(2));
  ReWrite(outfile); // open output file (read/write)

  //WriteLn(outfile, ParamStr(1));
  //WriteLn(outfile, inttostr(Length(folders)));
  //for a := 0 to Length(folders)-1 do WriteLn(outfile, folders[a]);

  for a := 0 to Length(folders)-1 do
    begin
    if FindFirst(ParamStr(1)+'\'+folders[a]+'*.*', faAnyFile-faDirectory, rec) = 0 then
      begin
      repeat
        begin
        s := ReplaceStr(ParamStr(3),'##','hashgoeshere'); // Replace ## with temp string.
        s := ReplaceStr(s,'#name',rec.Name); // replace #name with file name.
        t := ExtractFileExt(rec.Name);
        Delete(t,1,1);
        s := ReplaceStr(s,'#ext',t); // replace #ext with file extension.
        s := ReplaceStr(s,'#folder',folders[a]); // replace #folder with folder name.
        s := ReplaceStr(s,'#size',inttostr(rec.Size)); // replace #size with file size.
        t := DateToStr(FileDateToDateTime(rec.Time));
        t := copy(t,7,4)+'-'+copy(t,4,2)+'-'+copy(t,1,2);
        s := ReplaceStr(s,'#date',t); // replace #date with date last modified.
        FileTimeToSystemTime(rec.FindData.ftCreationTime,u);
        t := DateToStr(SystemTimeToDateTime(u));
        t := copy(t,7,4)+'-'+copy(t,4,2)+'-'+copy(t,1,2);
        s := ReplaceStr(s,'#created',t); // replace #created with creation date.
        if AnsiPos('#crc32',s) <> 0 then
          begin
          t := CRCFile(ParamStr(1)+'\'+folders[a]+rec.Name);
          s := ReplaceStr(s,'#crc32',t); // replace #crc32 with CRC32.
          end;
        if AnsiPos('#sha1',s) <> 0 then
          begin
          t := SHA1File(ParamStr(1)+'\'+folders[a]+rec.Name);
          s := ReplaceStr(s,'#sha1',t); // replace #sha1 with SHA-1.
          end;

        s := ReplaceStr(s,'#percent','%'); // Replace #percent string with %.
        s := ReplaceStr(s,'#qm','"'); // Replace #qm string with ".
        s := ReplaceStr(s,'hashgoeshere','#'); // Replace temp string with #.
        WriteLn(outfile, s); // Write final string to text file.
        end;
      until FindNext(rec) <> 0;
      FindClose(rec);
      end;
    end;

  CloseFile(outfile);
  endnow:
end.