unit Color16;

interface
   uses Windows,Graphics, SysUtils, Classes,MatHeaders;

 Type
   TColor16 = Record

    rgba: word;
    a: byte;
    r: byte;
    g: byte;
    b: byte;

    constructor Create(r: byte;g: byte;b: byte;a: byte;matFormatHeader:TMatHeader);

  end;

implementation

 constructor TColor16.Create(r: byte;g: byte;b: byte;a: byte;matFormatHeader:TMatHeader);
 begin
    self.rgba:=0;
    self.a :=a;
    self.r :=r;
    self.g :=g;
    self.b :=b;

    self.rgba:= self.r shl matFormatHeader.shiftR
             or self.g shl matFormatHeader.shiftG
             or self.b shl matFormatHeader.shiftB
             or self.a shl matFormatHeader.alpha_sh;

 end;
end.
