unit TesseractOCR;

{ The MIT License (MIT)

  TTesseractOCR5
  Copyright (c) 2018 Damian Woroch, http://rime.ddns.net/

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE. }
interface

uses
{$IFNDEF FPC}
  System.Classes,
  System.Types,
  System.SysUtils,
  System.IOUtils,
  System.Math,
  Vcl.Graphics,
  Vcl.Imaging.pngimage,
{$ELSE}
  Classes,
  Types,
  SysUtils,
  Math,
  Graphics,
{$ENDIF}
  TesseractOCR.Consts,
  TesseractOCR.CAPI,
  TesseractOCR.Leptonica,
  TesseractOCR.Utils,
  TesseractOCR.PageLayout;

type
  TOcrEngineMode = (oemTesseractOnly, oemLSTMOnly, oemTesseractLSTMCombined, oemDefault);

type
  TRecognizerProgressEvent = procedure(Sender: TObject; AProgress: Integer; var ACancel: Boolean) of object;
  TRecognizerEndEvent = procedure(Sender: TObject; ACanceled: Boolean) of object;

type
  TTesseractOCR5 = class(TObject)
  type
    TRecognizerThread = class(TThread)
    protected
      FOwner: TTesseractOCR5;
      procedure Execute; override;
    public
      constructor Create(AOwner: TTesseractOCR5);
    end;
  protected
    FDataPath: string;
    FProgressMonitor: ETEXT_DESC;
    FRecognizerThread: TRecognizerThread;
    FSourcePixImage: PPix;
    FTessBaseAPI: TessBaseAPI;
    procedure RecognizeInternal;
  private
    FBusy: Boolean;
    FHOCRText: string;
    FLayoutAnalyse: Boolean;
    FOnRecognizeBegin: TNotifyEvent;
    FOnRecognizeEnd: TRecognizerEndEvent;
    FOnRecognizeProgress: TRecognizerProgressEvent;
    FPageLayout: TTesseractPageLayout;
    FProgress: Integer;
    FUTF8Text: string;
    function GetPageSegMode: TessPageSegMode;
    procedure SetPageSegMode(APageSegMode: TessPageSegMode);
    procedure SynchronizeProgress;
    procedure SynchronizeBegin;
    procedure SynchronizeEnd;
  public
    // Initializes Tesseract
    function Initialize(ADataPath, ALanguage: string; AEngineMode: TOcrEngineMode = oemDefault): Boolean;
    // Read configuration file
    procedure ReadConfigFile(AFileName: string);
    // Read/write configuration variables
    function SetVariable(AName: string; AValue: string): Boolean;
    function GetIntVariable(AName: string): Integer;
    function GetBoolVariable(AName: string): Boolean;
    function GetFloatVariable(AName: string): Double;
    function GetStringVariable(AName: string): string;
    // Returns True if language is loaded
    function IsLanguageLoaded(ALanguage: string): Boolean;
    // Set source image from a file (uses Leptonica library)
    function SetImage(AFileName: string): Boolean; overload;
    // Set source image from a TBitmap
    function SetImage(const ABitmap: {$IFNDEF FPC}Vcl.Graphics.{$ENDIF}TBitmap): Boolean; overload;
    // Set source image from a memory buffer
    function SetImage(const ABuffer: Pointer; AImageWidth, AImageHeight: Integer; ABytesPerPixel: Integer;
      ABytesPerLine: Integer): Boolean; overload;
    // Deskew source image
    procedure DeskewSourceImage;
    // Limit recognition area
    procedure SetRectangle(ARectangle: TRect);
    // Set source image PPI
    procedure SetSourceResolution(APPI: Integer);
    // Get source image as TPNGImage
    function GetSourceImagePNG: {$IFNDEF FPC}Vcl.Imaging.pngimage.TPngImage{$ELSE}TPortableNetworkGraphic{$ENDIF};
    // Get source image as TBitmap
    function GetSourceImageBMP: {$IFNDEF FPC}Vcl.Graphics.{$ENDIF}TBitmap;
    // Perform OCR and layout analyse. Will create a separate thread if AInThread
    // is set to True (default)
    procedure Recognize(AUseThread: Boolean = True);
    // Perform OCR and return UTF-8 text (without layout analyse)
    function RecognizeAsText: string;
    // Cancel current recognize operation
    procedure CancelRecognize;
    // Creates PDF file (source image and searchable text)
    function CreatePDF(ASourceFileName: string; AOutputFileName: string): Boolean;
    // Get/set page segmentation mode
    property PageSegMode: TessPageSegMode read GetPageSegMode write SetPageSegMode;
    // True if OCR'ing
    property Busy: Boolean read FBusy;
    // OCR progress (0-100)
    property Progress: Integer read FProgress write FProgress;
    // Recognized text coded as UTF-8
    property UTF8Text: string read FUTF8Text write FUTF8Text;
    // Recognized text in HTML format
    property HOCRText: string read FHOCRText write FHOCRText;
    // Result of page layout analysis
    property pagelayout: TTesseractPageLayout read FPageLayout;
    // Events
    property OnRecognizeBegin: TNotifyEvent read FOnRecognizeBegin write FOnRecognizeBegin;
    property OnRecognizeProgress: TRecognizerProgressEvent read FOnRecognizeProgress write FOnRecognizeProgress;
    property OnRecognizeEnd: TRecognizerEndEvent read FOnRecognizeEnd write FOnRecognizeEnd;
    constructor Create;
    destructor Destroy; override;
  end;

