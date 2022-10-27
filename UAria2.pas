unit UAria2;

// Simple Aria2 classes for Delphi by Edward Guo

// https://aria2.github.io/manual/en/html/aria2c.html#rpc-interface
// https://aria2.github.io/manual/en/html/libaria2.html

interface

uses
  SysUtils, Classes, IdHttp, System.NetEncoding, JSON, Contnrs, SyncObjs;

const
  CT_APP_JSON = 'application/json';
{$IFDEF MSWINDOWS}
  ARIA2C_EXEC = 'aria2c.exe';
{$ELSE}
  ARIA2C_EXEC = 'aria2c';
{$ENDIF}
  ARIA2_DEF_PORT = 6800;
  ARAI2_DEF_CFG = 'aria2.conf';
  ARIA2_DIR = 'aria2';

  FMT_JRPCID = 'da%d';

  METHOD_ADD_URI = 'aria2.addUri';
  METHOD_ADD_TOR = 'aria2.addTorrent';
  METHOD_ADD_METALINK = 'aria2.addMetalink';
  METHOD_TELL_ACTIVE = 'aria2.tellActive';
  METHOD_TELL_WAITING = 'aria2.tellWaiting';
  METHOD_TELL_STOPPED = 'aria2.tellStopped';
  METHOD_TELL_STATUS = 'aria2.tellStatus';
  METHOD_CHG_POS = 'aria2.changePosition';
  METHOD_PAUSE = 'aria2.pause';
  METHOD_PAUSE_ALL = 'aria2.pauseAll';
  METHOD_FORCE_PAUSE = 'aria2.forcePause';
  METHOD_FORCE_PAUSE_ALL = 'aria2.forcePauseAll';
  METHOD_UNPAUSE = 'aria2.unpause';
  METHOD_UNPAUSE_ALL = 'aria2.unpauseAll';
  METHOD_REMOVE = 'aria2.remove';
  METHOD_FORCE_REMOVE = 'aria2.forceRemove';
  METHOD_GET_FILES = 'aria2.getFiles';
  METHOD_GET_URIS = 'aria2.getUris';
  METHOD_GET_PEERS = 'aria2.getPeers';
  METHOD_GET_SERVERS = 'aria2.getServers';
  METHOD_GET_OPTION= 'aria2.getOption';
  METHOD_GET_GOPTION= 'aria2.getGlobalOption';
  METHOD_GET_GSTAT = 'aria2.getGlobalStat';
  METHOD_REMOVE_DOWNLOAD_RESULT = 'aria2.removeDownloadResult';
  METHOD_GET_VER = 'aria2.getVersion';
  METHOD_SHUTDOWN = 'aria2.shutdown';
  METHOD_FORCE_SHUTDOWN = 'aria2.forceShutdown';
  METHOD_CHG_OPT = 'aria2.changeOption';
  METHOD_CHG_GOPT = 'aria2.changeGlobalOption';
  METHOD_PURGE_RESULT = 'aria2.purgeDownloadResult';

  ARIA2_FLAG_NO_ENCODE = $0001;
  ARIA2_FLAG_PAUSE = $0002;
  ARIA2_FLAG_FILE_NAME = $0004;
  ARIA2_FLAG_TO_HEAD = $0008; // move to head

  ARIA2_ITEM_HTTP = 0;
  ARIA2_ITEM_FTP = 1;
  ARIA2_ITEM_TOR = 2;
  ARIA2_ITEM_MLINK = 3;

