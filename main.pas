unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, filectrl, jpeg, ShellAPI, ShlObj, ComCtrls, Math,
  ExtCtrls,Registry;

type
  TForm1 = class(TForm)
    btn1: TButton;
    btn2: TButton;
    lbl1: TLabel;
    btn3: TButton;
    edt1: TEdit;
    mmo1: TMemo;
    clcs: TRadioGroup;
    Button1: TButton;
    Label1: TLabel;
    procedure btn2Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure FindSubDir(DirName: string; FileString: TStrings);
    procedure SearchFilename(const Dir, Ext: string; Files: TStrings);

    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);

    
  private
    { Private declarations }
    function IsValidDir(SearchRec: TSearchRec): Boolean;

  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  X: Integer;
  Y: Integer;
  Z: Integer;
  p: string;
implementation

{$R *.dfm}

 //获取桌面所在的路径
function GetDesktopDir: String;
var R: TRegistry;
begin
R := TRegistry.Create;
R.OpenKey('SOFTWARE\MICROSOFT\WINDOWS\CURRENTVERSION\EXPLORER\SHELL FOLDERS', FALSE);
Result := R.ReadString('DESKTOP');
Result := UpperCase(Result);  //轉換為大小寫,可以不使用;
R.Free;
end;
//函數返回的字符串就是路徑;


function BrowseDialogCallBack
  (Wnd: HWND; uMsg: UINT; lParam, lpData: LPARAM):
  integer stdcall;
var
  wa, rect: TRect;
  dialogPT: TPoint;
begin
  //center in work area
  if uMsg = BFFM_INITIALIZED then
  begin
    wa := Screen.WorkAreaRect;
    GetWindowRect(Wnd, Rect);
    dialogPT.X := ((wa.Right - wa.Left) div 2) -
      ((rect.Right - rect.Left) div 2);
    dialogPT.Y := ((wa.Bottom - wa.Top) div 2) -
      ((rect.Bottom - rect.Top) div 2);
    MoveWindow(Wnd,
      dialogPT.X,
      dialogPT.Y,
      Rect.Right - Rect.Left,
      Rect.Bottom - Rect.Top,
      True);
  end;

  Result := 0;
end; (*BrowseDialogCallBack*)


function BrowseDialog
  (const Title: string; const Flag: integer): string;
var
  lpItemID: PItemIDList;
  BrowseInfo: TBrowseInfo;
  DisplayName: array[0..MAX_PATH] of char;
  TempPath: array[0..MAX_PATH] of char;
