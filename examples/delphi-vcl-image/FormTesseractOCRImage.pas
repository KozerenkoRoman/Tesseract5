unit FormTesseractOCRImage;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  System.UITypes, System.Types, System.IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Samples.Spin,
  tesseractocr;

type
  TTesseractOCRImageForm = class(TForm)
    btnCancel: TButton;
    btnOpenFile: TButton;
    btnRecognize: TButton;
    cbPageSegMode: TComboBox;
    gbPage: TGroupBox;
    labAnalysisMode: TLabel;
    labMeanWordConf: TLabel;
    labOrientation: TLabel;
    labWritingDirect: TLabel;
    memHOCR: TMemo;
    memText: TMemo;
    OpenDialogImage: TOpenDialog;
    panLayoutLeft: TPanel;
    panTop: TPanel;
    pbImage: TPaintBox;
    pbLayout: TPaintBox;
    pbRecognizeProgress: TProgressBar;
    pgTabs: TPageControl;
    StatusBar: TStatusBar;
    tabHOCR: TTabSheet;
    tabImage: TTabSheet;
    tabLayout: TTabSheet;
    tabText: TTabSheet;
    tvLayoutItems: TTreeView;
    procedure btnCancelClick(Sender: TObject);
    procedure btnOpenFileClick(Sender: TObject);
    procedure btnRecognizeClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure pbImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pbImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pbImageMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pbImagePaint(Sender: TObject);
    procedure pbLayoutMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure pbLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure pbLayoutPaint(Sender: TObject);
    procedure StatusBarDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
    procedure tvLayoutItemsChange(Sender: TObject; Node: TTreeNode);
  private
    { Private declarations }
    FImageROI: TRect;
    FSelectedLayoutItem: TObject;
    FSelectingROI: Boolean;
    FSelectionROI: TRect;
    FSourceImage: TBitmap;
    FSourceImageFileName: String;
    FStretchDrawRect: TRect;
    procedure OnRecognizeBegin(Sender: TObject);
    procedure OnRecognizeProgress(Sender: TObject; AProgress: Integer; var ACancel: Boolean);
    procedure OnRecognizeEnd(Sender: TObject; ACanceled: Boolean);
  public
    { Public declarations }
  end;

var
  TesseractOCRImageForm: TTesseractOCRImageForm;

implementation

uses
  tesseractocr.pagelayout,
  tesseractocr.utils,
  tesseractocr.capi;

{$R *.dfm}

{ TTesseractOCRImageForm }

procedure TTesseractOCRImageForm.FormCreate(Sender: TObject);
var
  progressBarStyle: Integer;
begin
  FSelectingROI := False;
  pbRecognizeProgress.Parent := StatusBar;
  progressBarStyle := GetWindowLong(pbRecognizeProgress.Handle, GWL_EXSTYLE);
  progressBarStyle := progressBarStyle and not WS_EX_STATICEDGE;
  SetWindowLong(pbRecognizeProgress.Handle, GWL_EXSTYLE, progressBarStyle);
  cbPageSegMode.ItemIndex := Ord(PSM_AUTO_OSD);

  Tesseract := TTesseractOCR5.Create;
  Tesseract.OnRecognizeBegin := OnRecognizeBegin;
  Tesseract.OnRecognizeProgress := OnRecognizeProgress;
  Tesseract.OnRecognizeEnd := OnRecognizeEnd;
  if not Tesseract.Initialize('tessdata' + PathDelim, 'eng', oemDefault) then
  begin
    MessageDlg('Error loading Tesseract data', mtError, [mbOk], 0);
    Application.ShowMainForm := False;
    Application.Terminate;
  end;
end;

procedure TTesseractOCRImageForm.FormDestroy(Sender: TObject);
begin
  Tesseract.Free;
  if Assigned(FSourceImage) then
    FSourceImage.Free;
end;

procedure TTesseractOCRImageForm.FormResize(Sender: TObject);
begin
  FSelectionROI.Width := 0;
  FSelectionROI.Height := 0;
  FImageROI.Width := 0;
  FImageROI.Height := 0;
end;

procedure TTesseractOCRImageForm.pbImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if FStretchDrawRect.Contains(Point(X, Y)) then
  begin
    FSelectionROI.Left := X;
    FSelectionROI.Top := Y;
    FSelectingROI := True;
  end;