type
  TAria2Status = (asUnknown, asError, asRemoved, asComplete, asPaused, asWaiting, asActive);

  TAria2JSONRpc = class
  private
    m_cLock: TCriticalSection;
    m_cHttp: TIdHttp;
    // http://localhost:6800/jsonrpc
    m_sRpcAddr: string;
    m_nID: Integer;
    m_sSecret: string;
    m_bUseGet: Boolean;
    m_nConnectTimeOut: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetHost(const sHost: string; nPort: Integer);
    function Request(const sMethod, sParams: string; dwFlags: UInt32; var sResult: string): Integer;
    function GetResult(var sResult: string): Integer;

    function GetVersion(var sResult: string): Integer;
    function Shutdown(bForce: Boolean; var sResult: string): Integer;
    function AddURI(const sURI, sDir: string; dwFlags: UInt32; var sResult: string): Integer;
    function AddTorrent(const sTorFile, sDir: string; dwFlags: UInt32; var sResult: string): Integer;
    function AddMetalink(const sMLink, sDir: string; dwFlags: UInt32; var sResult: string): Integer;
    function Remove(const sGID: string; bForce: Boolean; var sResult: string): Integer;
    function Pause(const sGID: string; bForce: Boolean; var sResult: string): Integer;
    function UnPause(const sGID: string; var sResult: string): Integer;
    function TellStatus(const sGID: string; const sKeys: string; var sResult: string): Integer;
    function GetURIs(const sGID: string; var sResult: string): Integer;
    function GetFiles(const sGID: string; var sResult: string): Integer;
    function GetPeers(const sGID: string; var sResult: string): Integer;
    function GetServers(const sGID: string; var sResult: string): Integer;
    function TellActive(const sKeys: string; var sResult: string): Integer;
    function TellWaiting(nOfs, nNum: Integer; const sKeys: string; var sResult: string): Integer;
    function TellStopped(nOfs, nNum: Integer; const sKeys: string; var sResult: string): Integer;
    function ChangePosition(const sGID: string; nPos: Integer; const sHow: string; var sResult: string): Integer;
    function GetOption(const sGID: string; var sResult: string): Integer; // sGID='' for global
    function ChangeOption(const sGID, sOptions: string; var sResult: string): Integer;// sGID='' for global
    function RemoveDownloadResult(const sGID: string; var sResult: string): Integer;
    function PurgeDownloadResult(): string;
    function GetGlobalStat(var sResult: string): Integer;
  public
    property ID: Integer read m_nID write m_nID;
    property Secret: string read m_sSecret write m_sSecret;
    property UseGet: Boolean read m_bUseGet write m_bUseGet;
  end;

  TAria2ItemFile = class
  private
    m_nIndex: Integer;
    m_sPath: string;
    m_nTotalLength: Int64;
    m_nCompletedLength: Int64;
    m_bSelected: Boolean;
    m_nHealth: Byte;
    m_sURL: string;
  public
    property Idx: Integer read m_nIndex write m_nIndex;
    property Path: string read m_sPath write m_sPath;
    property TotalLength: Int64 read m_nTotalLength write m_nTotalLength;
    property CompletedLength: Int64 read m_nCompletedLength write m_nCompletedLength;
    property Selected: Boolean read m_bSelected write m_bSelected;
    property URL: string read m_sURL write m_sURL;
    property Health: Byte read m_nHealth write m_nHealth;
  end;

  TAria2ItemFileList = class(TObjectList)
  public
    function LoadFromJson(jv: TJSONArray): Integer;
    function SelectedCount: Integer;
  end;

  TAria2DownloadItem = class
  private
    m_nIndex: Integer;
    m_sName: string;
    m_sGID: string;
    m_sURL: string; // or filename
    m_nType: Integer;  // torrent/http/ftp/mlink
    m_eStatus: TAria2Status;
    m_nTotalLength: Int64;
    m_nCompletedLength: Int64;
    m_nUploadLength: Int64;
    m_nDownSpeed: Integer;
    m_nUpSpeed: Integer;
    m_dtAdded: TDateTime;
    m_sDir: string;
    m_nConnections: Integer;
    m_nPieces: Integer;
    m_nVerifiedLength: Int64;

    m_nSeeders: Integer;
    m_sHash: string;
    m_dtCreate: TDateTime;
    m_sComment: string;

    m_nErrorCode: Integer;
    m_sErrorMsg: string;

    m_cFiles: TAria2ItemFileList;
  protected
    function GetTorrentInfo(jo: TJSONObject): Boolean;
  public
    constructor Create(const sURL, sGID: string);
    destructor Destroy; override;
    function GetFromStatus(const sStatus: string): Boolean; overload;
    function GetFromStatus(jo: TJSONObject): Boolean; overload;
  public
    property Idx: Integer read m_nIndex write m_nIndex;
    property GID: string read m_sGID write m_sGID;
    property Name: string read m_sName write m_sName;
    property URL: string read m_sURL write m_sURL;
    property Dir: string read m_sDir write m_sDir;
    property Typ: Integer read m_nType write m_nType;
    property Status: TAria2Status read m_eStatus write m_eStatus;
    property TotalLength: Int64 read m_nTotalLength write m_nTotalLength;
    property CompletedLength: Int64 read m_nCompletedLength write m_nCompletedLength;
    property DownSpeed: Integer read m_nDownSpeed write m_nDownSpeed;
    property Connections: Integer read m_nConnections write m_nConnections;
    property Added: TDateTime read m_dtAdded write m_dtAdded;
    property UpSpeed: Integer read m_nUpSpeed write m_nUpSpeed;
    property UpLenght: Int64 read m_nUploadLength write m_nUploadLength;
    property Pieces: Integer read m_nPieces write m_nPieces;
    property VerifiedLength: Int64 read m_nVerifiedLength write m_nVerifiedLength;

    property Hash: string read m_sHash write m_sHash;
    property Seeders: Integer read m_nSeeders write m_nSeeders;
    property CreateDate: TDateTime read m_dtCreate write m_dtCreate;
    property Comment: string read m_sComment write m_sComment;

    property ErrorCode: Integer read m_nErrorCode write m_nErrorCode;
    property ErrorMessage: string read m_sErrorMsg write m_sErrorMsg;
    property Files: TAria2ItemFileList read m_cFiles;
  end;

  TAria2DownloadList = class(TObjectList)
  private
  public
    function LoadFromResult(const sRet: string): Integer;
    function GetList(cResult: TStrings): Integer;
  end;

  TAria2GetListThread = class;

  TAria2Delphi = class
  private
    m_cRPC: TAria2JSONRpc;
    m_cDownloadList: TAria2DownloadList;
    m_dtUpdate: TDateTime;
    m_cLock: TCriticalSection;
    m_cGetListThrd: TAria2GetListThread;
    m_eOnUpdateList: TThreadProcedure;
    procedure SetOnUpdateList(const Value: TThreadProcedure);
  public
    constructor Create;
    destructor Destroy; override;
    function MakeSureRunAria2: Integer;
    function IsAria2Running(nPort: Integer): Boolean;
    function DownloadURL(const sURL, sDir: string; dwFlags: UInt32; var sGID: string): Integer;
    function DownloadTorrent(const sTorFile, sDir, sSelected: string; dwFlags: UInt32; var sGID: string): Integer;
    function GetDownloadList(cResult: TStrings; bUpdNow: Boolean): Integer;
    function QuitAria2(bForce: Boolean): Integer;
    function DeleteDownload(const sGID: string; var sMsg: string): Integer;
    function Pause(const sGID: string; bPause: Boolean; var sMsg: string): Integer;
    function MoveTo(const sGID, sPos: string; var sMsg: string): Integer;
  public
    property DownloadList: TAria2DownloadList read m_cDownloadList;
    property RPC: TAria2JSONRpc read m_cRPC;
    property OnUpdateList: TThreadProcedure read m_eOnUpdateList write SetOnUpdateList;
  end;

  TAria2GetListThread = class(TThread)
  private
    m_nSleep: Integer;
    m_cAria2: TAria2Delphi;
  protected
    procedure Execute; override;
  public
    constructor Create(cAria2: TAria2Delphi; nSleep: Integer);
  end;