begin
  Result := '';
  FillChar(BrowseInfo, sizeof(TBrowseInfo), #0);
  with BrowseInfo do begin
    hwndOwner := Application.Handle;
    pszDisplayName := @DisplayName;
    lpszTitle := PChar(Title);
    ulFlags := Flag;
    lpfn := BrowseDialogCallBack;
  end;
  lpItemID := SHBrowseForFolder(BrowseInfo);
  if lpItemId <> nil then begin
    SHGetPathFromIDList(lpItemID, TempPath);
    Result := TempPath;
    GlobalFreePtr(lpItemID);
  end;
end;




procedure TForm1.btn2Click(Sender: TObject);

begin
  mmo1.Clear;
  edt1.Text := BrowseDialog('请指定图片所在的文件夹！', 0);

end;

procedure TForm1.btn3Click(Sender: TObject);
begin
  close;
end;


procedure TForm1.btn1Click(Sender: TObject);
var
  bmp: TBitmap;
  jpg: TJpegImage;
  stemp: string;
  filelstJpg: TStringList;
  filelstBmp: TStringList;
  i: Integer;
  a: Integer;
  p: string;

begin
  bmp := TBitmap.Create;
  jpg := TJpegImage.Create;
  filelstJpg := TStringList.Create;
  filelstBmp := TStringList.Create;
  SearchFilename(edt1.Text + '\', '.jpg', filelstJpg);
  SearchFilename(edt1.Text + '\', '.bmp', filelstBmp);
  if clcs.ItemIndex=1 then
  begin
    X := 980;
  end
  else
  begin
    X := 980;
  end;
  p:=GetDesktopDir+'\'+'荣成文明传习临时图片';
  if DirectoryExists(p) then
  begin
   // exist
  end
  else
  begin
    CreateDir(p);
  end;

  try
    a := filelstJpg.Count;

    if a <> 0 then
    begin

      mmo1.Lines.Clear;
      for i := 0 to a - 1 do
      begin
        begin
          try
          jpg.LoadFromFile(filelstJpg.Strings[i]);
          Y := round( jpg.Height * X / jpg.Width);
          bmp.height := Y;
          bmp.Width := X;
          bmp.Canvas.StretchDraw(bmp.Canvas.ClipRect, jpg);
          jpg.Assign(bmp);
          jpg.CompressionQuality := Z; //图片压缩后的品质
          jpg.Compress;
          sTemp := filelstJpg.Strings[i];
          sTemp:=StringReplace(stemp,edt1.Text,'',[rfReplaceAll]);
          sTemp:=p+sTemp;
          jpg.SaveToFile(sTemp);
          mmo1.Lines.Add(filelstJpg.Strings[i] + ' 处理完毕！');
          except
          mmo1.Lines.Add(filelstJpg.Strings[i]+' 处理出错！');

          //ShowMessage(filelstJpg.Strings[i]+'处理出错！');
            end;
        end;

      end;
      mmo1.Lines.Add('共 ' + inttostr(a) + ' 个JPG格式图片处理完毕！' + #13#10 );
      mmo1.Lines.Add('处理后的文件存放在桌面【荣成文明传习临时图片】文件夹中' + #13#10 );
      mmo1.Lines.Add('使用完毕后可以将其删除'+#13#10);
    end
    else
    begin
      ShowMessage('未发现JPG格式的图片文件！' + #13#10 )
    end;


  finally
    jpg.Free;
    bmp.Free;
    filelstJpg.free;
    filelstBmp.free;

  end;
end;


procedure TForm1.SearchFilename(const Dir, Ext: string; Files: TStrings);
var
  Found: TSearchRec;
  i: integer;
  Dirs: TStrings;
  Finished: integer;
  StopSearch: Boolean;
begin
  StopSearch := False;
  Dirs := TStringList.Create;
  Finished := FindFirst(Dir + '*.*', 63, Found);
  while (Finished = 0) and not (StopSearch) do
  begin
    if (Found.Name <> '.') then
    begin
      if (Found.Attr and faDirectory) = faDirectory then
        Dirs.Add(Dir + Found.Name)
      else
        if Pos(UpperCase(Ext), UpperCase(Found.Name)) > 0 then
          Files.Add(Dir + Found.Name);
    end;
    Finished := FindNext(Found);
  end;
  FindClose(Found);
  if not StopSearch then
    for i := 0 to Dirs.Count - 1 do
     SearchFilename(Dirs[i], Ext, Files);
  Dirs.Free;
end;

procedure TForm1.FindSubDir(DirName: string; FileString: TStrings);
var
  searchRec: TsearchRec;
begin
//找出所有下级子目录。
  if (FindFirst(DirName + '*.*', faDirectory, SearchRec) = 0) then
  begin
    if IsValidDir(SearchRec) then
      FileString.Add(DirName + SearchRec.Name);
    while (FindNext(SearchRec) = 0) do
    begin
      if IsValidDir(SearchRec) then
        FileString.Add(DirName + SearchRec.Name);
    end;
  end;
  FindClose(SearchRec);
end;

function TForm1.IsValidDir(SearchRec: TSearchRec): Boolean;
begin
  if (SearchRec.Attr = 16) and (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
    Result := True
  else
    Result := False;
end;



procedure TForm1.FormCreate(Sender: TObject);
begin
  X := 480;
  Y := 650;
  Z := 75;
end;




procedure TForm1.Button1Click(Sender: TObject);
begin
  ShellExecute(Handle,'Open','Http://www.rczyz.cn/rcxsdcx/login.php','','',SW_SHOWNORMAL);
end;

end.