end;

procedure TTesseractOCRImageForm.pbImageMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if FSelectingROI and FStretchDrawRect.Contains(Point(X, Y)) then
  begin
    FSelectionROI.Right := X;
    FSelectionROI.Bottom := Y;
    pbImage.Invalidate;
  end;
end;

procedure TTesseractOCRImageForm.pbImageMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  if FStretchDrawRect.Contains(Point(X, Y)) then
  begin
    FSelectingROI := False;
    FSelectionROI.Right := X;
    FSelectionROI.Bottom := Y;
    FSelectionROI.NormalizeRect;
    FImageROI.Create(FSelectionROI, False);
    FImageROI.Offset(-FStretchDrawRect.Left, -FStretchDrawRect.Top);
    FImageROI.Left := Round(FImageROI.Left * (FSourceImage.Width / FStretchDrawRect.Width));
    FImageROI.Top := Round(FImageROI.Top * (FSourceImage.Height / FStretchDrawRect.Height));
    FImageROI.Right := Round(FImageROI.Right * (FSourceImage.Width / FStretchDrawRect.Width));
    FImageROI.Bottom := Round(FImageROI.Bottom * (FSourceImage.Height / FStretchDrawRect.Height));
    pbImage.Invalidate;
  end;
end;

procedure TTesseractOCRImageForm.pbImagePaint(Sender: TObject);

  function ProportionalResize(AX, AY, AOrgWidth, AOrgHeight, AMaxWidth, AMaxHeight: Integer): TRect;
  var
    w, h: Single;
    X, Y: Single;
  begin
    X := AX;
    Y := AY;
    if (AOrgWidth > AOrgHeight) then
    begin
      w := AMaxWidth;
      h := (AMaxWidth * AOrgHeight) / AOrgWidth;
      if (h > AMaxHeight) then
      begin
        w := (AMaxHeight * AOrgWidth) / AOrgHeight;
        h := AMaxHeight;
      end;
    end
    else
    begin
      w := (AMaxHeight * AOrgWidth) / AOrgHeight;
      h := AMaxHeight;
      if (w > AMaxWidth) then
      begin
        w := AMaxWidth;
        h := (AMaxWidth * AOrgHeight) / AOrgWidth;
      end;
    end;
    Y := Y + (Abs(AMaxHeight - h) / 2);
    X := X + (Abs(AMaxWidth - w) / 2);
    Result := Rect(Trunc(X), Trunc(Y), Trunc(w + X), Trunc(h + Y));
  end;

begin
  if not Assigned(FSourceImage) then
    Exit;
  FStretchDrawRect := ProportionalResize(0, 0, FSourceImage.Width, FSourceImage.Height, pbImage.BoundsRect.Width,
    pbImage.BoundsRect.Height);
  pbImage.Canvas.StretchDraw(FStretchDrawRect, FSourceImage);
  pbImage.Canvas.Brush.Style := bsClear;
  pbImage.Canvas.Pen.Style := psDash;
  pbImage.Canvas.Pen.Color := clRed;
  pbImage.Canvas.Rectangle(FSelectionROI);
end;

procedure TTesseractOCRImageForm.pbLayoutMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
var
  Node: TTreeNode;
begin
  Node := tvLayoutItems.Items[0];
  while Node <> nil do
  begin
    if Node.Data = FSelectedLayoutItem then
    begin
      tvLayoutItems.Select(Node);
      Break;
    end;
    Node := Node.GetNext;
  end;
end;

procedure TTesseractOCRImageForm.pbLayoutMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  para: TTesseractParagraph;
  textLine: TTesseractTextLine;
  word: TTesseractWord;
begin
  if not Assigned(FSourceImage) then
    Exit;
  if not Tesseract.pagelayout.DataReady then
    Exit;

  for word in Tesseract.pagelayout.Words do
  begin
    if word.BoundingRect.Contains(Point(X, Y)) then
    begin
      FSelectedLayoutItem := word;
      pbLayout.Invalidate;
      Exit;
    end;
  end;
  for textLine in Tesseract.pagelayout.TextLines do
  begin
    if textLine.BoundingRect.Contains(Point(X, Y)) then
    begin
      FSelectedLayoutItem := textLine;
      pbLayout.Invalidate;
      Exit;
    end;
  end;
  for para in Tesseract.pagelayout.Paragraphs do
  begin
    if para.BoundingRect.Contains(Point(X, Y)) then
    begin
      FSelectedLayoutItem := para;
      pbLayout.Invalidate;
      Exit;
    end;
  end;