var
  g_yAria2Status: array[TAria2Status] of string = ('Unknown', 'Error',
    'Removed', 'Complete', 'Paused', 'Waiting', 'Active');

  g_sAria2Dir: string = ARIA2_DIR + PathDelim;
  g_cAria2Inst: TAria2Delphi = nil;
  g_nAria2Port: Integer = ARIA2_DEF_PORT;
  g_nStartAria2: Integer = 1; 
  g_bAunAria2: Boolean = False; // run by me
  g_nGetDownloadListWait: Integer = 1000;
  g_nRunAria2Flags: UInt32 = 1;
  g_bLetArai2Run: Boolean = False;

function GetAria2ExecPath: string;
function CreateGlobalAira2Instance: Boolean;
function GetAria2StatusText(eStatus: TAria2Status): string; inline;

implementation

{$IFDEF MSWINDOWS}
uses
  Windows;
{$ENDIF}

function RunEXE (const sEXE: string; bHide: Boolean; dwWait: UInt32): Boolean;
{$IFDEF MSWINDOWS}
var
  szEXE: array[0..MAX_PATH] of Char;
  rSI: TStartUpInfo;
  rPI: TProcessInformation;
begin
  StrPCopy(szEXE, sEXE);
  // Set startup info
  FillChar(rSI, sizeof(rSI), 0);
  rSI.cb := sizeof(rSI);
  rSI.dwFlags:= STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK or STARTF_USESTDHANDLES;

  if not bHide then rSI.wShowWindow := SW_SHOWNORMAL else
    rSI.wShowWindow:= SW_HIDE;
  // Fill process info
  FillChar(rPI, sizeof(rPI), 0);

  Result := CreateProcess(nil,szEXE,nil,nil,False,0,nil,nil,rSI,rPI);

  if (Result) then
  begin
    CloseHandle(rPI.hThread);
    if dwWait>0 then WaitForInputIdle(rPI.hProcess, dwWait);
    CloseHandle(rPI.hProcess);
  end;
end;
{$ELSE}
begin
  Result := False;
  // TODO
//string command = "open " + filePath;
//system(command.c_str());
end;
{$ENDIF}

function SpanOfNowAndThen(const ANow, AThen: TDateTime): TDateTime; inline;
begin
  if ANow < AThen then
    Result := AThen - ANow
  else
    Result := ANow - AThen;
end;

function SecondSpan(const ANow, AThen: TDateTime): Double; inline;
begin
  Result := SecsPerDay * SpanOfNowAndThen(ANow, AThen);
end;

function GetAria2StatusText(eStatus: TAria2Status): string;
begin
  Result := g_yAria2Status[eStatus];
end;

function GetAria2ExecPath: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + g_sAria2Dir;
end;

function CreateGlobalAira2Instance: Boolean;
begin
  if g_cAria2Inst=nil then
  begin
    g_cAria2Inst := TAria2Delphi.Create;
  end;
  Result := g_cAria2Inst.MakeSureRunAria2=0;
end;

{ TAria2Delphi }

constructor TAria2Delphi.Create;
begin
  m_cRPC := TAria2JSONRpc.Create;
  m_cLock := TCriticalSection.Create;
  m_cDownloadList := TAria2DownloadList.Create;
  m_cGetListThrd := TAria2GetListThread.Create(Self, g_nGetDownloadListWait);
  inherited;
end;

destructor TAria2Delphi.Destroy;
begin
  m_cGetListThrd.Terminate;
  if g_bAunAria2 and (not g_bLetArai2Run) then
  begin
    QuitAria2(False);
  end;
  m_cRPC.Free;
  m_cDownloadList.Free;
   m_cLock.Free;
  inherited;
end;

function TAria2Delphi.DownloadTorrent(const sTorFile, sDir, sSelected: string;
  dwFlags: UInt32; var sGID: string): Integer;
var
  cItem: TAria2DownloadItem;
  sParams, sRet: string;
  i, j: Integer;
  s: string;
begin
  sGID := '';
  Result := m_cRPC.AddTorrent(sTorFile, sDir, ARIA2_FLAG_PAUSE, sGID);
  if Result<>0 then Exit;

  if sGID<>'' then
  begin
    cItem := TAria2DownloadItem.Create(sTorFile, sGID);
    if m_cDownloadList.Add(cItem)<0 then
    begin
      cItem.Free;
      Exit;
    end;

    if (Length(sGID)>0) and (Length(sSelected)>0) then
    begin
      sParams := Format('"select-file":"%s"', [sSelected]);
      m_cRPC.ChangeOption(sGID, sParams, sRet);
    end;
    m_cRPC.UnPause(sGID, sRet); //'[{"bittorrent"...},{}]'
    Result := 0;
    if m_cRPC.TellStatus(sGID, '"gid","errorCode","errorMessage"', sRet)=0 then
    begin
      // {"status":"error","errorCode":"12"}
      i := Pos('"errorCode"', sRet);
      if i>0 then
      begin
        sParams := Copy(sRet, i+11, 20);
        i := Pos('"', sParams);      // :"12", i=2,j=5
        j := Pos('"', sParams, i+1);
        if (i>0) and (j>0) then
        begin
          s := Copy(sParams, i+1, j-i-1);
          i := StrToIntDef(s, 0);
          sGID := sRet;  // whole message
          Result := i; // ARIA2 error code
        end;
      end;
    end;
    GetDownloadList(nil, True);
  end;
end;

function TAria2Delphi.DownloadURL(const sURL, sDir: string; dwFlags: UInt32;
  var sGID: string): Integer;
begin
  Result := m_cRPC.AddURI(sURL, sDir, dwFlags, sGID);
end;

function TAria2Delphi.GetDownloadList(cResult: TStrings; bUpdNow: Boolean): Integer;
var
  sRet, sKeys: string;
  i: Integer;
  cItem: TAria2DownloadItem;
  eNotify: TThreadProcedure;
