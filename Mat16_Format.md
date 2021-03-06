<h1>BoBo Fetts 16-bit mat specs</h1>
Oct 31,2021<br><br>  


Known 16-bit mat formats supported by JediKnight:    

565 RGB:  
![565](/img/565Format.png "565 Format")  
     
1555 ARGB (Enabled when TransparentBool =1):     
![1555](/img/1555Format.png "1555 Format")    

Straight from the Code Alliance file specs:  
MAT files contain image information. This could be solid colors(8-bit format) or textures, there could be several textures  
or colors in one file(cells). The textures are of the mip-map type. That is one larger texture with several more  
smaller ones each with less detail. These are used to change the detail of the textures shown to the player by the engine.  
This is a function of distance as specified in the JKL Section: Header /Mipmap Distances.  
The file is structured in 2 parts if the MAT is a color one, or 3 parts, if it is a texture one.   

Note: The following code is in Delphi format

The header for a 16-bit mat is:  

    TMatHeader = record
      tag:array[0..3] of ANSIchar;  // 'MAT ' - notice space after MAT
      ver:Longint;                  // Apparently - version = 0x32 ('2')
      mat_Type:Longint;             // 0 = 8 bit colors uses (TColorHeader) , 1= ?, 2= texture uses (TTextureHeader),3= includes palette dump at end of file
      record_count:Longint;         // record_count {number of textures or colors
      cel_count: Longint;           // cel_count { In color MATs, it's 0, in TX ones, it's equal to numOfTextures
      ColorMode:Longint;            // {ColorMode, Indexed = 0  RGB = 1 RGBA = 2
      bits:LongInt;                 //  = 16  {bits/pixel}

      redbits:longint;              // {red bits per pixel}   {ignored by game engine}  
      greenbits:longint;            // {green bits per pixel} {ignored by game engine}  
      bluebits:longint;             // {blue bits per pixel}  {ignored by game engine}  

      shiftR:longint;               // bit index to red color channel, shift left during conversion {ignored by game engine}  
      shiftG:longint;               // bit index to green color channel, shift left during conversion {ignored by game engine}  
      shiftB:longint;               // bit index to blue color channel, shift left during conversion {ignored by game engine}  

      RedBitDif: longint;           // bits shifted right during conversion from 8bit to 5bit  {ignored by game engine}  
      GreenBitDif: longint;         // bits shifted right during conversion from 8bit to 6bit  {ignored by game engine}  
      BlueBitDif: longint;          // bits shifted right during conversion from 8bit to 5bit  {ignored by game engine}  

      alpha_bpp:longint;            // {ignored by game engine}  
      alpha_sh:longint;             // shift left during conversion {ignored by game engine}  
      alpha_BitDif:longint;         // shifted right during conversion {ignored by game engine}  
    end;  

    // Used in solid color 8bit indexed mats only  
    // Depending on the Type in TMatHeader there will be either record_count*TColorHeader or record_count*TTextureHeader  
    TColorHeader = record  
      textype:longint;                 // {0 = color}  
      colornum:longint;                // {Color index from the CMP palette}  
      pads:array[0..3] of longint;     // {each = 0x3F800000 (check cmp header )}  
    end;  

    TTextureHeader = record  
      textype: longint;                   // { 8= texture}  
      transparent_color : longint;        // {unknown use}  
      pads: array[0..2] of longint;  
      unk1tha: word;                      // {ignored by game engine}  
      unk1thb: word;  
      unk2th: longint;                    //=0  
      unk3th: longint;                    // {ignored by game engine}  
      unk4th: longint;                    // {ignored by game engine}  
      cel_idx: longint;                   //=0 for first texture. Inc. for every texture in mat  
    end;  

    // Not Used in solid color 8bit indexed mats  
    TTextureMipmapHeader = record  
      SizeX: longint;                   // {horizontal size of first MipMap, must be divisable by 2}  
      SizeY: longint;                   // {Vertical size of first MipMap ,must be divisable by 2}  
      TransparentBool: longint;         // {1: transparent on, else 0: transparent off, in 16-bit enables ARGB1555}  
      Pad: array[0..1] of longint;      // {padding = 0 }  
      NumMipMaps: longint;              // {Number of mipmaps in texture largest one first.}  
    end;  
    // For each texture(Cell), the TTextureMipmapHeader is followed by actual texture data. The graphics are uncompressed; the top left corner is the start;  
    // lines are read first. The main texture is directly followed by the sub MipMaps(MipMipMaps-1).  
    // SubMipMaps other then the largest first one are not used in transparent/Alpha or multicelled mats(MipMipMaps=1).  
    
    TCMPPal = array[0..255] of record r, g, b: byte;  end; //palette dump, used only in type 3 mats
