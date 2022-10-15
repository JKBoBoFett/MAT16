unit CNDHeaders;

interface

type
// Tranlated from ProjectMarduk:
// https://github.com/smlu/ProjectMarduk

 Tfog  = record
  enabled:Integer;
  color:array[0..4] of Single; //rgba
  startDepth:Single;
  endDepth:Single;
 end;

 TColorFormat = record
   colorMode:Integer; // RGB565 = 1, RGBA4444 = 2
   bpp:Integer; // Bit depth per pixel

   redBPP:Integer;
   greenBPP:Integer;
   blueBPP:Integer;

   RedShl:Integer;
   GreenShl:Integer;
   BlueShl:Integer;

   RedShr:Integer;
   GreenShr:Integer;
   BlueShr:Integer;

   alphaBPP:Integer;
   AlphaShl:Integer;
   AlphaShr:Integer;
 end;

 TCndHeader = record
   fileSize:Cardinal;
   copyright:array[0..1216] of AnsiChar;
   filePath:array[0..64] of AnsiChar;
   cnddtype:Cardinal;
   version:Cardinal;
   worldGravity:Single;
   ceilingSky_Z:Single;
   horizonDistance:Single;
   horizonSkyOffset:array[0..2] of Single; // x,y
   ceilingSkyOffset:array[0..2] of Single; // x,y
   LOD_Distances:array[0..4] of Single;
   fog:Tfog;
   unknown2:Cardinal;
   numMaterials:Cardinal;
   sizeMaterials:Cardinal;
   aMaterials:Cardinal;     // 32-bit void*
   unknown4:array[0..13] of Cardinal;
   aSelectors:Cardinal;
   unknown5:Cardinal;
   worldAIClasses:Cardinal;
   unknown6:array[0..2] of Cardinal;
   numModels:Cardinal;
   sizeModels:Cardinal;
   aModels:Cardinal;
   numSprites:Cardinal;
   sizeSprites:Cardinal;
   aSprites:Cardinal;      // 32-bit void*
   numKeyframes:Cardinal;
   sizeKeyframes:Cardinal;
   aKeyframes:Cardinal;    // 32-bit void*
   unknown9:array[0..20] of Cardinal;
   worldSounds:Cardinal;
   worldSoundUnknown:Cardinal; // Size of sound data
 end;

   TCndMatHeader = record
   name: array[0..64] of AnsiChar;
   width:Integer;
   height:Integer;
   mipmapCount:Integer;
   texturesPerMipmap:Integer;
   ColorFormat:TColorFormat
   end;

implementation

end.