begin
  if bUpdNow then
  begin
    sKeys := '';
    m_cLock.Enter;
    try
      m_cDownloadList.Clear;
      i := m_cRPC.TellStopped(-1, 2000, '', sRet);
      if i=0 then
      begin
        m_cDownloadList.LoadFromResult(sRet);
        for i := m_cDownloadList.Count-1 downto 0 do
        begin
          cItem := TAria2DownloadItem(m_cDownloadList[i]);
          case cItem.ErrorCode of
          0:
            begin
              // TODO: remove succ and begin to analyze
              m_cRPC.RemoveDownloadResult(cItem.GID, sRet);
            end;
          11, 12:
            begin
              // dup, delete
              m_cRPC.RemoveDownloadResult(cItem.GID, sRet);
            end;
          end;
        end;
      end else
      begin
        if i<0 then // no server
        begin
          Result := i;
          Exit;
        end;
      end;
      m_cDownloadList.Clear;
      if m_cRPC.TellActive(sKeys, sRet)=0 then m_cDownloadList.LoadFromResult(sRet);
      if m_cRPC.TellWaiting(-1, 2000, '', sRet)=0 then m_cDownloadList.LoadFromResult(sRet);
      if m_cRPC.TellStopped(-1, 2000, '', sRet)=0 then m_cDownloadList.LoadFromResult(sRet);
      m_dtUpdate := Now;
      if cResult<>nil then m_cDownloadList.GetList(cResult);
      Result := m_cDownloadList.Count;
      eNotify := m_eOnUpdateList;
    finally
      m_cLock.Leave;
    end;
    if Assigned(eNotify) then // take outside to avoid dead lock
      TThread.Synchronize(nil, eNotify);
  end else
  begin
    m_cLock.Enter;
    if cResult<>nil then m_cDownloadList.GetList(cResult);
    Result := m_cDownloadList.Count;
    m_cLock.Leave;
  end;
end;

function TAria2Delphi.IsAria2Running(nPort: Integer): Boolean;
var
  sRet: string;
begin
  m_cRPC.SetHost('', g_nAria2Port);
  if m_cRPC.GetVersion(sRet)=0 then
  begin
    Result := True;
    Exit;
  end;
  Result := False;
end;

function TAria2Delphi.QuitAria2(bForce: Boolean): Integer;
var
  sRet: string;
begin
  Result := m_cRPC.Shutdown(bForce, sRet);
  g_bAunAria2 := False;
end;

procedure TAria2Delphi.SetOnUpdateList(const Value: TThreadProcedure);
begin
  m_cLock.Enter;
  m_eOnUpdateList := Value;
  m_cLock.Leave;
end;

function RunAria2: Boolean;
var
  sOld, s: string;
  bHide: Boolean;
begin
  // TODO: pipe stdout
  //CreatePipe(vStdInPipe.Output, vStdInPipe.Input, @vSecurityAttributes, 0)
  Result := False;
  sOld := GetCurrentDir();
  try
    SetCurrentDir(GetAria2ExecPath);
    s := Format('%s --enable-rpc --rpc-listen-port=%d --conf-path=%s', //--quiet
      [ARIA2C_EXEC, g_nAria2Port, ARAI2_DEF_CFG]);
    bHide := g_nRunAria2Flags and $01<>0;
    if RunExe(s, bHide, 2000) then
    begin
      Result := True;
      g_bAunAria2 := True;
    end;
  finally
    SetCurrentDir(sOld);
  end;
end;

function TAria2Delphi.MakeSureRunAria2: Integer;
begin
  if IsAria2Running(g_nAria2Port) then
  begin
    Result := 0;
    Exit;
  end;

  Result := -1;
  if RunAria2 then
  begin
    Sleep(500);
    if IsAria2Running(g_nAria2Port) then Result := 0;
  end;
end;

function TAria2Delphi.MoveTo(const sGID, sPos: string; var sMsg: string): Integer;
var
  s, sHow: string;
  nPos: Integer;
begin
  sHow := 'POS_SET';
  nPos := 0;
  s := AnsiLowercase(sPos);
  if s='' then
  begin
    Result := -2;
    Exit;
  end else
  begin
    if s='end' then
    begin
      sHow := 'POS_END';
    end else
    begin
      case s[1] of
      '+', '-': sHow := 'POS_CUR';  
      end;    
      nPos := StrToIntDef(s, 0);
    end;
  end;

  Result := m_cRPC.ChangePosition(sGID, nPos, sHow, sMsg);
end;

function TAria2Delphi.Pause(const sGID: string; bPause: Boolean; var sMsg: string): Integer;
begin
  if bPause then m_cRPC.Pause(sGID, True, sMsg) else
    m_cRPC.UnPause(sGID, sMsg);
end;

function TAria2Delphi.DeleteDownload(const sGID: string; var sMsg: string): Integer;
begin
  Result := m_cRPC.Remove(sGID, True, sMsg);
  if Result=0 then m_cRPC.PurgeDownloadResult;
end;

function GetDirJson(const sDir: string): string;
var
  i, j, n: Integer;
begin
  n := Length(sDir);
  SetLength(Result, 2*n);
  if (n>0) then
    case sDir[n] of
    '\', '/': Dec(n);
    end;

  j := 0;
  for i := 1 to n do
  begin
    Inc(j);
    case sDir[i] of
    '\':
      begin
        Result[j] := '\';
        Inc(j);
      end;
    end;
    Result[j] := sDir[i];
  end;
  SetLength(Result, j);
end;

{ TAria2JSONRpc }

function TAria2JSONRpc.AddMetalink(const sMLink, sDir: string; dwFlags: UInt32;
  var sResult: string): Integer;
var
  sParams, sExtParams: string;
begin
  sParams := '"'+sMLink+'"';
  sExtParams := '';
  if dwFlags and ARIA2_FLAG_PAUSE<>0 then sExtParams := sExtParams+'"pause":"true"';
  if sDir<>'' then
  begin
    if sExtParams<>'' then sExtParams := sExtParams+',';
    sExtParams := sExtParams+Format('"dir":"%s"', [GetDirJson(sDir)]);
  end;
  if sExtParams<>'' then
    sParams := sParams + ',{'+sExtParams+'}';

  Result := Request(METHOD_ADD_METALINK, sParams, 0, sResult);
