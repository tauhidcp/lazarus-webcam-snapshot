
unit Camera;

{$MODE Delphi}

interface


uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Classes, windows, Controls,
  ExtCtrls, Dialogs, MMSystem, AviCaptura;

{  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, MMSystem, AviCaptura;}


type

  {Tipos de datos usados en la creacion de los eventos}
  TOnFrameVideoEvent =procedure (Sender:TObject;HndPreview:Thandle; lpVHdr:PVideoHdr) of object;
  TOnWaveStreamEvent =procedure (Sender:TObject;HndPreview:Thandle; lpWHdr:PWaveHdr) of object;
  TOnStatusErrorEvent=procedure (Sender:TObject;HndPreview:THandle;id:Integer;lpsz:PChar) of object;
  TOnYieldEvent   =procedure (Sender:TObject;HndPreview:THandle) of object;
  TOnControlEvent =procedure (Sender:TObject;HndPreview:THandle; nState:Integer) of object;

  TCamera = class;

  TCamera = class(TCustomPanel)
   private
    { Private declarations }
    FVideoDriverNombre      : string;
    FFichierVideo           : string;
    FFichierImage          : string;
    FFlagOverlay:Boolean;
    FActif:boolean;
    FOverlay:Boolean;
    FFramesPreview:Integer;
    FFrameCapture:Integer;
    FHiloAparte:Boolean;
    FStrechPreview:Boolean;
    FTiempoActivado:Boolean;
    FSecondes:Integer;
    FDriverInitialise:Boolean;
    FDevice:Integer;
    FHandlePreview:THandle;
    {Eventos}
    FOnFrame:TOnFrameVideoEvent;
    FONVIDEOSTREAM:TOnFrameVideoEvent;
    FONWAVESTREAM:TOnWaveStreamEvent;

    FONERROR:TOnStatusErrorEvent;
    FONSTATUS:TOnStatusErrorEvent;

    FONCONTROL:TOnControlEvent;
    FONYIELD:TOnYieldEvent;

    {instala las funciones de callback, encargadas de enviar los mensajes que haran
    saltar los eventos}
    procedure InstallCallBack;
    procedure DesInstallCallBack;

    {procedimientos encargados de recibir los mensajes, y de activar, en caso de que
    haya sido definido, el manejador de eventos correspondiente. Hay uno por cada
    tipo de mensaje que hemos definido. Aqui es donde se usan los tipos definidos con
    anterioridad}

    function   OpenDriver : Boolean;
    function   InitDriver( Index : Integer ): Boolean;
    procedure  CloseDriver;
    procedure  ShowVideo;
    procedure  ActivOverlay;
    procedure  ActivPrview;
    procedure  SetActif(Valor:boolean);
    procedure  SetOverlay(Valor:boolean);
    procedure  SetStrechView(Valor:Boolean);
    procedure  SetFramesCaptura(Valor:Integer);
    procedure  SetHiloAparte(Valor:Boolean);
    procedure  SetTempActif(Valor:Boolean);
    procedure  SetSecondes(Valor:integer);
    function   GetGrabando:Boolean;
    procedure  Connect;
    procedure  Desconectar;
    function   DialogConfig  : Boolean;
    function   DialogFormat  : Boolean;
    function   DialogDisplay  : Boolean;

  protected
    { Protected declarations }


  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   Paint;override;

    procedure CaptureVideoDisque;
    procedure CaptureVideoSansDisque;
    procedure StopVideo;
    procedure GrabarImagenPortaPapeles;
    procedure CaptureImageDisque;

    procedure SelectConfig;
    procedure SelectFormat;
    procedure SelectCompress;
    procedure SelectDisplay;

    {Propiedad publica, de solo lectura}
    property HandlePreview:THandle read FHandlePreview;
    property Grabando:Boolean read GetGrabando;

  published
    property Actif: boolean read FActif write SetActif default false;
    property FichierVideo:String read FFichierVideo write FFichierVideo;
    property FichierImage:String read FFichierImage write FFichierImage;
    property Overlay:Boolean read FOverlay write SetOverlay default False;
    property FramesPreview:Integer read FFramesPreview write FFramesPreview default 15;
    property FramesCaptura:Integer read FFrameCapture write SetFramesCaptura default 15;
    property HiloAparte:Boolean read FHiloAparte write SetHiloAparte default true;
    property StrechView:Boolean read  FStrechPreview write SetStrechView default True;
    property TiempoActivado:Boolean read FTiempoActivado write SetTempActif default False;
    property Secondes:Integer read FSecondes write SetSecondes default 0;
    property lmageDevice:integer read FDevice write FDevice default 0;
    property Align;
    property Visible;
    property Enabled;

    {eventos}
    property OnFrame:TOnFrameVideoEvent read FOnFrame write FOnFrame;
    property OnVideoStream:TOnFrameVideoEvent read FOnVideoStream write FOnVideoStream;
    property OnWaveStream:TOnWaveStreamEvent read FOnWaveStream write FOnWaveStream;
    property OnError:TOnStatusErrorEvent read FOnError write FOnError;
    property OnStatus:TOnStatusErrorEvent read FOnStatus write FOnStatus;
    property OnControl:TOnControlEvent read FOnControl write FOnControl;
    property OnYield:TOnYieldEvent read FOnYield write FOnYield;

    {hacemos visibles algunos eventos comunes}
    property Onclick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
  end;

