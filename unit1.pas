unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ExtDlgs, Camera, AviCaptura;


type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    MyPaintBox: TPaintBox;
    Panel1: TPanel;
    SavePictureDialog1: TSavePictureDialog;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Panel1Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
var
  ca : TCamera;
begin
  Ca := TCamera.Create(nil);
  Ca.ParentWindow:= Panel1.Handle;
  Ca.Actif:= true;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  lBmp: TBitmap;
begin
  lBmp := TBitmap.Create;
  try
    lBmp.SetSize(Panel1.ClientWidth, Panel1.ClientHeight);
    BitBlt(lBmp.Canvas.Handle, 0, 0, Panel1.ClientWidth, Panel1.ClientHeight, TPanel(Panel1).Canvas.Handle, 0, 0, SRCCOPY);
    MyPaintBox.Canvas.Draw(0,0,lBmp);
  finally
    lBmp.Free;
  end;

end;

procedure TForm1.Button3Click(Sender: TObject);
var
  Bitmap: TBitmap;
  Source: TRect;
  Dest: TRect;
begin
  SavePictureDialog1.Filter:='File BMP (*.bmp)|*.bmp';
  if SavePictureDialog1.Execute then
  begin
  Bitmap := TBitmap.Create;
  try
    with Bitmap do
    begin
      Width := MyPaintBox.Width;
      Height := MyPaintBox.Height;
      Dest := Rect(0, 0, Width, Height);
    end;
    with MyPaintBox do
      Source := Rect(0, 0, Width, Height);
      Bitmap.Canvas.CopyRect(Dest, MyPaintBox.Canvas, Source);
      Bitmap.SaveToFile(SavePictureDialog1.FileName);
      ShowMessage('Image Saved on '+SavePictureDialog1.FileName);
  finally
    Bitmap.Free;
  end;
  end;
end;

procedure TForm1.Panel1Click(Sender: TObject);
begin

end;

end.