var
  Tesseract: TTesseractOCR5 = nil;

implementation

var
  CancelOCR: Boolean;

{ TTesseractOCR5 }

constructor TTesseractOCR5.Create;
begin
  if not InitTesseractLib then
    raise Exception.Create('Tesseract library is not loaded');
  if not InitLeptonicaLib then
    raise Exception.Create('Leptonica library is not loaded');
  FTessBaseAPI := TessBaseAPICreate();
  FPageLayout := TTesseractPageLayout.Create(FTessBaseAPI);
end;

destructor TTesseractOCR5.Destroy;
begin
  if FBusy then
  begin
    CancelRecognize;
    FRecognizerThread.WaitFor;
  end;
  if Assigned(FTessBaseAPI) then
  begin
    TessBaseAPIEnd(FTessBaseAPI);
    TessBaseAPIDelete(FTessBaseAPI);
  end;
  if Assigned(FSourcePixImage) then
  begin
    pixDestroy(FSourcePixImage);
    FSourcePixImage := nil;
  end;
  if Assigned(FPageLayout) then
    FPageLayout.Free;
  FreeTesseractLib;
  FreeLeptonicaLib;
  inherited Destroy;
end;

function TTesseractOCR5.Initialize(ADataPath, ALanguage: string; AEngineMode: TOcrEngineMode): Boolean;
begin
  Result := False;
  if Assigned(FTessBaseAPI) then
  begin
    FDataPath := ADataPath;
    Result := TessBaseAPIInit2(FTessBaseAPI, PUTF8Char(UTF8Encode(FDataPath)), PUTF8Char(UTF8Encode(ALanguage)),
      TessOcrEngineMode(AEngineMode)) = 0;
  end;
end;

procedure TTesseractOCR5.ReadConfigFile(AFileName: string);
begin
  TessBaseAPIReadConfigFile(FTessBaseAPI, PUTF8Char(UTF8Encode(AFileName)));
end;

function TTesseractOCR5.SetVariable(AName: string; AValue: string): Boolean;
begin
  Result := TessBaseAPISetVariable(FTessBaseAPI, PUTF8Char(UTF8Encode(AName)), PUTF8Char(UTF8Encode(AValue)));
end;

function TTesseractOCR5.GetIntVariable(AName: string): Integer;
begin
  Result := 0;
  TessBaseAPIGetIntVariable(FTessBaseAPI, PUTF8Char(UTF8Encode(AName)), Result);
end;

function TTesseractOCR5.GetBoolVariable(AName: string): Boolean;
var
  val: LongBool;
