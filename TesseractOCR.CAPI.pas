unit TesseractOCR.CAPI;

{ The MIT License (MIT)

  TTesseractOCR4
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
  {$IFNDEF FPC}Winapi.Windows, System.SysUtils{$ELSE}dynlibs, SysUtils{$ENDIF},
  TesseractOCR.Leptonica,
  TesseractOCR.Consts;

type
  TessBaseAPI = Pointer;
  TessBoxTextRenderer = Pointer;
  TessChoiceIterator = Pointer;
  TessHOcrRenderer = Pointer;
  TessMutableIterator = Pointer;
  TessPageIterator = Pointer;
  TessPDFRenderer = Pointer;
  TessResultIterator = Pointer;
  TessResultRenderer = Pointer;
  TessTextRenderer = Pointer;
  TessUnlvRenderer = Pointer;

  TessOcrEngineMode = (OEM_TESSERACT_ONLY, OEM_LSTM_ONLY, OEM_TESSERACT_LSTM_COMBINED, OEM_DEFAULT);
  TessOrientation = (ORIENTATION_PAGE_UP, ORIENTATION_PAGE_RIGHT, ORIENTATION_PAGE_DOWN, ORIENTATION_PAGE_LEFT);
  TessPageIteratorLevel = (RIL_BLOCK, RIL_PARA, RIL_TEXTLINE, RIL_WORD, RIL_SYMBOL);
  TessPageSegMode = (PSM_OSD_ONLY, PSM_AUTO_OSD, PSM_AUTO_ONLY, PSM_AUTO, PSM_SINGLE_COLUMN, PSM_SINGLE_BLOCK_VERT_TEXT, PSM_SINGLE_BLOCK, PSM_SINGLE_LINE, PSM_SINGLE_WORD, PSM_CIRCLE_WORD, PSM_SINGLE_CHAR, PSM_SPARSE_TEXT, PSM_SPARSE_TEXT_OSD, PSM_RAW_LINE, PSM_COUNT);
  TessParagraphJustification = (JUSTIFICATION_UNKNOWN, JUSTIFICATION_LEFT, JUSTIFICATION_CENTER, JUSTIFICATION_RIGHT);
  TessPolyBlockType = (PT_UNKNOWN, PT_FLOWING_TEXT, PT_HEADING_TEXT, PT_PULLOUT_TEXT, PT_EQUATION, PT_INLINE_EQUATION, PT_TABLE, PT_VERTICAL_TEXT, PT_CAPTION_TEXT, PT_FLOWING_IMAGE, PT_HEADING_IMAGE, PT_PULLOUT_IMAGE, PT_HORZ_LINE, PT_VERT_LINE, PT_NOISE, PT_COUNT);
  TessTextlineOrder = (TEXTLINE_ORDER_LEFT_TO_RIGHT, TEXTLINE_ORDER_RIGHT_TO_LEFT, TEXTLINE_ORDER_TOP_TO_BOTTOM);
  TessWritingDirection = (WRITING_DIRECTION_LEFT_TO_RIGHT, WRITING_DIRECTION_RIGHT_TO_LEFT, WRITING_DIRECTION_TOP_TO_BOTTOM);

  Float = Single;
  Bool = LongBool;
  Size_T = NativeUInt;
  Int = Integer;
  PInt = ^Int;

  CANCEL_FUNC = function(cancel_this: Pointer; words: Int): Boolean; cdecl;
  PROGRESS_FUNC = function(progress: Int; left, right, top, bottom: Int): Boolean; cdecl;

  EANYCODE_CHAR = record
    char_code: UINT16;
    left: INT16;
    right: INT16;
    top: INT16;
    bottom: INT16;
    font_index: INT16;
    confidence: UINT8;
    point_size: UINT8;
    blanks: INT8;
    formatting: UINT8;
  end;

  ETEXT_DESC = record
    count: INT16;
    progress: INT16;
    more_to_come: INT8;
    ocr_alive: INT8;
    err_code: INT8;
    cancel: CANCEL_FUNC;
    progress_callback: PROGRESS_FUNC;
    end_time: Integer;
    text: array [0 .. 0] of EANYCODE_CHAR;
  end;
  PETEXT_DESC = ^ETEXT_DESC;
  PPUTF8Char = ^PUTF8Char;

  // General free functions
  TfnTessDeleteIntArray = procedure(arr: Pointer); cdecl;
  TfnTessDeleteText = procedure(text: PUTF8Char); cdecl;
  TfnTessDeleteTextArray = procedure(arr: PPUTF8Char); cdecl;
  TfnTessVersion = function: PUTF8Char; cdecl;

  // Renderer API
  TfnTessBoxTextRendererCreate = function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;
  TfnTessDeleteResultRenderer = procedure(renderer: TessResultRenderer); cdecl;
  TfnTessHOcrRendererCreate = function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;
  TfnTessHOcrRendererCreate2 = function(const outputbase: PUTF8Char; font_info: Bool): TessResultRenderer; cdecl;
  TfnTessPDFRendererCreate = function(const outputbase: PUTF8Char; const datadir: PUTF8Char; textonly: Bool): TessResultRenderer; cdecl;
  TfnTessResultRendererAddImage = function(renderer: TessResultRenderer; api: TessBaseAPI): Bool; cdecl;
  TfnTessResultRendererBeginDocument = function(renderer: TessResultRenderer; const title: PUTF8Char): Bool; cdecl;
  TfnTessResultRendererEndDocument = function(renderer: TessResultRenderer): Bool; cdecl;
  TfnTessResultRendererExtention = function(renderer: TessResultRenderer): PUTF8Char; cdecl;
  TfnTessResultRendererImageNum = function(renderer: TessResultRenderer): Int; cdecl;
  TfnTessResultRendererInsert = procedure(renderer: TessResultRenderer; next: TessResultRenderer); cdecl;
  TfnTessResultRendererNext = function(renderer: TessResultRenderer): TessResultRenderer; cdecl;
  TfnTessResultRendererTitle = function(renderer: TessResultRenderer): PUTF8Char; cdecl;
  TfnTessTextRendererCreate = function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;
  TfnTessUnlvRendererCreate = function(const outputbase: PUTF8Char): TessResultRenderer; cdecl;

  // Base API
  TfnTessBaseAPIAdaptToWordStr = function(handle: TessBaseAPI; mode: TessPageSegMode; const wordstr: PUTF8Char): Bool; cdecl;
  TfnTessBaseAPIAllWordConfidences = function(handle: TessBaseAPI): PInt; cdecl;
  TfnTessBaseAPIAnalyseLayout = function(handle: TessBaseAPI): TessPageIterator; cdecl;
  TfnTessBaseAPIClear = procedure(handle: TessBaseAPI); cdecl;
  TfnTessBaseAPIClearAdaptiveClassifier = procedure(handle: TessBaseAPI); cdecl;
  TfnTessBaseAPICreate = function: TessBaseAPI; cdecl;
  TfnTessBaseAPIDelete = procedure(handle: TessBaseAPI); cdecl;
  TfnTessBaseAPIEnd = procedure(handle: TessBaseAPI); cdecl;
  TfnTessBaseAPIGetAvailableLanguagesAsVector = function(const handle: TessBaseAPI): PPUTF8Char; cdecl;
  TfnTessBaseAPIGetBoolVariable = function(const handle: TessBaseAPI; const name: PUTF8Char; out value: Bool): Bool; cdecl;
  TfnTessBaseAPIGetBoxText = function(handle: TessBaseAPI; page_number: Int): PUTF8Char; cdecl;
  TfnTessBaseAPIGetComponentImages = function(handle: TessBaseAPI; const level: TessPageIteratorLevel; const text_only: Bool; var pixa: PPixa; var blockids: PInt): PBoxa; cdecl;
  TfnTessBaseAPIGetComponentImages1 = function(handle: TessBaseAPI; const level: TessPageIteratorLevel; const text_only: Bool; const raw_image: Bool; const raw_padding: Int; var pixa: PPixa; var blockids: PInt; var paraids: PInt): PBoxa; cdecl;
  TfnTessBaseAPIGetConnectedComponents = function(handle: TessBaseAPI; var cc: PPixa): PBoxa; cdecl;
  TfnTessBaseAPIGetDatapath = function(handle: TessBaseAPI): PUTF8Char; cdecl;
  TfnTessBaseAPIGetDoubleVariable = function(const handle: TessBaseAPI; const name: PUTF8Char; out value: double): Bool; cdecl;
  TfnTessBaseAPIGetHOCRText = function(handle: TessBaseAPI; page_number: Int): PUTF8Char; cdecl;
  TfnTessBaseAPIGetInitLanguagesAsString = function(const handle: TessBaseAPI): PUTF8Char; cdecl;
  TfnTessBaseAPIGetInputImage = function(handle: TessBaseAPI): PPix; cdecl;
  TfnTessBaseAPIGetInputName = function(handle: TessBaseAPI): PUTF8Char; cdecl;
  TfnTessBaseAPIGetIntVariable = function(const handle: TessBaseAPI; const name: PUTF8Char; out value: Int): Bool; cdecl;
  TfnTessBaseAPIGetIterator = function(handle: TessBaseAPI): TessResultIterator; cdecl;
  TfnTessBaseAPIGetLoadedLanguagesAsVector = function(const handle: TessBaseAPI): PPUTF8Char; cdecl;
  TfnTessBaseAPIGetMutableIterator = function(handle: TessBaseAPI): TessMutableIterator; cdecl;
  TfnTessBaseAPIGetOpenCLDevice = function(handle: TessBaseAPI; device: PPointer): Size_T; cdecl;
  TfnTessBaseAPIGetPageSegMode = function(handle: TessBaseAPI): TessPageSegMode; cdecl;
  TfnTessBaseAPIGetRegions = function(handle: TessBaseAPI; var pixa: PPixa): PBoxa; cdecl;
  TfnTessBaseAPIGetSourceYResolution = function(handle: TessBaseAPI): Int; cdecl;
  TfnTessBaseAPIGetStringVariable = function(const handle: TessBaseAPI; const name: PUTF8Char): PUTF8Char; cdecl;
  TfnTessBaseAPIGetStrips = function(handle: TessBaseAPI; var pixa: PPixa; var blockids: PInt): PBoxa; cdecl;
  TfnTessBaseAPIGetTextDirection = function(handle: TessBaseAPI; var out_offset: Int; var out_slope: Float): Bool; cdecl;
  TfnTessBaseAPIGetTextlines = function(handle: TessBaseAPI; var pixa: PPixa; var blockids: PInt): PBoxa; cdecl;
  TfnTessBaseAPIGetTextlines1 = function(handle: TessBaseAPI; const raw_image: Bool; const raw_padding: Int; var pixa: PPixa; var blockids: PInt; var paraids: PInt): PBoxa; cdecl;
  TfnTessBaseAPIGetThresholdedImage = function(handle: TessBaseAPI): PPix; cdecl;
  TfnTessBaseAPIGetThresholdedImageScaleFactor = function(const handle: TessBaseAPI): Int; cdecl;
  TfnTessBaseAPIGetUnichar = function(handle: TessBaseAPI; unichar_id: Int): PUTF8Char; cdecl;
  TfnTessBaseAPIGetUNLVText = function(handle: TessBaseAPI): PUTF8Char; cdecl;
  TfnTessBaseAPIGetUTF8Text = function(handle: TessBaseAPI): PUTF8Char; cdecl;
  TfnTessBaseAPIGetWords = function(handle: TessBaseAPI; var pixa: PPixa): PBoxa; cdecl;
  TfnTessBaseAPIInit1 = function(handle: TessBaseAPI; const datapath: PUTF8Char; const language: PUTF8Char; oem: TessOcrEngineMode; configs: PPUTF8Char; configs_size: Int): Int; cdecl;
  TfnTessBaseAPIInit2 = function(handle: TessBaseAPI; const datapath: PUTF8Char; const language: PUTF8Char; oem: TessOcrEngineMode): Int; cdecl;
  TfnTessBaseAPIInit3 = function(handle: TessBaseAPI; const datapath: PUTF8Char; const language: PUTF8Char): Int; cdecl;
  TfnTessBaseAPIInit4 = function(handle: TessBaseAPI; const datapath: PUTF8Char; const language: PUTF8Char; oem: TessOcrEngineMode; configs: PPUTF8Char; configs_size: Int; vars_vec: PPUTF8Char; vars_values: PPUTF8Char; vars_vec_size: Size_T; set_only_non_debug_params: Bool): Int; cdecl;
  TfnTessBaseAPIInitForAnalysePage = procedure(handle: TessBaseAPI); cdecl;
  TfnTessBaseAPIInitLangMod = function(handle: TessBaseAPI; const datapath: PUTF8Char; const language: PUTF8Char): Int; cdecl;
  TfnTessBaseAPIIsValidWord = function(handle: TessBaseAPI; const word: PUTF8Char): Int; cdecl;
  TfnTessBaseAPIMeanTextConf = function(handle: TessBaseAPI): Int; cdecl;
  TfnTessBaseAPIPrintVariables = procedure(const handle: TessBaseAPI; fp: Pointer); cdecl;
  TfnTessBaseAPIPrintVariablesToFile = function(const handle: TessBaseAPI; const filename: PUTF8Char): Bool; cdecl;
  TfnTessBaseAPIProcessPage = function(handle: TessBaseAPI; pix: PPix; page_index: Int; const filename: PUTF8Char; const retry_config: PUTF8Char; timeout_millisec: Int; renderer: TessResultRenderer): Bool; cdecl;
  TfnTessBaseAPIProcessPages = function(handle: TessBaseAPI; const filename: PUTF8Char; const retry_config: PUTF8Char; timeout_millisec: Int; renderer: TessResultRenderer): Bool; cdecl;
  TfnTessBaseAPIReadConfigFile = procedure(handle: TessBaseAPI; const filename: PUTF8Char); cdecl;
  TfnTessBaseAPIReadDebugConfigFile = procedure(handle: TessBaseAPI; const filename: PUTF8Char); cdecl;
  TfnTessBaseAPIRecognize = function(handle: TessBaseAPI; var monitor: ETEXT_DESC): Int; cdecl;
  TfnTessBaseAPIRecognizeForChopTest = function(handle: TessBaseAPI; var monitor: ETEXT_DESC): Int; cdecl;
  TfnTessBaseAPIRect = function(handle: TessBaseAPI; const imagedata: PByte; bytes_per_pixel: Int; bytes_per_line: Int; left: Int; top: Int; width: Int; height: Int): PUTF8Char; cdecl;
  TfnTessBaseAPISetDebugVariable = function(handle: TessBaseAPI; const name: PUTF8Char; const value: PUTF8Char): Bool; cdecl;
  TfnTessBaseAPISetImage = procedure(handle: TessBaseAPI; const imagedata: PByte; width: Int; height: Int; bytes_per_pixel: Int; bytes_per_line: Int); cdecl;
  TfnTessBaseAPISetImage2 = procedure(handle: TessBaseAPI; pix: PPix); cdecl;
  TfnTessBaseAPISetInputImage = procedure(handle: TessBaseAPI; const pix: PPix); cdecl;
  TfnTessBaseAPISetInputName = procedure(handle: TessBaseAPI; const name: PUTF8Char); cdecl;
  TfnTessBaseAPISetMinOrientationMargin = procedure(handle: TessBaseAPI; margin: double); cdecl;
  TfnTessBaseAPISetOutputName = procedure(handle: TessBaseAPI; const name: PUTF8Char); cdecl;
  TfnTessBaseAPISetPageSegMode = procedure(handle: TessBaseAPI; mode: TessPageSegMode); cdecl;
  TfnTessBaseAPISetRectangle = procedure(handle: TessBaseAPI; left: Int; top: Int; width: Int; height: Int); cdecl;
  TfnTessBaseAPISetSourceResolution = procedure(handle: TessBaseAPI; ppi: Int); cdecl;
  TfnTessBaseAPISetVariable = function(handle: TessBaseAPI; const name: PUTF8Char; const value: PUTF8Char): Bool; cdecl;

  // Page iterator
  TfnTessPageIteratorBaseline = function(const handle: TessPageIterator; level: TessPageIteratorLevel; out x1: Int; out y1: Int; out x2: Int; out y2: Int): Bool; cdecl;
  TfnTessPageIteratorBegin = procedure(handle: TessPageIterator); cdecl;
  TfnTessPageIteratorBlockType = function(const handle: TessPageIterator): TessPolyBlockType; cdecl;
  TfnTessPageIteratorBoundingBox = function(const handle: TessPageIterator; level: TessPageIteratorLevel; out left: Int; out top: Int; out right: Int; out bottom: Int): Bool; cdecl;
  TfnTessPageIteratorCopy = function(const handle: TessBaseAPI): TessPageIterator; cdecl;
  TfnTessPageIteratorDelete = procedure(handle: TessBaseAPI); cdecl;
  TfnTessPageIteratorGetBinaryImage = function(const handle: TessPageIterator; level: TessPageIteratorLevel): PPix; cdecl;
  TfnTessPageIteratorGetImage = function(const handle: TessPageIterator; level: TessPageIteratorLevel; padding: Int; original_image: PPix; var left: Int; var top: Int): PPix; cdecl;
  TfnTessPageIteratorIsAtBeginningOf = function(const handle: TessPageIterator; level: TessPageIteratorLevel): Bool; cdecl;
  TfnTessPageIteratorIsAtFinalElement = function(const handle: TessPageIterator; level: TessPageIteratorLevel; element: TessPageIteratorLevel): Bool; cdecl;
  TfnTessPageIteratorNext = function(handle: TessPageIterator; level: TessPageIteratorLevel): Bool; cdecl;
  TfnTessPageIteratorOrientation = procedure(handle: TessPageIterator; out orientation: TessOrientation; out writing_direction: TessWritingDirection; out textline_order: TessTextlineOrder; out deskew_angle: Float); cdecl;
  TfnTessPageIteratorParagraphInfo = procedure(handle: TessPageIterator; out justification: TessParagraphJustification; out is_list_item: Bool; out is_crown: Bool; out first_line_indent: Int); cdecl;

  // Result iterator
  TfnTessChoiceIteratorConfidence = function(const handle: TessChoiceIterator): Float; cdecl;
  TfnTessChoiceIteratorDelete = procedure(handle: TessChoiceIterator); cdecl;
  TfnTessChoiceIteratorGetUTF8Text = function(const handle: TessChoiceIterator): PUTF8Char; cdecl;
  TfnTessChoiceIteratorNext = function(handle: TessChoiceIterator): Bool; cdecl;
  TfnTessResultIteratorConfidence = function(const handle: TessResultIterator; level: TessPageIteratorLevel): Float; cdecl;
  TfnTessResultIteratorCopy = function(const handle: TessResultIterator): TessResultIterator; cdecl;
  TfnTessResultIteratorDelete = procedure(handle: TessResultIterator); cdecl;
  TfnTessResultIteratorGetChoiceIterator = function(const handle: TessResultIterator): TessChoiceIterator; cdecl;
  TfnTessResultIteratorGetPageIterator = function(const handle: TessResultIterator): TessPageIterator; cdecl;
  TfnTessResultIteratorGetPageIteratorConst = function(const handle: TessResultIterator): TessPageIterator; cdecl;
  TfnTessResultIteratorGetUTF8Text = function(const handle: TessResultIterator; level: TessPageIteratorLevel): PUTF8Char; cdecl;
  TfnTessResultIteratorNext = function(handle: TessResultIterator; level: TessPageIteratorLevel): Bool; cdecl;
  TfnTessResultIteratorSymbolIsDropcap = function(const handle: TessResultIterator): Bool; cdecl;
  TfnTessResultIteratorSymbolIsSubscript = function(const handle: TessResultIterator): Bool; cdecl;
  TfnTessResultIteratorSymbolIsSuperscript = function(const handle: TessResultIterator): Bool; cdecl;
  TfnTessResultIteratorWordFontAttributes = function(const handle: TessResultIterator; out is_bold: Bool; out is_italic: Bool; out is_underlined: Bool; out is_monospace: Bool; out is_serif: Bool; out is_smallcaps: Bool; out pointsize: Int; out font_id: Int): PUTF8Char; cdecl;
  TfnTessResultIteratorWordIsFromDictionary = function(const handle: TessResultIterator): Bool; cdecl;
  TfnTessResultIteratorWordIsNumeric = function(const handle: TessResultIterator): Bool; cdecl;
  TfnTessResultIteratorWordRecognitionLanguage = function(const handle: TessResultIterator): PUTF8Char; cdecl;

var
  // General free functions
  TessDeleteIntArray: TfnTessDeleteIntArray;
  TessDeleteText: TfnTessDeleteText;
  TessDeleteTextArray: TfnTessDeleteTextArray;
  TessVersion: TfnTessVersion;
  // Renderer API
  TessBoxTextRendererCreate: TfnTessBoxTextRendererCreate;
  TessDeleteResultRenderer: TfnTessDeleteResultRenderer;
  TessHOcrRendererCreate: TfnTessHOcrRendererCreate;
  TessHOcrRendererCreate2: TfnTessHOcrRendererCreate2;
  TessPDFRendererCreate: TfnTessPDFRendererCreate;
  TessResultRendererAddImage: TfnTessResultRendererAddImage;
  TessResultRendererBeginDocument: TfnTessResultRendererBeginDocument;
  TessResultRendererEndDocument: TfnTessResultRendererEndDocument;
  TessResultRendererExtention: TfnTessResultRendererExtention;
  TessResultRendererImageNum: TfnTessResultRendererImageNum;
  TessResultRendererInsert: TfnTessResultRendererInsert;
  TessResultRendererNext: TfnTessResultRendererNext;
  TessResultRendererTitle: TfnTessResultRendererTitle;
  TessTextRendererCreate: TfnTessTextRendererCreate;
  TessUnlvRendererCreate: TfnTessUnlvRendererCreate;
  // Base API
  TessBaseAPIAdaptToWordStr: TfnTessBaseAPIAdaptToWordStr;
  TessBaseAPIAllWordConfidences: TfnTessBaseAPIAllWordConfidences;
  TessBaseAPIAnalyseLayout: TfnTessBaseAPIAnalyseLayout;
  TessBaseAPIClear: TfnTessBaseAPIClear;
  TessBaseAPIClearAdaptiveClassifier: TfnTessBaseAPIClearAdaptiveClassifier;
  TessBaseAPICreate: TfnTessBaseAPICreate;
  TessBaseAPIDelete: TfnTessBaseAPIDelete;
  TessBaseAPIEnd: TfnTessBaseAPIEnd;
  TessBaseAPIGetAvailableLanguagesAsVector: TfnTessBaseAPIGetAvailableLanguagesAsVector;
  TessBaseAPIGetBoolVariable: TfnTessBaseAPIGetBoolVariable;
  TessBaseAPIGetBoxText: TfnTessBaseAPIGetBoxText;
  TessBaseAPIGetComponentImages: TfnTessBaseAPIGetComponentImages;
  TessBaseAPIGetComponentImages1: TfnTessBaseAPIGetComponentImages1;
  TessBaseAPIGetConnectedComponents: TfnTessBaseAPIGetConnectedComponents;
  TessBaseAPIGetDatapath: TfnTessBaseAPIGetDatapath;
  TessBaseAPIGetDoubleVariable: TfnTessBaseAPIGetDoubleVariable;
  TessBaseAPIGetHOCRText: TfnTessBaseAPIGetHOCRText;
  TessBaseAPIGetInitLanguagesAsString: TfnTessBaseAPIGetInitLanguagesAsString;
  TessBaseAPIGetInputImage: TfnTessBaseAPIGetInputImage;
  TessBaseAPIGetInputName: TfnTessBaseAPIGetInputName;
  TessBaseAPIGetIntVariable: TfnTessBaseAPIGetIntVariable;
  TessBaseAPIGetIterator: TfnTessBaseAPIGetIterator;
  TessBaseAPIGetLoadedLanguagesAsVector: TfnTessBaseAPIGetLoadedLanguagesAsVector;
  TessBaseAPIGetMutableIterator: TfnTessBaseAPIGetMutableIterator;
  TessBaseAPIGetOpenCLDevice: TfnTessBaseAPIGetOpenCLDevice;
  TessBaseAPIGetPageSegMode: TfnTessBaseAPIGetPageSegMode;
  TessBaseAPIGetRegions: TfnTessBaseAPIGetRegions;
  TessBaseAPIGetSourceYResolution: TfnTessBaseAPIGetSourceYResolution;
  TessBaseAPIGetStringVariable: TfnTessBaseAPIGetStringVariable;
  TessBaseAPIGetStrips: TfnTessBaseAPIGetStrips;
  TessBaseAPIGetTextDirection: TfnTessBaseAPIGetTextDirection;
  TessBaseAPIGetTextlines: TfnTessBaseAPIGetTextlines;
  TessBaseAPIGetTextlines1: TfnTessBaseAPIGetTextlines1;
  TessBaseAPIGetThresholdedImage: TfnTessBaseAPIGetThresholdedImage;
  TessBaseAPIGetThresholdedImageScaleFactor: TfnTessBaseAPIGetThresholdedImageScaleFactor;
  TessBaseAPIGetUnichar: TfnTessBaseAPIGetUnichar;
  TessBaseAPIGetUNLVText: TfnTessBaseAPIGetUNLVText;
  TessBaseAPIGetUTF8Text: TfnTessBaseAPIGetUTF8Text;
  TessBaseAPIGetWords: TfnTessBaseAPIGetWords;
  TessBaseAPIInit1: TfnTessBaseAPIInit1;
  TessBaseAPIInit2: TfnTessBaseAPIInit2;
  TessBaseAPIInit3: TfnTessBaseAPIInit3;
  TessBaseAPIInit4: TfnTessBaseAPIInit4;
  TessBaseAPIInitForAnalysePage: TfnTessBaseAPIInitForAnalysePage;
  TessBaseAPIInitLangMod: TfnTessBaseAPIInitLangMod;
  TessBaseAPIIsValidWord: TfnTessBaseAPIIsValidWord;
  TessBaseAPIMeanTextConf: TfnTessBaseAPIMeanTextConf;
  TessBaseAPIPrintVariables: TfnTessBaseAPIPrintVariables;
  TessBaseAPIPrintVariablesToFile: TfnTessBaseAPIPrintVariablesToFile;
  TessBaseAPIProcessPage: TfnTessBaseAPIProcessPage;
  TessBaseAPIProcessPages: TfnTessBaseAPIProcessPages;
  TessBaseAPIReadConfigFile: TfnTessBaseAPIReadConfigFile;
  TessBaseAPIReadDebugConfigFile: TfnTessBaseAPIReadDebugConfigFile;
  TessBaseAPIRecognize: TfnTessBaseAPIRecognize;
  TessBaseAPIRecognizeForChopTest: TfnTessBaseAPIRecognizeForChopTest;
  TessBaseAPIRect: TfnTessBaseAPIRect;
  TessBaseAPISetDebugVariable: TfnTessBaseAPISetDebugVariable;
  TessBaseAPISetImage: TfnTessBaseAPISetImage;
  TessBaseAPISetImage2: TfnTessBaseAPISetImage2;
  TessBaseAPISetInputImage: TfnTessBaseAPISetInputImage;
  TessBaseAPISetInputName: TfnTessBaseAPISetInputName;
  TessBaseAPISetMinOrientationMargin: TfnTessBaseAPISetMinOrientationMargin;
  TessBaseAPISetOutputName: TfnTessBaseAPISetOutputName;
  TessBaseAPISetPageSegMode: TfnTessBaseAPISetPageSegMode;
  TessBaseAPISetRectangle: TfnTessBaseAPISetRectangle;
  TessBaseAPISetSourceResolution: TfnTessBaseAPISetSourceResolution;
  TessBaseAPISetVariable: TfnTessBaseAPISetVariable;
  // Page iterator
  TessPageIteratorBaseline: TfnTessPageIteratorBaseline;
  TessPageIteratorBegin: TfnTessPageIteratorBegin;
  TessPageIteratorBlockType: TfnTessPageIteratorBlockType;
  TessPageIteratorBoundingBox: TfnTessPageIteratorBoundingBox;
  TessPageIteratorCopy: TfnTessPageIteratorCopy;
  TessPageIteratorDelete: TfnTessPageIteratorDelete;
  TessPageIteratorGetBinaryImage: TfnTessPageIteratorGetBinaryImage;
  TessPageIteratorGetImage: TfnTessPageIteratorGetBinaryImage;
  TessPageIteratorIsAtBeginningOf: TfnTessPageIteratorIsAtBeginningOf;
  TessPageIteratorIsAtFinalElement: TfnTessPageIteratorIsAtFinalElement;
  TessPageIteratorNext: TfnTessPageIteratorNext;
  TessPageIteratorOrientation: TfnTessPageIteratorOrientation;
  TessPageIteratorParagraphInfo: TfnTessPageIteratorParagraphInfo;
  // Result iterator
  TessChoiceIteratorConfidence: TfnTessChoiceIteratorConfidence;
  TessChoiceIteratorDelete: TfnTessChoiceIteratorDelete;
  TessChoiceIteratorGetUTF8Text: TfnTessChoiceIteratorGetUTF8Text;
  TessChoiceIteratorNext: TfnTessChoiceIteratorNext;
  TessResultIteratorConfidence: TfnTessResultIteratorConfidence;
  TessResultIteratorCopy: TfnTessResultIteratorCopy;
  TessResultIteratorDelete: TfnTessResultIteratorDelete;
  TessResultIteratorGetChoiceIterator: TfnTessResultIteratorGetChoiceIterator;
  TessResultIteratorGetPageIterator: TfnTessResultIteratorGetPageIterator;
  TessResultIteratorGetPageIteratorConst: TfnTessResultIteratorGetPageIteratorConst;
  TessResultIteratorGetUTF8Text: TfnTessResultIteratorGetUTF8Text;
  TessResultIteratorNext: TfnTessResultIteratorNext;
  TessResultIteratorSymbolIsDropcap: TfnTessResultIteratorSymbolIsDropcap;
  TessResultIteratorSymbolIsSubscript: TfnTessResultIteratorSymbolIsSubscript;
  TessResultIteratorSymbolIsSuperscript: TfnTessResultIteratorSymbolIsSuperscript;
  TessResultIteratorWordFontAttributes: TfnTessResultIteratorWordFontAttributes;
  TessResultIteratorWordIsFromDictionary: TfnTessResultIteratorWordIsFromDictionary;
  TessResultIteratorWordIsNumeric: TfnTessResultIteratorWordIsNumeric;
  TessResultIteratorWordRecognitionLanguage: TfnTessResultIteratorWordRecognitionLanguage;

function InitTesseractLib: Boolean;
procedure FreeTesseractLib;

implementation

var
  hTesseractLib: THandle;

procedure FreeTesseractLib;
begin
  if (hTesseractLib <> 0) then
  begin
    FreeLibrary(hTesseractLib);
    hTesseractLib := 0;
  end;
end;

function InitTesseractLib: Boolean;

  function GetTesseractProcAddress(var AProcPtr: Pointer; AProcName: AnsiString): Boolean;
  begin
    AProcPtr := GetProcAddress(hTesseractLib, {$IFDEF FPC}AProcName{$ELSE}PAnsiChar(AProcName){$ENDIF});
    Result := Assigned(AProcPtr);
    if not Result then
      raise Exception.Create('Error while loading Tesseract function: ' + string(AProcName));
  end;

begin
  Result := False;
  if (hTesseractLib = 0) then
  begin
    hTesseractLib := LoadLibrary({$IFDEF FPC}libtesseract{$ELSE}PChar(libtesseract){$ENDIF});
    if (hTesseractLib <> 0) then
    begin
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIAdaptToWordStr{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIAdaptToWordStr');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIAllWordConfidences{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIAllWordConfidences');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIAnalyseLayout{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIAnalyseLayout');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIClear{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIClear');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIClearAdaptiveClassifier{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIClearAdaptiveClassifier');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPICreate{$IFDEF FPC}){$ENDIF}, 'TessBaseAPICreate');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIDelete{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIDelete');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIEnd{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIEnd');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetAvailableLanguagesAsVector{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetAvailableLanguagesAsVector');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetBoolVariable{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetBoolVariable');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetBoxText{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetBoxText');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetComponentImages{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetComponentImages');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetComponentImages1{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetComponentImages1');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetConnectedComponents{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetConnectedComponents');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetDatapath{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetDatapath');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetDoubleVariable{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetDoubleVariable');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetHOCRText{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetHOCRText');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetInitLanguagesAsString{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetInitLanguagesAsString');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetInputImage{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetInputImage');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetInputName{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetInputName');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetIntVariable{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetIntVariable');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetIterator{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetIterator');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetLoadedLanguagesAsVector{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetLoadedLanguagesAsVector');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetMutableIterator{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetMutableIterator');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetOpenCLDevice{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetOpenCLDevice');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetPageSegMode{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetPageSegMode');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetRegions{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetRegions');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetSourceYResolution{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetSourceYResolution');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetStringVariable{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetStringVariable');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetStrips{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetStrips');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetTextDirection{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetTextDirection');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetTextlines{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetTextlines');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetTextlines1{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetTextlines1');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetThresholdedImage{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetThresholdedImage');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetThresholdedImageScaleFactor{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetThresholdedImageScaleFactor');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetUnichar{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetUnichar');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetUNLVText{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetUNLVText');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetUTF8Text{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetUTF8Text');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIGetWords{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIGetWords');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIInit1{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIInit1');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIInit2{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIInit2');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIInit3{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIInit3');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIInit4{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIInit4');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIInitForAnalysePage{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIInitForAnalysePage');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIIsValidWord{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIIsValidWord');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIMeanTextConf{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIMeanTextConf');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIPrintVariables{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIPrintVariables');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIPrintVariablesToFile{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIPrintVariablesToFile');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIProcessPage{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIProcessPage');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIProcessPages{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIProcessPages');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIReadConfigFile{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIReadConfigFile');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIReadDebugConfigFile{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIReadDebugConfigFile');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIRecognize{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIRecognize');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPIRect{$IFDEF FPC}){$ENDIF}, 'TessBaseAPIRect');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPISetDebugVariable{$IFDEF FPC}){$ENDIF}, 'TessBaseAPISetDebugVariable');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPISetImage{$IFDEF FPC}){$ENDIF}, 'TessBaseAPISetImage');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPISetImage2{$IFDEF FPC}){$ENDIF}, 'TessBaseAPISetImage2');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPISetInputImage{$IFDEF FPC}){$ENDIF}, 'TessBaseAPISetInputImage');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPISetInputName{$IFDEF FPC}){$ENDIF}, 'TessBaseAPISetInputName');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPISetMinOrientationMargin{$IFDEF FPC}){$ENDIF}, 'TessBaseAPISetMinOrientationMargin');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPISetOutputName{$IFDEF FPC}){$ENDIF}, 'TessBaseAPISetOutputName');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPISetPageSegMode{$IFDEF FPC}){$ENDIF}, 'TessBaseAPISetPageSegMode');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPISetRectangle{$IFDEF FPC}){$ENDIF}, 'TessBaseAPISetRectangle');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPISetSourceResolution{$IFDEF FPC}){$ENDIF}, 'TessBaseAPISetSourceResolution');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBaseAPISetVariable{$IFDEF FPC}){$ENDIF}, 'TessBaseAPISetVariable');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessBoxTextRendererCreate{$IFDEF FPC}){$ENDIF}, 'TessBoxTextRendererCreate');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessChoiceIteratorConfidence{$IFDEF FPC}){$ENDIF}, 'TessChoiceIteratorConfidence');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessChoiceIteratorDelete{$IFDEF FPC}){$ENDIF}, 'TessChoiceIteratorDelete');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessChoiceIteratorGetUTF8Text{$IFDEF FPC}){$ENDIF}, 'TessChoiceIteratorGetUTF8Text');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessChoiceIteratorNext{$IFDEF FPC}){$ENDIF}, 'TessChoiceIteratorNext');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessDeleteIntArray{$IFDEF FPC}){$ENDIF}, 'TessDeleteIntArray');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessDeleteResultRenderer{$IFDEF FPC}){$ENDIF}, 'TessDeleteResultRenderer');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessDeleteText{$IFDEF FPC}){$ENDIF}, 'TessDeleteText');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessDeleteTextArray{$IFDEF FPC}){$ENDIF}, 'TessDeleteTextArray');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessHOcrRendererCreate{$IFDEF FPC}){$ENDIF}, 'TessHOcrRendererCreate');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessHOcrRendererCreate2{$IFDEF FPC}){$ENDIF}, 'TessHOcrRendererCreate2');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorBaseline{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorBaseline');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorBegin{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorBegin');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorBlockType{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorBlockType');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorBoundingBox{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorBoundingBox');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorCopy{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorCopy');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorDelete{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorDelete');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorGetBinaryImage{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorGetBinaryImage');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorGetImage{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorGetImage');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorIsAtBeginningOf{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorIsAtBeginningOf');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorIsAtFinalElement{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorIsAtFinalElement');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorNext{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorNext');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorOrientation{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorOrientation');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPageIteratorParagraphInfo{$IFDEF FPC}){$ENDIF}, 'TessPageIteratorParagraphInfo');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessPDFRendererCreate{$IFDEF FPC}){$ENDIF}, 'TessPDFRendererCreate');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorConfidence{$IFDEF FPC}){$ENDIF},'TessResultIteratorConfidence');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorCopy{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorCopy');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorDelete{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorDelete');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorGetChoiceIterator{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorGetChoiceIterator');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorGetPageIterator{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorGetPageIterator');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorGetPageIteratorConst{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorGetPageIteratorConst');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorGetUTF8Text{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorGetUTF8Text');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorNext{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorNext');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorSymbolIsDropcap{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorSymbolIsDropcap');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorSymbolIsSubscript{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorSymbolIsSubscript');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorSymbolIsSuperscript{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorSymbolIsSuperscript');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorWordFontAttributes{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorWordFontAttributes');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorWordIsFromDictionary{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorWordIsFromDictionary');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorWordIsNumeric{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorWordIsNumeric');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultIteratorWordRecognitionLanguage{$IFDEF FPC}){$ENDIF}, 'TessResultIteratorWordRecognitionLanguage');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultRendererAddImage{$IFDEF FPC}){$ENDIF}, 'TessResultRendererAddImage');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultRendererBeginDocument{$IFDEF FPC}){$ENDIF}, 'TessResultRendererBeginDocument');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultRendererEndDocument{$IFDEF FPC}){$ENDIF}, 'TessResultRendererEndDocument');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultRendererExtention{$IFDEF FPC}){$ENDIF}, 'TessResultRendererExtention');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultRendererImageNum{$IFDEF FPC}){$ENDIF}, 'TessResultRendererImageNum');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultRendererInsert{$IFDEF FPC}){$ENDIF}, 'TessResultRendererInsert');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultRendererNext{$IFDEF FPC}){$ENDIF}, 'TessResultRendererNext');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessResultRendererTitle{$IFDEF FPC}){$ENDIF}, 'TessResultRendererTitle');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessTextRendererCreate{$IFDEF FPC}){$ENDIF}, 'TessTextRendererCreate');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessUnlvRendererCreate{$IFDEF FPC}){$ENDIF}, 'TessUnlvRendererCreate');
      GetTesseractProcAddress({$IFNDEF FPC}@{$ELSE}Pointer({$ENDIF}TessVersion{$IFDEF FPC}){$ENDIF}, 'TessVersion');
      Result := True;
    end;
  end;
end;

end.