end;

procedure TTesseractOCRImageForm.pbLayoutPaint(Sender: TObject);

  procedure DrawRectAndTextAbove(ACanvas: TCanvas; AText: String; AColor: TColor; ARect: TRect);
  var
    textSize: TSize;
  begin
    ACanvas.Brush.Style := bsClear;
    ACanvas.Pen.Color := AColor;
    ACanvas.Rectangle(ARect);
    ACanvas.Brush.Color := clGray;
    ACanvas.Pen.Color := clGray;
    ACanvas.Brush.Style := bsSolid;
    textSize := ACanvas.TextExtent(AText);
    ACanvas.Rectangle(Rect(ARect.Left, ARect.Top - textSize.Height - 4, ARect.Left + textSize.Width + 4, ARect.Top));
    ACanvas.TextOut(ARect.Left + 2, ARect.Top - textSize.Height - 2, AText);
  end;

var
  block: TTesseractBlock;
  para: TTesseractParagraph;
  textLine: TTesseractTextLine;
  word: TTesseractWord;
  symbol: TTesseractSymbol;
  text: String;
begin
  if not Assigned(FSourceImage) then
    Exit;
  if not Tesseract.pagelayout.DataReady then
    Exit;
  pbLayout.Canvas.Brush.Color := clWhite;
  pbLayout.Canvas.FillRect(pbLayout.ClientRect);
  pbLayout.Canvas.Draw(0, 0, FSourceImage);
  pbLayout.Canvas.Pen.Style := psSolid;
  pbLayout.Canvas.Font.Size := 10;
  pbLayout.Canvas.Font.Name := 'Verdana';
  pbLayout.Canvas.Font.Color := clWhite;
  if Assigned(FSelectedLayoutItem) then
  begin
    if FSelectedLayoutItem is TTesseractBlock then
    begin
      block := TTesseractBlock(FSelectedLayoutItem);
      text := 'Block (' + BlockTypeToString(block.BlockType) + ')';
      DrawRectAndTextAbove(pbLayout.Canvas, text, clBlack, block.BoundingRect);
    end
    else if FSelectedLayoutItem is TTesseractParagraph then
    begin
      para := TTesseractParagraph(FSelectedLayoutItem);
      text := 'Paragraph (Justification: ' + ParagraphJustificationToString(para.Justification) + ')';
      DrawRectAndTextAbove(pbLayout.Canvas, text, clGreen, para.BoundingRect);
    end
    else if FSelectedLayoutItem is TTesseractTextLine then
    begin
      textLine := TTesseractTextLine(FSelectedLayoutItem);
      text := 'Text line';
      DrawRectAndTextAbove(pbLayout.Canvas, text, clBlue, textLine.BoundingRect);
    end
    else if FSelectedLayoutItem is TTesseractWord then
    begin
      word := TTesseractWord(FSelectedLayoutItem);
      text := Format('%s (Confidence: %.2f%%, Language: %s, In dictionary: %s)',
        [word.text, word.Confidence, word.Language, BoolToStr(word.InDictionary, True)]);
      DrawRectAndTextAbove(pbLayout.Canvas, text, clRed, word.BoundingRect);
    end
    else if FSelectedLayoutItem is TTesseractSymbol then
    begin
      symbol := TTesseractSymbol(FSelectedLayoutItem);
      text := Format('%s (Confidence: %.2f%%)', [symbol.Character, symbol.Confidence]);
      DrawRectAndTextAbove(pbLayout.Canvas, text, clRed, symbol.BoundingRect);
    end;
  end;
end;

procedure TTesseractOCRImageForm.StatusBarDrawPanel(StatusBar: TStatusBar; Panel: TStatusPanel; const Rect: TRect);
begin
  if (Panel.Index = 0) then
  begin
    pbRecognizeProgress.Top := Rect.Top;
    pbRecognizeProgress.Left := Rect.Left;
    pbRecognizeProgress.Width := Rect.Right - Rect.Left;
    pbRecognizeProgress.Height := Rect.Bottom - Rect.Top;
  end;