begin
  Result := False;
  if TessBaseAPIGetBoolVariable(FTessBaseAPI, PUTF8Char(UTF8Encode(AName)), val) then
    Result := val;
end;

function TTesseractOCR5.GetFloatVariable(AName: string): Double;
begin
  Result := 0;
  TessBaseAPIGetDoubleVariable(FTessBaseAPI, PUTF8Char(UTF8Encode(AName)), Result);
end;

function TTesseractOCR5.GetStringVariable(AName: string): string;
begin
  Result := PUTF8CharToString(TessBaseAPIGetStringVariable(FTessBaseAPI, PUTF8Char(UTF8Encode(AName))));
end;

function TTesseractOCR5.IsLanguageLoaded(ALanguage: string): Boolean;
type
  TUTF8Arr = array [0 .. 0] of PUTF8Char;
  PUTF8Arr = ^TUTF8Arr;
var
  arr: PUTF8Arr;
  lang: UTF8String;
  i: Integer;
begin
  Result := False;
  arr := PUTF8Arr(TessBaseAPIGetLoadedLanguagesAsVector(FTessBaseAPI));
  if not Assigned(arr) then
    Exit;
  i := 0;
  repeat
    SetString(lang, PUTF8Char(arr[i]), Length(arr[i]));
    if (lang = UTF8String(ALanguage)) then
    begin
      Result := True;
      Exit;
    end;
    Inc(i);
  until not Assigned(Pointer(arr[i]));
end;

procedure TTesseractOCR5.SetRectangle(ARectangle: TRect);
begin
  if FBusy then
    Exit;
  TessBaseAPISetRectangle(FTessBaseAPI, ARectangle.Left, ARectangle.Top, ARectangle.Right - ARectangle.Left,
    ARectangle.Bottom - ARectangle.Top);
end;

procedure TTesseractOCR5.SetSourceResolution(APPI: Integer);
begin
  if FBusy then
    Exit;
  TessBaseAPISetSourceResolution(FTessBaseAPI, APPI);
end;

function TTesseractOCR5.GetPageSegMode: TessPageSegMode;
begin
  Result := TessBaseAPIGetPageSegMode(FTessBaseAPI);
end;

procedure TTesseractOCR5.SetPageSegMode(APageSegMode: TessPageSegMode);
begin
  if FBusy then
    Exit;
  TessBaseAPISetPageSegMode(FTessBaseAPI, APageSegMode);
end;

function TTesseractOCR5.SetImage(AFileName: string): Boolean;
begin
  Result := False;
  if FBusy then
    Exit;
  if Assigned(FSourcePixImage) then
  begin
    pixDestroy(FSourcePixImage);
    FSourcePixImage := nil;
  end;
  FSourcePixImage := pixRead(PUTF8Char(UTF8Encode(AFileName)));
  if Assigned(FSourcePixImage) then
  begin
    TessBaseAPISetImage2(FTessBaseAPI, FSourcePixImage);
    Result := True;
  end;
end;

function TTesseractOCR5.SetImage(const ABitmap: {$IFNDEF FPC}Vcl.Graphics.{$ENDIF}TBitmap): Boolean;
var
  msSourceImage: TMemoryStream;
begin
  Result := False;
  if FBusy then
    Exit;
  if Assigned(FSourcePixImage) then
  begin
    pixDestroy(FSourcePixImage);
    FSourcePixImage := nil;
  end;
  msSourceImage := TMemoryStream.Create;
  try
    ABitmap.SaveToStream(msSourceImage);
    FSourcePixImage := pixReadMem(msSourceImage.Memory, msSourceImage.Size);
    if Assigned(FSourcePixImage) then
    begin
      TessBaseAPISetImage2(FTessBaseAPI, FSourcePixImage);
      Result := True;
    end;
  finally
    msSourceImage.Free;
  end;
end;

function TTesseractOCR5.SetImage(const ABuffer: Pointer; AImageWidth, AImageHeight: Integer; ABytesPerPixel: Integer;
  ABytesPerLine: Integer): Boolean;