procedure Register;

implementation

const ACTIVAR=1;
      DESACTIVAR=0;
      CIERTO=1;
      FALSO=0;
      MAXVIDDRIVERS = 10;
      TEXTO_GRABAR = 'Grabando video';

var     FFramePreview         : THandle;
        FGrabando:Boolean;
        FAreaVideo: TWinControl;
{Funciones de CALLBACK. Estas funciones son llamadas periodicamente cuando se esta
visualizando o capturando video. Cada vez que sean llamadas, enviaran un mensaje al
propio componente, que será recogido por el manejador de mensajes correspondiente, el
cual a su vez llamara (si procede) al manejador de eventos definido por el usuario. Dicho
manejador de eventos recibira una serie de parametros, que se extraen del mensaje que la
funcion de callback envia. El handle que reciben las funciones de callback
es el de la ventana de Preview}

function STATUSCALLBACKProc(HndPreview:HWND; nID:Integer; lpsz:Pchar):LongInt; stdcall;
Var JLCVideo:TCamera;
begin
     case Nid of
          IDS_CAP_BEGIN: FGrabando:=True;
          IDS_CAP_END  : FGrabando:=False;
     end;
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TCamera(FAreaVideo);
     if not (csDesigning in JLCVideo.ComponentState) then
        if (Assigned(JLCVideo.FOnStatus)) then JLCVideo.FOnStatus(TObject(JLCVideo),HndPreview,nid, lpsz);
end;

function ERRORCALLBACKProc(HndPreview:HWND; nID:Integer; lpsz:Pchar):LongInt; stdcall;
Var JLCVideo:TCamera;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TCamera(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnError)) then JLCVideo.FOnError(TObject(JLCVideo),HndPreview,nid, lpsz);
end;

function WAVECALLBACKProc(HndPreview:HWND; lpWHdr:PWavehdr):LongInt; stdcall;
Var JLCVideo:TCamera;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TCamera(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnWaveStream)) then JLCVideo.FOnWaveStream(TObject(JLCVideo),HndPreview,lpWHdr);
end;


function CONTROLCALLBACKProc(HndPreview:HWND; nState:Integer):LongInt; stdcall;
Var JLCVideo:TCamera;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TCamera(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnControl)) then JLCVideo.FOnControl(TObject(JLCVideo),hndPReview, nState);
    Result:=CIERTO;

end;

{funciones de callback}
function YieldCallBackProc(HndPreview:HWND):LongInt; stdcall;
Var JLCVideo:TCamera;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TCamera(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnYield)) then JLCVideo.FOnYield(TObject(JLCVideo),HndPreview);
end;

function VideoCallBackProc(HndPreview:HWND;lp:PVideoHdr):LongInt;stdcall;
Var JLCVideo:TCamera;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TCamera(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnVideoStream)) then JLCVideo.FOnVideoStream(TObject(JLCVideo),HndPreview,lp);
end;

function FrameCallBackProc(HndPreview:HWND;lp:PVideoHdr):LongInt;stdcall;
Var
  JLCVideo:TCamera;