end;

procedure TTesseractOCRImageForm.tvLayoutItemsChange(Sender: TObject; Node: TTreeNode);
begin
  FSelectedLayoutItem := TObject(tvLayoutItems.Selected.Data);
  pbLayout.Invalidate;
end;

procedure TTesseractOCRImageForm.btnOpenFileClick(Sender: TObject);
begin
  if Tesseract.Busy then
    Exit;
  if OpenDialogImage.Execute then
  begin
    if Assigned(FSourceImage) then
      FreeAndNil(FSourceImage);
    if Tesseract.SetImage(OpenDialogImage.FileName) then
    begin
      FSourceImageFileName := OpenDialogImage.FileName;
      StatusBar.Panels[1].text := FSourceImageFileName;
      FSourceImage := Tesseract.GetSourceImageBMP;
      FSelectionROI := Rect(0, 0, 0, 0);
      btnRecognize.Enabled := True;
      pgTabs.ActivePage := tabImage;
      pbImage.Invalidate;
    end;
  end;
end;

procedure TTesseractOCRImageForm.btnRecognizeClick(Sender: TObject);
begin
  if not Assigned(FSourceImage) then
    Exit;

  if (FImageROI.Width > 0) and (FImageROI.Height > 0) then
    Tesseract.SetRectangle(FImageROI)
  else
    Tesseract.SetRectangle(Rect(0, 0, FSourceImage.Width, FSourceImage.Height));

  Tesseract.PageSegMode := TessPageSegMode(cbPageSegMode.ItemIndex);
  Tesseract.Recognize;
end;

procedure TTesseractOCRImageForm.btnCancelClick(Sender: TObject);
begin
  Tesseract.CancelRecognize;
end;

procedure TTesseractOCRImageForm.OnRecognizeBegin(Sender: TObject);
begin
  memText.Clear;
  memHOCR.Clear;
  tvLayoutItems.Items.Clear;
  FSelectedLayoutItem := nil;
  btnCancel.Enabled := True;
  btnRecognize.Enabled := False;
end;

procedure TTesseractOCRImageForm.OnRecognizeProgress(Sender: TObject; AProgress: Integer; var ACancel: Boolean);
begin
  pbRecognizeProgress.Position := AProgress;
end;

procedure TTesseractOCRImageForm.OnRecognizeEnd(Sender: TObject; ACanceled: Boolean);
var
  blockTree, paraTree, textLineTree, wordTree: TTreeNode;
begin
  btnCancel.Enabled := False;
  btnRecognize.Enabled := True;
  if not ACanceled then
  begin
    pbRecognizeProgress.Position := 100;
    memText.text := Tesseract.UTF8Text;
    memHOCR.text := Tesseract.HOCRText;
    labOrientation.Caption := Format('Orientation: %s', [PageOrientationToString(Tesseract.pagelayout.Orientation)]);
    labWritingDirect.Caption := Format('Writing direction: %s', [WritingDirectionToString(Tesseract.pagelayout.WritingDirection)]);
    labMeanWordConf.Caption := Format('Mean word confidence: %d%%', [Tesseract.pagelayout.MeanWordConfidence]);

    pbLayout.Invalidate;
    tvLayoutItems.Items.Clear;
    for var block in Tesseract.pagelayout.Blocks do
    begin
      blockTree := tvLayoutItems.Items.AddObject(nil, 'Block (' + BlockTypeToString(block.BlockType) + ')', block);
      for var para in block.Paragraphs do
      begin
        paraTree := tvLayoutItems.Items.AddChildObject(blockTree, 'Paragraph', para);
        for var textLine in para.TextLines do
        begin
          textLineTree := tvLayoutItems.Items.AddChildObject(paraTree, 'Text Line', textLine);
          for var word in textLine.Words do
          begin
            wordTree := tvLayoutItems.Items.AddChildObject(textLineTree, word.text, word);
            for var symbol in word.Symbols do
              tvLayoutItems.Items.AddChildObject(wordTree, symbol.Character, symbol);
          end;
        end;
      end;
    end;
    if pgTabs.ActivePage = tabImage then
      pgTabs.ActivePage := tabText;
  end
  else
    pbRecognizeProgress.Position := 0;
end;

end.
