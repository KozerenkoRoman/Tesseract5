program delphi_console_simple;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  tesseractocr in '..\..\tesseractocr.pas';

begin
  Tesseract := TTesseractOCR5.Create;
  try
    if Tesseract.Initialize('tessdata' + PathDelim, 'ukr') then
    begin
      Tesseract.SetImage('samples' + PathDelim + 'ukr.jpg');
      WriteLn(Tesseract.RecognizeAsText);
      ReadLn;
    end;
  finally
    Tesseract.Free;
  end;
end.