begin
//     Integer(JLCVideo):=CapGetUserData(HndPreview);
     JLCVideo:=TCamera(FAreaVideo);
    if not (csDesigning in JLCVideo.ComponentState) then
       if (Assigned(JLCVideo.FOnFrame)) then JLCVideo.FOnFrame(TObject(JLCVideo),HndPreview,lp);
end;


{implementacion del componente}

constructor TCamera.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  parent:=AOwner as TWinCOntrol;
  width:=304;
  height:=210;
  FAreaVideo:=Self;
  FFramePreview         := 0;
  FVideoDriverNombre      := 'No hay driver';
  FFichierVideo           := 'Video.avi';
  FFichierImage          := 'Imagen.bmp';
  FActif:=False;
  FFramesPreview:=15;
  FFrameCapture:=15;
  FHiloAparte:=True;
  FOverlay:=False;
  FStrechPreview:=True;
  FFlagOverlay:=False;
  FTiempoActivado:=False;
  FSecondes:=0;
  FGrabando:=False;
end;

destructor TCamera.Destroy;
begin
  if FActif then Desconectar;
  inherited Destroy;
end;

procedure TCamera.Paint;
begin
  inherited Paint;
  SetWindowPos(FFramePreview,HWND_TOP,0,0,width,height,SWP_SHOWWINDOW);
end;

function TCamera.GetGrabando:boolean;
begin
     Result:=FGrabando;
end;