end;

function TAria2JSONRpc.AddTorrent(const sTorFile, sDir: string; dwFlags: UInt32;
  var sResult: string): Integer;
var
  sExtParams, sParams: string;
  cEnc64: TBase64Encoding;
  cTorFile: TFileStream;
  cOutStm: TStringStream;
begin
//{
//	"jsonrpc": "2.0",
//	"method": "aria2.addTorrent",
//	"id": "xxx",
//	"params": ["token:xxxxx", "torrentµÄbase64Öµ", [], {}]
//}

{
aria2.addTorrent([secret, ]torrent[, uris[, options[, position]]])

This method adds a BitTorrent download by uploading a ".torrent" file.
If you want to add a BitTorrent Magnet URI, use the aria2.addUri() method instead.
torrent must be a base64-encoded string containing the contents of the ".torrent" file.
uris is an array of URIs (string). uris is used for Web-seeding.
For single file torrents, the URI can be a complete URI pointing to the resource;
if URI ends with /, name in torrent file is added. For multi-file torrents,
name and path in torrent are added to form a URI for each file.
options is a struct and its members are pairs of option name and value.
See Options below for more details. If position is given,
it must be an integer starting from 0. The new download will be inserted at 
position in the waiting queue. If position is omitted or position is larger 
than the current size of the queue, the new download is appended to the end of the queue.
This method returns the GID of the newly registered download.
If --rpc-save-upload-metadata is true, the uploaded data is saved as a file
named as the hex string of SHA-1 hash of data plus ".torrent" in the directory
specified by --dir option.
E.g. a file name might be 0a3893293e27ac0490424c06de4d09242215f0a6.torrent.
If a file with the same name already exists, it is overwritten!
If the file cannot be saved successfully or --rpc-save-upload-metadata is false,
the downloads added by this method are not saved by --save-session.
}

  cTorFile := TFileStream.Create(sTorFile, fmOpenRead or fmShareDenyNone);
  cOutStm := TStringStream.Create;
  cEnc64 := TBase64Encoding.Create;
  try
    cEnc64.Encode(cTorFile, cOutStm);
    sParams := '"'+cOutStm.DataString+'"';
  finally
    cEnc64.Free;
    cOutStm.Free;
    cTorFile.Free;
  end;
  sExtParams := '';
  if dwFlags and ARIA2_FLAG_PAUSE<>0 then sExtParams := sExtParams+'"pause":"true"';
  if sDir<>'' then
  begin
    if sExtParams<>'' then sExtParams := sExtParams+',';
    sExtParams := sExtParams+Format('"dir":"%s"', [GetDirJson(sDir)]);
  end;
  if sExtParams<>'' then
    sParams := Format('%s,[],{%s}', [sParams, sExtParams]);
  if dwFlags and ARIA2_FLAG_TO_HEAD<>0 then
  begin
    sParams := sParams+',0';
  end;
  Result := Request(METHOD_ADD_TOR, sParams, ARIA2_FLAG_NO_ENCODE, sResult);
end;

function TAria2JSONRpc.AddURI(const sURI, sDir: string; dwFlags: UInt32;
  var sResult: string): Integer;
var
  sParams, sExtParams: string;
begin
//{
//    "jsonrpc": "2.0",
//    "id": "10",
//    "method": "aria2.addUri",
//    "params":
//    [
//        [
//            "http://url/to/a.torrent"
//        ],
//        {
//            "pause": "true",
//            'dir': 'D:\Downloads',
//            'out': 'button.png'
//        }
//    ]
//}
  sParams := '["'+sURI+'"]';
  sExtParams := '';
  if dwFlags and ARIA2_FLAG_PAUSE<>0 then sExtParams := sExtParams+'"pause":"true"';
  if sDir<>'' then
  begin
    if sExtParams<>'' then sExtParams := sExtParams+',';
    sExtParams := sExtParams+Format('"dir":"%s"', [GetDirJson(sDir)]);
  end;
  if sExtParams<>'' then
    sParams := sParams + ',{'+sExtParams+'}';

  Result := Request(METHOD_ADD_URI, sParams, 0, sResult);
end;

function TAria2JSONRpc.ChangeOption(const sGID, sOptions: string; var sResult: string): Integer;
begin
  if sGID<>'' then
    Result := Request(METHOD_CHG_OPT, Format('"%s",{%s}', [sGID, sOptions]), 0, sResult)
  else
    Result := Request(METHOD_CHG_GOPT, Format('{%s}', [sOptions]), 0, sResult);
end;

function TAria2JSONRpc.ChangePosition(const sGID: string; nPos: Integer;
  const sHow: string; var sResult: string): Integer;
begin
  // Works only in waiting queue
  // errorCode=1 GID#c17e3d141b357d90 not found in the waiting queue.
  Result := Request(METHOD_CHG_POS, Format('"%s",%d,"%s"', [sGID, nPos, sHow]), 0, sResult);
end;

constructor TAria2JSONRpc.Create;
begin
  m_cLock := TCriticalSection.Create;
  m_cHttp := TIdHttp.Create(nil);
  m_cHttp.Request.Accept := CT_APP_JSON;
  SetHost('127.0.0.1', ARIA2_DEF_PORT);
  inherited;
end;

destructor TAria2JSONRpc.Destroy;
begin
  FreeAndNil(m_cHttp);
  FreeAndNil(m_cLock);
  inherited;
end;

function TAria2JSONRpc.GetResult(var sResult: string): Integer;
var
  jv: TJSONValue;
  jo: TJSONObject;
  jp: TJSONPair;
  sVer: string;
  sID: string;