begin
  Result := False;
  if FBusy then
    Exit;
  if Assigned(ABuffer) then
  begin
    TessBaseAPISetImage(FTessBaseAPI, ABuffer, AImageWidth, AImageHeight, ABytesPerPixel, ABytesPerLine);
    Result := True;
  end;
end;

procedure TTesseractOCR5.DeskewSourceImage;
var
  deskewedImage: PPix;
begin
  if Assigned(FSourcePixImage) then
  begin
    deskewedImage := pixDeskew(FSourcePixImage, 0);
    if Assigned(deskewedImage) then
    begin
      pixDestroy(FSourcePixImage);
      FSourcePixImage := deskewedImage;
      TessBaseAPISetImage2(FTessBaseAPI, FSourcePixImage);
    end;
  end;
end;

function TTesseractOCR5.GetSourceImagePNG:
{$IFNDEF FPC}Vcl.Imaging.pngimage.TPngImage{$ELSE}TPortableNetworkGraphic{$ENDIF};
var
  pSourceImg: PPix;
  pSourceImagePng: pl_uint8;
  ms: TMemoryStream;
  buffSize: NativeInt;
begin
  Result := {$IFNDEF FPC}Vcl.Imaging.pngimage.TPngImage{$ELSE}TPortableNetworkGraphic{$ENDIF}.Create;
  pSourceImg := TessBaseAPIGetInputImage(FTessBaseAPI);
  if Assigned(pSourceImg) then
  begin
    if pixWriteMemPng(@pSourceImagePng, buffSize, pSourceImg, 0) = 0 then
    begin
      ms := TMemoryStream.Create;
      try
        ms.WriteBuffer(pSourceImagePng^, buffSize);
        ms.Position := 0;
        Result.LoadFromStream(ms);
      finally
        ms.Free;
      end;
      lept_free(pSourceImagePng);
    end;
  end;
end;

function TTesseractOCR5.GetSourceImageBMP: {$IFNDEF FPC}Vcl.Graphics.{$ENDIF}TBitmap;
var
  pSourceImg: PPix;
  pSourceImageBmp: pl_uint8;
  ms: TMemoryStream;
  buffSize: NativeInt;
begin
  Result := {$IFNDEF FPC}Vcl.Graphics.{$ENDIF}TBitmap.Create;
  pSourceImg := TessBaseAPIGetInputImage(FTessBaseAPI);
  if Assigned(pSourceImg) then
  begin
    if pixWriteMemBmp(@pSourceImageBmp, buffSize, pSourceImg) = 0 then
    begin
      ms := TMemoryStream.Create;
      try
        ms.WriteBuffer(pSourceImageBmp^, buffSize);
        ms.Position := 0;
        Result.LoadFromStream(ms);
      finally
        ms.Free;
      end;
      lept_free(pSourceImageBmp);
    end;
  end;
end;

procedure TTesseractOCR5.CancelRecognize;
begin
  if FBusy then
    CancelOCR := True;
end;

function CancelCallback(cancel_this: Pointer; words: Integer): Boolean; cdecl;
begin
  Result := CancelOCR;
end;

function ProgressCallback(Progress: Integer; Left, Right, Top, Bottom: Integer): Boolean; cdecl;
begin
  if Assigned(Tesseract.OnRecognizeProgress) then
  begin
    Tesseract.Progress := Progress;
    TThread.Synchronize(nil, {$IFDEF FPC}@{$ENDIF}Tesseract.SynchronizeProgress);
  end;
  Result := False;
end;

procedure TTesseractOCR5.SynchronizeProgress;
begin
  if Assigned(FOnRecognizeProgress) then
    OnRecognizeProgress(Self, FProgress, CancelOCR);
end;

procedure TTesseractOCR5.SynchronizeBegin;
begin
  if Assigned(FOnRecognizeBegin) then
    OnRecognizeBegin(Self);
end;

procedure TTesseractOCR5.SynchronizeEnd;
begin
  if Assigned(FOnRecognizeEnd) then
    OnRecognizeEnd(Self, CancelOCR);
end;