procedure TCamera.SetSecondes(Valor:Integer);
Var CapParms         : TCAPTUREPARMS;
begin
   capCaptureGetSetup(FFramePreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
   capParms.wTimeLimit:=Valor;
   capCaptureSetSetup(FFramePreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
end;


procedure TCamera.SetActif(Valor:boolean);
begin
     FActif:=Valor;
     if Valor then    //Activar el video
        Connect
     else
        Desconectar
end;

procedure TCamera.SetTempActif(Valor:Boolean);
var
         Retc             : LongInt;
	 CapParms         : TCAPTUREPARMS;
begin
     FTiempoActivado:=Valor;
     if FFramePreview=0 then exit;
     retc := capCaptureGetSetup(FFramePreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
     if retc <> 0 then
     begin
  	CapParms.fLimitEnabled    := Valor;
        retc := capCaptureSetSetup(FFramePreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
        if retc = 0 then exit;
     end;
end;

procedure TCamera.SetStrechView(Valor:Boolean);
begin
     FStrechPreview:=Valor;
     if FFramePreview=0 then exit;
     if FStrechPreview then
           capPreviewScale(FFramePreview, ACTIVAR)
     else
           capPreviewScale(FFramePreview, DESACTIVAR)
end;


procedure TCamera.SetFramesCaptura(Valor:Integer);
var
         Retc             : LongInt;
	 CapParms         : TCAPTUREPARMS;
begin
     FFrameCapture:=Valor;
     if FFramePreview=0 then exit;
     retc := capCaptureGetSetup(FFramePreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
     if retc <> 0 then
     begin
  	CapParms.dwRequestMicroSecPerFrame    := (1000000 div Valor);
        retc := capCaptureSetSetup(FFramePreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
        if retc = 0 then exit;
     end;
end;


procedure TCamera.SetHiloAparte(Valor:Boolean);
var
         Retc             : LongInt;
	 CapParms         : TCAPTUREPARMS;
begin
     FHiloAparte:=Valor;
     if FFramePreview=0 then exit;
     retc := capCaptureGetSetup(FFramePreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
     if retc <> 0 then
     begin
        CapParms.fYield           := Valor;
        retc := capCaptureSetSetup(FFramePreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
        if retc = 0 then exit;
     end;
end;


procedure  TCamera.SetOverlay(Valor:boolean);
begin
     FOverlay:=Valor;
     ShowVideo;
end;

procedure TCamera.Connect;
begin
  if OpenDriver then
  begin
    SetStrechView(FStrechPreview);
    SetFramesCaptura(FFrameCapture);
    SetStrechView(FStrechPreview);
    SetFramesCaptura(FFrameCapture);
    SetHiloAparte(FHiloAparte);
    SetTempActif(FTiempoActivado);
    SetSecondes(FSecondes);
    ShowVideo;
  end
  else
     raise Exception.Create('Ah merde ! Pas de connection !');
end;

procedure TCamera.InstallCallBack;
begin
     capSetCallBackOnYield(FFramePreview,Longint(@YieldCallBackProc));
     capSetCallbackOnVideoStream(FFramePreview,Longint(@VideoCallBackProc));
     capSetCallbackOnFrame (FFramePreview,Longint(@FrameCallBackProc));
     capSetCallbackOnError (FFramePreview,Longint(@ErrorCallBackProc));
     capSetCallbackOnStatus(FFramePreview,Longint(@StatusCallBackProc));
     capSetCallbackOnWaveStream (FFramePreview,Longint(@WaveCallBackProc));
     capSetCallbackOnCapControl (FFramePreview,Longint(@ControlCallBackProc));
end;

procedure TCamera.DesInstallCallBack;
begin
     capSetCallbackOnFrame (FFramePreview,0);
     capSetCallBackOnYield(FFramePreview,0);
     capSetCallbackOnVideoStream(FFramePreview,0);
     capSetCallbackOnError (FFramePreview,0);
     capSetCallbackOnStatus(FFramePreview,0);
     capSetCallbackOnWaveStream (FFramePreview,0);
     capSetCallbackOnCapControl (FFramePreview,0);
end;



procedure TCamera.ActivOverlay;
begin
	if FFramePreview = 0 then exit;
        capOverlay(FFramePreview, ACTIVAR);
        //desactivamos las callback, por si estabamos en modo preview y estaban activadas
        DesInstallCallBack;
end;

procedure TCamera.ActivPrview;
begin
   	if FFramePreview = 0 then exit;
        //Como ya estamos en modo preview, instalamos las callback
        InstallCallBack;
        capPreviewRate(FFramePreview, 1000 div FFramesPreview);
	capPreview(FFramePreview, ACTIVAR);
end;



procedure TCamera.ShowVideo;
begin
     If FOverlay then
        ActivOverlay
     else
        ActivPrview;
end;


procedure TCamera.Desconectar;
begin
     if (not FOverlay) then DesInstallCallBack; //por si cerramos estando en modo preview
     CloseDriver;
     FActif:=False;
end;


function  TCamera.OpenDriver : Boolean;
var
  achDeviceName    : array [0..80] of Char;
  achDeviceVersion : array [0..100] of Char;
begin
   Result:=False;
  // Crear la ventana de captura y visualización
  FFramePreview := capCreateCaptureWindow( PChar('JLCVideo'),
                    WS_CHILD or WS_VISIBLE, 0, 0,
                    FAreaVideo.Width, FAreaVideo.Height,
                    FAreaVideo.Handle, 0);
{   FFramePreview := capCreateCaptureWindow( PChar('JLCVideo'),
                    WS_CHILD or WS_VISIBLE, 0, 0,
                    Width, Height,
                    Handle, 0);   }
  //Si tenemos éxito en la creación....
  if FFramePreview <> 0 then
  begin
      FHandlePreview:=FFramePreview;
      //Abrir el driver de video del lmageDevice FDevice (normalmente 0)
      FDriverInitialise := InitDriver( FDevice );
      //Si hemos conseguido Connect, obtenemos nombre y versión del driver
      if FDriverInitialise then
      begin
         //obtener el nombre y la version del driver que hemos instalado
         if capGetDriverDescription( FDevice, achDeviceName, 80, achDeviceVersion, 100 ) then
    	           FVideoDriverNombre := string(achDeviceName);
         Result:=TRUE;
      end
      else  //no hemos conseguido Connect, cerramos el driver
      begin
        Result := FALSE;
        CloseDriver;
        FFramePreview := 0;
      end;
  end;
end;


function TCamera.InitDriver( Index : Integer ): Boolean;
var
         Retc             : LongInt;
	 CapParms         : TCAPTUREPARMS;
begin
     Result := FALSE;
     // Nos conectamos al driver de captura de video
     if capDriverConnect(FFramePreview, Index) <> 0 then
     begin
        retc := capCaptureGetSetup(FFramePreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
	if retc <> 0 then
        begin
	  	CapParms.fMCIControl      := FALSE;
	  	CapParms.vKeyAbort        := VK_ESCAPE;
	  	CapParms.fAbortLeftMouse  := FALSE;
	  	CapParms.fAbortRightMouse := FALSE;
                retc := capCaptureSetSetup(FFramePreview, LongInt(@CapParms), sizeof(TCAPTUREPARMS));
                if retc = 0 then exit;
        end;
	Result := TRUE;
     end
     else

         Raise Exception.Create('webcam tidak ditemukan!');
end;

procedure TCamera.CloseDriver;
begin
     if FFramePreview <> 0 then
     begin
	  capSetCallbackOnStatus(FFramePreview, LongInt(0));
	  capDriverDisconnect( FFramePreview );
          DestroyWindow( FFramePreview ) ;
	  FFramePreview := 0;
     end;
end;

procedure TCamera.CaptureImageDisque;
var
	achSingleFileName  : array [0..255] of Char;
begin
	if FFramePreview = 0 then exit;
	capGrabFrameNOStop(FFramePreview);
 	StrPCopy(achSingleFileName, FFichierImage);
	capFileSaveDIB(FFramePreview, LongInt(@achSingleFileName));
end;

procedure TCamera.GrabarImagenPortaPapeles;
begin
	if FFramePreview = 0 then exit;
	capGrabFrameNOStop(FFramePreview);
        capEditCopy(FFramePreview);
end;


procedure TCamera.CaptureVideoDisque;
var
	achFileName  : array [0..255] of Char;
        retc:Integer;
begin
     if FFramePreview = 0 then exit;
     ActivPrview;
     StrPCopy(achFileName, FFichierVideo);
     retc := capFileSetCaptureFile(FFramePreview, LongInt(@achFileName));
     if retc = FALSO then
          showmessage(FVideoDriverNombre+': Error en capFileSetCaptureFile');
     capCaptureSequence( FFramePreview );
end;

procedure TCamera.CaptureVideoSansDisque;
begin
     if FFramePreview = 0 then exit;
     ActivPrview;
     capCaptureSequenceNoFile( FFramePreview );
end;


procedure TCamera.StopVideo;
begin
     if FFramePreview = 0 then exit;
     //If not GetGrabando then Exit;
     capCaptureStop(FFramePreview);
end;

procedure TCamera.SelectFormat;
begin
	if FFramePreview = 0 then exit;
        if DialogFormat then
	   capDlgVideoFormat(FFramePreview)
        else
            raise Exception.Create('Pas bon format !');
end;

procedure  TCamera.SelectDisplay;
begin
	if FFramePreview = 0 then exit;
        if DialogDisplay then
	   capDlgVideoDisplay(FFramePreview)
        else
            raise Exception.Create('Pas bon display !');

end;


procedure TCamera.SelectConfig;
begin
	if FFramePreview = 0 then exit;
        if DialogConfig then
            capDlgVideoSource(FFramePreview)
        else
            raise Exception.Create('Pas bon !');
end;

procedure TCamera.SelectCompress;
begin
	if FFramePreview = 0 then exit;
        capDlgVideoCompression(FFramePreview);
end;


function  TCamera.DialogFormat  : Boolean;
var
  CDrvCaps : TCapDriverCaps;
begin
   Result := TRUE;
   if FFramePreview = 0 then exit;
   capDriverGetCaps(FFramePreview, LongInt(@CDrvCaps), sizeof(TCapDriverCaps));
   Result := CDrvCaps.fHasDlgVideoFormat;
end;

function  TCamera.DialogDisplay : Boolean;
var
  CDrvCaps : TCapDriverCaps;
begin
	Result := TRUE;
	if FFramePreview = 0 then exit;
        capDriverGetCaps(FFramePreview, LongInt(@CDrvCaps), sizeof(TCapDriverCaps));
        Result := CDrvCaps.fHasDlgVideoDisplay;
end;

function  TCamera.DialogConfig  : Boolean;
var
  CDrvCaps : TCapDriverCaps;
begin
  Result := TRUE;
  if FFramePreview = 0 then exit;
  capDriverGetCaps(FFramePreview, LongInt(@CDrvCaps), sizeof(TCapDriverCaps));
  Result := CDrvCaps.fHasDlgVideoSource;
end;

procedure Register;
begin
  RegisterComponents('Yves', [TCamera]);
end;



end.