begin
  Result := -1;
  //{"id":"pfm1","jsonrpc":"2.0","result":"71f4d6f726bcc8f7"}
  //{"jsonrpc": "2.0", "result": "gid", "id": 2}
  //{"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "1"}
  //PFMLog(sResult, False);
  jv := TJSONObject.ParseJSONValue(sResult);
  try
    if jv is TJSONObject then
    begin
      Result := -2;
      jo := TJSONObject(jv);
      jp := jo.Get('jsonrpc');
      if jp<>nil then
      begin
        sVer := jp.JsonValue.Value;
        jp := jo.Get('id');
        if jp<>nil then
        begin
          sID := jp.JsonValue.Value;
          Result := -3;
          if sID=Format(FMT_JRPCID, [m_nID]) then
          begin
            jp := jo.Get('result');
            if jp<>nil then
            begin
              if (jp.JsonValue is TJSONString) then
              begin
                sResult := jp.JsonValue.Value;
              end else
              //if jp.JsonValue is TJSONArray then
              begin
                sResult := jp.JsonValue.ToJSON;
              end;
              Result := 0;
            end else
            begin
              jp := jo.Get('error');
              if jp<>nil then
              begin
                jo := TJSONObject(jp);
                jp := jo.Get('code');
                if jp<>nil then
                  Result := StrToIntDef(jp.JsonValue.Value, -4);
                jp := jo.Get('message');
                if jp<>nil then
                  sResult := jp.JsonValue.Value;
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    jv.Free;
  end;
end;