procedure TTesseractOCR5.RecognizeInternal;
var
  oldExceptionMask: TArithmeticExceptionMask;
begin
  FBusy := True;
  FillChar(FProgressMonitor, SizeOf(FProgressMonitor), #0);
  FProgressMonitor.cancel := @CancelCallback;
  FProgressMonitor.progress_callback := @ProgressCallback;
  CancelOCR := False;
  FUTF8Text := '';
  FHOCRText := '';
  TThread.Synchronize(nil, {$IFDEF FPC}@{$ENDIF}Tesseract.SynchronizeBegin);
  try
    oldExceptionMask := GetExceptionMask;
    SetExceptionMask(exAllArithmeticExceptions);
    if (TessBaseAPIRecognize(FTessBaseAPI, FProgressMonitor) = 0) then
    begin
      FUTF8Text := PUTF8CharToString(TessBaseAPIGetUTF8Text(FTessBaseAPI));
      FUTF8Text := StringReplace(FUTF8Text, #10, #13#10, [rfReplaceAll]);
      FHOCRText := PUTF8CharToString(TessBaseAPIGetHOCRText(FTessBaseAPI, 0));
      FHOCRText := StringReplace(FHOCRText, #10, #13#10, [rfReplaceAll]);
      if FLayoutAnalyse then
        FPageLayout.AnalyseLayout;
    end
    else
      Exit;
  finally
    SetExceptionMask(oldExceptionMask);
    FBusy := False;
    TThread.Synchronize(nil, {$IFDEF FPC}@{$ENDIF}Tesseract.SynchronizeEnd);
  end;
end;

procedure TTesseractOCR5.Recognize(AUseThread: Boolean);
begin
  if FBusy then
    Exit;
  FLayoutAnalyse := True;
  if AUseThread then
    FRecognizerThread := TRecognizerThread.Create(Self)
  else
    RecognizeInternal;
end;

function TTesseractOCR5.RecognizeAsText: string;
begin
  Result := '';
  if FBusy then
    Exit;
  FLayoutAnalyse := False;
  RecognizeInternal;
  Result := FUTF8Text;
end;

function TTesseractOCR5.CreatePDF(ASourceFileName: string; AOutputFileName: string): Boolean;
var
  pdfRenderer: TessPDFRenderer;
  oldPageSegMode: TessPageSegMode;
  outFileName: string;
  exceptionMask: TFPUExceptionMask;
begin
  Result := False;
  if FBusy then
    Exit;
  oldPageSegMode := PageSegMode;
  PageSegMode := PSM_AUTO_OSD;
  try
{$IFNDEF FPC}
    outFileName := TPath.Combine(TPath.GetDirectoryName(AOutputFileName),
      TPath.GetFileNameWithoutExtension(AOutputFileName));
{$ELSE}
    outFileName := ConcatPaths([ExtractFileDir(AOutputFileName), ChangeFileExt(AOutputFileName, '')]);
{$ENDIF}
    exceptionMask := GetExceptionMask;
    SetExceptionMask(exceptionMask + [exZeroDivide, exInvalidOp]);
    try
      pdfRenderer := TessPDFRendererCreate(PUTF8Char(UTF8Encode(outFileName)), PUTF8Char(UTF8Encode(FDataPath)), False);
      try
        Result := TessBaseAPIProcessPages(FTessBaseAPI, PUTF8Char(UTF8Encode(ASourceFileName)), nil, 0, pdfRenderer);
      finally
        TessDeleteResultRenderer(pdfRenderer);
      end;
    finally
      SetExceptionMask(exceptionMask);
    end;
  finally
    PageSegMode := oldPageSegMode;
  end;
end;

{ TTesseractOCR5.TRecognizerThread }

constructor TTesseractOCR5.TRecognizerThread.Create(AOwner: TTesseractOCR5);
begin
  inherited Create(False);
  FOwner := AOwner;
  FreeOnTerminate := True;
end;

procedure TTesseractOCR5.TRecognizerThread.Execute;
begin
  FOwner.RecognizeInternal;
end;

end.