function TAria2JSONRpc.GetServers(const sGID: string;
  var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_SERVERS, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.GetFiles(const sGID: string; var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_FILES, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.GetGlobalStat(var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_GSTAT, '', 0, sResult);
end;

function TAria2JSONRpc.GetOption(const sGID: string; var sResult: string): Integer;
begin
  if sGID<>'' then
    Result := Request(METHOD_GET_OPTION, '"'+sGID+'"', 0, sResult)
  else
    Result := Request(METHOD_GET_GOPTION, '', 0, sResult);
end;

function TAria2JSONRpc.GetPeers(const sGID: string;
  var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_PEERS, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.GetURIs(const sGID: string; var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_URIS, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.GetVersion(var sResult: string): Integer;
begin
  Result := Request(METHOD_GET_VER, '', 0, sResult);
end;

function TAria2JSONRpc.Pause(const sGID: string; bForce: Boolean; var sResult: string): Integer;
begin
  if sGID='' then
  begin
    if bForce then
      Result := Request(METHOD_FORCE_PAUSE_ALL, '', 0, sResult)
    else
      Result := Request(METHOD_PAUSE_ALL, '', 0, sResult);
  end else
  begin
    if bForce then
      Result := Request(METHOD_FORCE_PAUSE, '"'+sGID+'"', 0, sResult)
    else
      Result := Request(METHOD_PAUSE, '"'+sGID+'"', 0, sResult);
  end;
end;

function TAria2JSONRpc.PurgeDownloadResult: string;
begin
  Request(METHOD_PURGE_RESULT, '', 0, Result);
end;

function TAria2JSONRpc.Remove(const sGID: string; bForce: Boolean; var sResult: string): Integer;
begin
  if bForce then
    Result := Request(METHOD_FORCE_REMOVE, '"'+sGID+'"', 0, sResult)
  else
    Result := Request(METHOD_REMOVE, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.RemoveDownloadResult(const sGID: string; var sResult: string): Integer;
begin
  Result := Request(METHOD_REMOVE_DOWNLOAD_RESULT, '"'+sGID+'"', 0, sResult);
end;

function TAria2JSONRpc.Request(const sMethod, sParams: string;
  dwFlags: UInt32; var sResult: string): Integer;
var
  sReq, s: string;
  cStm: TStringStream;
  cEnc64: TBase64Encoding;
begin
  m_cLock.Enter;
  try
    Inc(m_nID);
    //jsonrpc?method=METHOD_NAME&id=ID&params=BASE64_ENCODED_PARAMS
    if m_bUseGet then
    begin
      if dwFlags and ARIA2_FLAG_NO_ENCODE=0 then
      begin
        cEnc64 := TBase64Encoding.Create;
        sReq := cEnc64.Encode(sParams);
        cEnc64.Free;
      end else
        sReq := sParams;
      sResult := m_cHttp.Get(Format('%s?method=%s&id='+FMT_JRPCID+'&params=%s',
        [m_sRpcAddr, sMethod, m_nID, sReq]));
    end else
    begin
      if dwFlags and ARIA2_FLAG_NO_ENCODE=0 then
        s := UTF8Encode(sParams) else
        s := sParams;
      if m_sSecret<>'' then
        s := '"token:'+m_sSecret+'",'+s;
      sReq := Format('{"jsonrpc":"2.0","id":"'+FMT_JRPCID+'","method":"%s","params":[%s]}',
        [m_nID, sMethod, s]);

      m_cHttp.Request.ContentType := CT_APP_JSON;
      if m_cHttp.IOHandler=nil then
        m_cHttp.CreateIOHandler();
      if m_nConnectTimeOut>0 then
        m_cHttp.IOHandler.ConnectTimeout := m_nConnectTimeOut;
      cStm := TStringStream.Create(sReq);
      try
        sResult := m_cHttp.Post(m_sRpcAddr, cStm);
      finally
        cStm.Free;
      end;
    end;
    Result := m_cHttp.ResponseCode;
    if Result<300 then
      Result := GetResult(sResult);
  except
    Result := m_cHttp.ResponseCode;
    sResult := m_cHttp.ResponseText;
    if sResult='' then
    begin
      sResult := Format('Error code=%d', [Result]);
    end;
  end;
  m_cLock.Leave;
end;

procedure TAria2JSONRpc.SetHost(const sHost: string; nPort: Integer);
var
  s: string;
begin
  s := sHost;
  if s='' then s := '127.0.0.1';
  if nPort<=0 then nPort := ARIA2_DEF_PORT;
  m_sRpcAddr := Format('http://%s:%d/jsonrpc', [s, nPort]);
end;

function TAria2JSONRpc.Shutdown(bForce: Boolean; var sResult: string): Integer;
begin
  if bForce then
    Result := Request(METHOD_FORCE_SHUTDOWN, '', 0, sResult)
  else
    Result := Request(METHOD_SHUTDOWN, '', 0, sResult);
end;

function TAria2JSONRpc.TellActive(const sKeys: string; var sResult: string): Integer;
var
  sParams: string;
begin
  if sKeys<>'' then sParams := '['+sKeys+']' else sParams := '';
  Result := Request(METHOD_TELL_ACTIVE, sParams, 0, sResult);
end;

function TAria2JSONRpc.TellStatus(const sGID, sKeys: string; var sResult: string): Integer;
var
  sAddParams: string;
begin
  if sKeys<>'' then sAddParams := ',['+sKeys+']' else sAddParams := '';
  Result := Request(METHOD_TELL_STATUS, Format('"%s"%s', [sGID, sAddParams]), 0, sResult);
end;

function TAria2JSONRpc.TellStopped(nOfs, nNum: Integer; const sKeys: string; var sResult: string): Integer;
var
  sAddParams: string;
begin
  if sKeys<>'' then sAddParams := ',['+sKeys+']' else sAddParams := '';
  Result := Request(METHOD_TELL_STOPPED, Format('%d,%d%s', [nOfs, nNum, sAddParams]), 0, sResult);
end;

function TAria2JSONRpc.TellWaiting(nOfs, nNum: Integer; const sKeys: string; var sResult: string): Integer;
var
  sAddParams: string;
begin
  if sKeys<>'' then sAddParams := ',['+sKeys+']' else sAddParams := '';
  Result := Request(METHOD_TELL_WAITING, Format('%d,%d%s', [nOfs, nNum, sAddParams]), 0, sResult);
end;

function TAria2JSONRpc.UnPause(const sGID: string; var sResult: string): Integer;
begin
  if sGID='' then
    Result := Request(METHOD_UNPAUSE_ALL, '', 0, sResult)
  else
    Result := Request(METHOD_UNPAUSE, '"'+sGID+'"', 0, sResult);
end;


{ TAria2DownloadItem }

constructor TAria2DownloadItem.Create(const sURL, sGID: string);
begin
  m_sURL := sURL;
  m_sGID := sGID;
  m_dtAdded := Now;
  m_cFiles := TAria2ItemFileList.Create;
  inherited Create;
end;

function TAria2DownloadItem.GetFromStatus(const sStatus: string): Boolean;
var
  jv: TJSONValue;
  jo: TJSONObject;
begin
  Result := False;
  try
    jv := TJSONObject.ParseJSONValue(sStatus);
    if jv is TJSONObject then
    try
      jo := TJSONObject(jv);
      Result := GetFromStatus(jo);
    finally
      jv.Free;
    end;
    Result := True;
  except
  end;
end;

function TAria2DownloadItem.GetTorrentInfo(jo: TJSONObject): Boolean;
var
  jo1: TJSONObject;
  jp: TJSONPair;
  n: Int64;
  V: Double;
begin
  Result := False;

  jp := jo.Get('creationDate');
  if jp<>nil then
  begin
    n := StrToInt64Def(jp.JsonValue.Value, 0);
    if n>0 then
    begin
      V := SecondSpan(Now, 25569);
      V := (V - n) / SecsPerDay;
      m_dtCreate := Now - V
    end;
  end;

  jp := jo.Get('comment');
  if jp<>nil then
  begin
    m_sComment := jp.JsonValue.Value;
  end;

  jp := jo.Get('info');
  if jp<>nil then
  begin
    jo1 := TJSONObject(jp.JsonValue);
    jp := jo1.Get('name');
    if jp<>nil then
      m_sName := jp.JsonValue.Value;
    Result := True;
  end;
end;

destructor TAria2DownloadItem.Destroy;
begin
  m_cFiles.Free;
  inherited;
end;

function TAria2DownloadItem.GetFromStatus(jo: TJSONObject): Boolean;
var
  btjo: TJSONObject;
  jp: TJSONPair;
  s: string;
begin
  Result := False;
  jp := jo.Get('index');
  if jp<>nil then
    m_nIndex := StrToIntDef(jp.JsonValue.Value, 0);

  jp := jo.Get('errorCode');
  if jp<>nil then
    m_nErrorCode := StrToIntDef(jp.JsonValue.Value, 0);
  jp := jo.Get('errorMessage');
  if jp<>nil then
    m_sErrorMsg := jp.JsonValue.Value;

  jp := jo.Get('gid');
  if jp<>nil then
  begin
    Result := True;
    m_sGID := jp.JsonValue.Value;
  end;
  jp := jo.Get('dir');
  if jp<>nil then
    m_sDir := jp.JsonValue.Value;

  jp := jo.Get('downloadSpeed');
  if jp<>nil then
    m_nDownSpeed := StrToIntDef(jp.JsonValue.Value, 0);
  jp := jo.Get('completedLength');
  if jp<>nil then
    m_nCompletedLength := StrToInt64Def(jp.JsonValue.Value, 0);
  jp := jo.Get('totalLength');
  if jp<>nil then
    m_nTotalLength := StrToInt64Def(jp.JsonValue.Value, 0);
  jp := jo.Get('connections');
  if jp<>nil then
    m_nConnections := StrToIntDef(jp.JsonValue.Value, 0);
  jp := jo.Get('uploadSpeed');
  if jp<>nil then
    m_nUpSpeed := StrToIntDef(jp.JsonValue.Value, 0);
  jp := jo.Get('uploadLength');
  if jp<>nil then
    m_nUploadLength := StrToInt64Def(jp.JsonValue.Value, 0);
  jp := jo.Get('numPieces');
  if jp<>nil then
    m_nPieces := StrToIntDef(jp.JsonValue.Value, 0);
  jp := jo.Get('verifiedLength');
  if jp<>nil then
    m_nVerifiedLength := StrToInt64Def(jp.JsonValue.Value, 0);

  jp := jo.Get('status');
  if jp<>nil then
  begin
    s := AnsiLowercase(jp.JsonValue.Value);
    if s='active' then m_eStatus := asActive
    else if s='paused' then m_eStatus := asPaused
    else if s='waiting' then m_eStatus := asWaiting
    else if s='complete ' then m_eStatus := asComplete
    else if s='removed' then m_eStatus := asRemoved
    else if s='error' then m_eStatus := asError
    else m_eStatus := asUnknown;
  end;

  jp := jo.Get('files');
  if jp<>nil then
  begin
    if jp.JsonValue is TJSONArray then
      m_cFiles.LoadFromJson(TJSONArray(jp.JsonValue));
  end;

  jp := jo.Get('bittorrent');
  if jp<>nil then
  begin
    btjo := TJSONObject(jp.JsonValue);
    GetTorrentInfo(btjo);
    m_nType := ARIA2_ITEM_TOR;
    jp := jo.Get('infoHash');
    if jp<>nil then
      m_sHash := jp.JsonValue.Value;
    jp := jo.Get('numSeeders');
    if jp<>nil then
      m_nSeeders := StrToIntDef(jp.JsonValue.Value, 0);
  end else
  begin
    // TODO: http/ftp/mlink
  end;
end;

{ TAria2DownloadList }

function TAria2DownloadList.GetList(cResult: TStrings): Integer;
var
  i: Integer;
  cItem: TAria2DownloadItem;
  s: string;
begin
  Result := Count;
  cResult.BeginUpdate;
  for i := 0 to Count-1 do
  begin
    cItem := TAria2DownloadItem(Get(i));
    s := Format('Type=%d;Name=%s;GID=%s;Status=%s;Code=%d;SpeedDown=%d;SpeedUp=%d;'+
     'Total=%d;Current=%d;Connection=%d;Seed=%d;Files=%d/%d;Dir=%s;URL=%s',
      [cItem.Typ, cItem.Name, cItem.GID, GetAria2StatusText(cItem.Status),
       cItem.ErrorCode, cItem.DownSpeed, cItem.UpSpeed, cItem.TotalLength,
       cItem.CompletedLength, cItem.Connections, cItem.Seeders,
       cItem.Files.SelectedCount, cItem.Files.Count, cItem.Dir, cItem.URL]);
    cResult.AddObject(s, cItem);
  end;
  cResult.EndUpdate;
end;

function TAria2DownloadList.LoadFromResult(const sRet: string): Integer;
var
  jv: TJSONValue;
  ja: TJSONArray;
  jo: TJSONObject;
  i: Integer;
  cItem: TAria2DownloadItem;
begin
  Result := 0;
  try
    jv := TJSONObject.ParseJSONValue(sRet);
    if jv is TJSONArray then
    try
      ja := TJSONArray(jv);
      for i := 0 to ja.Count-1 do
      begin
        jo := TJSONObject(ja.Items[i]);
        cItem := TAria2DownloadItem.Create('', '');
        if cItem.GetFromStatus(jo) then
        begin
          if Add(cItem)<0 then cItem.Free;
        end else
          cItem.Free;
      end;
    finally
      jv.Free;
    end;
  except
  end;
end;

{ TAria2ItemFileList }

function TAria2ItemFileList.LoadFromJson(jv: TJSONArray): Integer;
var
  jo: TJSONObject;
  jp: TJSONPair;
  jv1: TJSONArray;
  i, j: Integer;
  cItem: TAria2ItemFile;
  s: string;
begin
  Clear;
  for i := 0 to jv.Count-1 do
  begin
    jo := TJSONObject(jv.Items[i]);
    jp := jo.Get('path');
    if jp<>nil then
    begin
      cItem := TAria2ItemFile.Create;
      cItem.Path := jp.JsonValue.Value;
      jp := jo.Get('index');
      if jp<>nil then
        cItem.Idx := StrToIntDef(jp.JsonValue.Value, -1);
      jp := jo.Get('completedLength');
      if jp<>nil then
        cItem.CompletedLength := StrToInt64Def(jp.JsonValue.Value, -1);
      jp := jo.Get('length');
      if jp<>nil then
        cItem.TotalLength := StrToInt64Def(jp.JsonValue.Value, -1);
      jp := jo.Get('selected');
      if jp<>nil then
        cItem.Selected := jp.JsonValue.Value = 'true';
      jp := jo.Get('uris');
      if jp<>nil then
      begin
        // []
        if jp.JsonValue is TJSONArray then
        begin
          jv1 := TJSONArray(jp.JsonValue);
          s := '';
          for j := 0 to jv1.Count-1 do
          begin
            s := s+TJSONString(jv1[j]).Value+';';
          end;
          if Length(s)>0 then
          begin
            SetLength(s, Length(s)-1);
            cItem.URL := s;
          end;
        end else
        begin
          cItem.URL := jp.JsonValue.Value;
        end;
      end;

      if Add(cItem)<0 then cItem.Free;
    end;
  end;

  Result := Count;
end;

function TAria2ItemFileList.SelectedCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Count-1 do
  begin
    if TAria2ItemFile(Get(i)).Selected then Inc(Result);
  end;
end;

{ TAria2GetListThread }

constructor TAria2GetListThread.Create(cAria2: TAria2Delphi; nSleep: Integer);
begin
  m_nSleep := nSleep;
  m_cAria2 := cAria2;
  inherited Create(False);
  FreeOnTerminate := True;
end;

procedure TAria2GetListThread.Execute;
begin
  try
    while not Terminated do
    begin
      Sleep(m_nSleep);
      if Terminated then Break;
      if m_cAria2.GetDownloadList(nil, True)<0 then
      begin
        // auto start aria2?
        if g_nStartAria2=1 then RunAria2;
      end;
    end;
  except
  end;
end;

initialization
finalization
  FreeAndNil(g_cAria2Inst);

end.
