{==============================================================================|
| Project : Ararat Synapse                                       | 001.004.000 |
| Project : Internet Tools                                       | 001.004.000 |
|==============================================================================|
| Content: SSL support by OpenSSL                                              |
|==============================================================================|
| Copyright (c)1999-2017, Lukas Gebauer                                        |
| All rights reserved.                                                         |
|                                                                              |
| Redistribution and use in source and binary forms, with or without           |
| modification, are permitted provided that the following conditions are met:  |
|                                                                              |
| Redistributions of source code must retain the above copyright notice, this  |
| list of conditions and the following disclaimer.                             |
|                                                                              |
| Redistributions in binary form must reproduce the above copyright notice,    |
| this list of conditions and the following disclaimer in the documentation    |
| and/or other materials provided with the distribution.                       |
|                                                                              |
| Neither the name of Lukas Gebauer nor the names of its contributors may      |
| be used to endorse or promote products derived from this software without    |
| specific prior written permission.                                           |
|                                                                              |
| THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"  |
| AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE    |
| IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE   |
| ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR  |
| ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL       |
| DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR   |
| SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER   |
| CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT           |
| LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY    |
| OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH  |
| DAMAGE.                                                                      |
|==============================================================================|
| The Initial Developer of the Original Code is Lukas Gebauer (Czech Republic).|
| Portions created by Lukas Gebauer are Copyright (c)2005-2017.                |
| Portions created by Petr Fejfar are Copyright (c)2011-2012.                  |
| Portions created by Pepak are Copyright (c)2018.                             |
| All Rights Reserved.                                                         |
|==============================================================================|
| Contributor(s):                                                              |
|==============================================================================|
| History: see HISTORY.HTM from distribution package                           |
|          (Found at URL: http://www.ararat.cz/synapse/)                       |
|==============================================================================}

//requires OpenSSL libraries!

{:@abstract(SSL plugin for OpenSSL)

Compatibility with OpenSSL versions:
0.9.6 should work, known mysterious crashing on FreePascal and Linux platform.
0.9.7 - 1.0.0 working fine.
1.1.0 should work, under testing.

OpenSSL libraries are loaded dynamicly - you not need OpenSSL librares even you
compile your application with this unit. SSL just not working when you not have
OpenSSL libraries.

This plugin have limited support for .NET too! Because is not possible to use
callbacks with CDECL calling convention under .NET, is not supported
key/certificate passwords and multithread locking. :-(

For handling keys and certificates you can use this properties:

@link(TCustomSSL.CertificateFile) for PEM or ASN1 DER (cer) format. @br
@link(TCustomSSL.Certificate) for ASN1 DER format only. @br
@link(TCustomSSL.PrivateKeyFile) for PEM or ASN1 DER (key) format. @br
@link(TCustomSSL.PrivateKey) for ASN1 DER format only. @br
@link(TCustomSSL.CertCAFile) for PEM CA certificate bundle. @br
@link(TCustomSSL.PFXFile) for PFX format. @br
@link(TCustomSSL.PFX) for PFX format from binary string. @br

This plugin is capable to create Ad-Hoc certificates. When you start SSL/TLS
server without explicitly assigned key and certificate, then this plugin create
Ad-Hoc key and certificate for each incomming connection by self. It slowdown
accepting of new connections!
}

//{$INCLUDE 'jedi.inc'}
{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

{$H+}

{$IFDEF UNICODE}
  {$WARN IMPLICIT_STRING_CAST OFF}
  {$WARN IMPLICIT_STRING_CAST_LOSS OFF}
{$ENDIF}

unit synapse_ssl_openssl_override;

interface

uses
  SysUtils, Classes,
  blcksock, synsock, synautil,
{$IFDEF CIL}
  System.Text,
{$ENDIF}
{$IFDEF DELPHI23_UP}
  AnsiStrings,
{$ENDIF}
  ssl_openssl_lib;

type
  {:@abstract(class implementing OpenSSL SSL plugin.)
   Instance of this class will be created for each @link(TTCPBlockSocket).
   You not need to create instance of this class, all is done by Synapse itself!}
  TSSLOpenSSLOverride = class(TCustomSSL)
  private
    FServer: boolean;
  protected
    FOldSSLType: TSSLType;
    FOldVerifyCert: boolean;
    function customCertificateHandling: boolean; virtual;
    function customQuickClientPrepare: boolean; virtual;
    procedure setCustomError(msg: string; id: integer = -3);
  public
    CAFile, CAPath, outErrorMessage: string;
    outErrorCode: integer;
    class procedure LoadOpenSSL; virtual;
  protected
    FSsl: PSSL;
    Fctx: PSSL_CTX;
    function NeedSigningCertificate: boolean; virtual;
    function SSLCheck: Boolean;
    function SetSslKeys: boolean; virtual;
    function Init: Boolean;
    function DeInit: Boolean;
    function Prepare: Boolean; overload;
    function Prepare(aserver: Boolean): Boolean; overload;
    function LoadPFX(pfxdata: ansistring): Boolean;
    function CreateSelfSignedCert(Host: string): Boolean; override;
    property Server: boolean read FServer;
  public
    {:See @inherited}
    constructor Create(const Value: TTCPBlockSocket); override;
    destructor Destroy; override;
    {:See @inherited}
    function LibVersion: String; override;
    {:See @inherited}
    function LibName: String; override;
    {:See @inherited and @link(ssl_cryptlib) for more details.}
    function Connect: boolean; override;
    {:See @inherited and @link(ssl_cryptlib) for more details.}
    function Accept: boolean; override;
    {:See @inherited}
    function Shutdown: boolean; override;
    {:See @inherited}
    function BiShutdown: boolean; override;
    {:See @inherited}
    function SendBuffer(Buffer: TMemory; Len: Integer): Integer; override;
    {:See @inherited}
    function RecvBuffer(Buffer: TMemory; Len: Integer): Integer; override;
    {:See @inherited}
    function WaitingData: Integer; override;
    {:See @inherited}
    function GetSSLVersion: string; override;
    {:See @inherited}
    function GetPeerSubject: string; override;
    {:See @inherited}
    function GetPeerSerialNo: integer; override; {pf}
    {:See @inherited}
    function GetPeerIssuer: string; override;
    {:See @inherited}
    function GetPeerName: string; override;
    {:See @inherited}
    function GetPeerNameHash: cardinal; override; {pf}
    {:See @inherited}
    function GetPeerFingerprint: string; override;
    {:See @inherited}
    function GetCertInfo: string; override;
    {:See @inherited}
    function GetCipherName: string; override;
    {:See @inherited}
    function GetCipherBits: integer; override;
    {:See @inherited}
    function GetCipherAlgBits: integer; override;
    {:See @inherited}
    function GetVerifyCert: integer; override;
  end;

implementation
uses dynlibs;
{==============================================================================}

{$IFNDEF CIL}
function PasswordCallback(buf:PAnsiChar; size:Integer; rwflag:Integer; userdata: Pointer):Integer; cdecl;
var
  Password: AnsiString;
begin
  Password := '';
  if TCustomSSL(userdata) is TCustomSSL then
    Password := TCustomSSL(userdata).KeyPassword;
  if Length(Password) > (Size - 1) then
    SetLength(Password, Size - 1);
  Result := Length(Password);
  {$IFDEF DELPHI23_UP}AnsiStrings.{$ENDIF}StrLCopy(buf, PAnsiChar(Password + #0), Result + 1);
end;
{$ENDIF}

{==============================================================================}

constructor TSSLOpenSSLOverride.Create(const Value: TTCPBlockSocket);
begin
  inherited Create(Value);
  FCiphers := 'DEFAULT';
  FSsl := nil;
  Fctx := nil;
end;

destructor TSSLOpenSSLOverride.Destroy;
begin
  DeInit;
  inherited Destroy;
end;


function TSSLOpenSSLOverride.LibName: String;
begin
  Result := 'ssl_openssl';
end;

function TSSLOpenSSLOverride.SSLCheck: Boolean;
var
{$IFDEF CIL}
  sb: StringBuilder;
{$ENDIF}
  s : AnsiString;
begin
  Result := true;
  FLastErrorDesc := '';
  FLastError := ErrGetError;
  ErrClearError;
  if FLastError <> 0 then
  begin
    Result := False;
{$IFDEF CIL}
    sb := StringBuilder.Create(256);
    ErrErrorString(FLastError, sb, 256);
    FLastErrorDesc := Trim(sb.ToString);
{$ELSE}
    s := StringOfChar(#0, 256);
    ErrErrorString(FLastError, s, Length(s));
    FLastErrorDesc := s;
{$ENDIF}
  end;
end;

function TSSLOpenSSLOverride.CreateSelfSignedCert(Host: string): Boolean;
var
  pk: EVP_PKEY;
  x: PX509;
  rsa: PRSA;
  t: PASN1_UTCTIME;
  name: PX509_NAME;
  b: PBIO;
  xn, y: integer;
  s: AnsiString;
{$IFDEF CIL}
  sb: StringBuilder;
{$ENDIF}
begin
  Result := True;
  pk := EvpPkeynew;
  x := X509New;
  try
    rsa := RsaGenerateKey(2048, $10001, nil, nil);
    EvpPkeyAssign(pk, EVP_PKEY_RSA, rsa);
    X509SetVersion(x, 2);
    Asn1IntegerSet(X509getSerialNumber(x), 0);
    t := Asn1UtctimeNew;
    try
      X509GmtimeAdj(t, -60 * 60 *24);
      X509SetNotBefore(x, t);
      X509GmtimeAdj(t, 60 * 60 * 60 *24);
      X509SetNotAfter(x, t);
    finally
      Asn1UtctimeFree(t);
    end;
    X509SetPubkey(x, pk);
    Name := X509GetSubjectName(x);
    X509NameAddEntryByTxt(Name, 'C', $1001, 'CZ', -1, -1, 0);
    X509NameAddEntryByTxt(Name, 'CN', $1001, host, -1, -1, 0);
    x509SetIssuerName(x, Name);
    x509Sign(x, pk, EvpGetDigestByName('SHA1'));
    b := BioNew(BioSMem);
    try
      i2dX509Bio(b, x);
      xn := bioctrlpending(b);
{$IFDEF CIL}
      sb := StringBuilder.Create(xn);
      y := bioread(b, sb, xn);
      if y > 0 then
      begin
        sb.Length := y;
        s := sb.ToString;
      end;
{$ELSE}
      setlength(s, xn);
      y := bioread(b, s, xn);
      if y > 0 then
        setlength(s, y);
{$ENDIF}
    finally
      BioFreeAll(b);
    end;
    FCertificate := s;
    b := BioNew(BioSMem);
    try
      i2dPrivatekeyBio(b, pk);
      xn := bioctrlpending(b);
{$IFDEF CIL}
      sb := StringBuilder.Create(xn);
      y := bioread(b, sb, xn);
      if y > 0 then
      begin
        sb.Length := y;
        s := sb.ToString;
      end;
{$ELSE}
      setlength(s, xn);
      y := bioread(b, s, xn);
      if y > 0 then
        setlength(s, y);
{$ENDIF}
    finally
      BioFreeAll(b);
    end;
    FPrivatekey := s;
  finally
    X509free(x);
    EvpPkeyFree(pk);
  end;
end;

function TSSLOpenSSLOverride.LoadPFX(pfxdata: ansistring): Boolean;
var
  cert, pkey, ca: SslPtr;
  b: PBIO;
  p12: SslPtr;
begin
  Result := False;
  b := BioNew(BioSMem);
  try
    BioWrite(b, pfxdata, Length(PfxData));
    p12 := d2iPKCS12bio(b, nil);
    if not Assigned(p12) then
      Exit;
    try
      cert := nil;
      pkey := nil;
      ca := nil;
      try {pf}
        if PKCS12parse(p12, FKeyPassword, pkey, cert, ca) > 0 then
          if SSLCTXusecertificate(Fctx, cert) > 0 then
            if SSLCTXusePrivateKey(Fctx, pkey) > 0 then
              Result := True;
      {pf}
      finally
        EvpPkeyFree(pkey);
        X509free(cert);
        SkX509PopFree(ca,_X509Free); // for ca=nil a new STACK was allocated...
      end;
      {/pf}
    finally
      PKCS12free(p12);
    end;
  finally
    BioFreeAll(b);
  end;
end;

function TSSLOpenSSLOverride.SetSslKeys: boolean;
var
  st: TFileStream;
  s: string;
begin
  Result := False;
  if not assigned(FCtx) then
    Exit;
  try
    if FCertificateFile <> '' then
      if SslCtxUseCertificateChainFile(FCtx, FCertificateFile) <> 1 then
        if SslCtxUseCertificateFile(FCtx, FCertificateFile, SSL_FILETYPE_PEM) <> 1 then
          if SslCtxUseCertificateFile(FCtx, FCertificateFile, SSL_FILETYPE_ASN1) <> 1 then
            Exit;
    if FCertificate <> '' then
      if SslCtxUseCertificateASN1(FCtx, length(FCertificate), FCertificate) <> 1 then
        Exit;
    SSLCheck;
    if FPrivateKeyFile <> '' then
      if SslCtxUsePrivateKeyFile(FCtx, FPrivateKeyFile, SSL_FILETYPE_PEM) <> 1 then
        if SslCtxUsePrivateKeyFile(FCtx, FPrivateKeyFile, SSL_FILETYPE_ASN1) <> 1 then
          Exit;
    if FPrivateKey <> '' then
      if SslCtxUsePrivateKeyASN1(EVP_PKEY_RSA, FCtx, FPrivateKey, length(FPrivateKey)) <> 1 then
        Exit;
    SSLCheck;
    if FCertCAFile <> '' then
      if SslCtxLoadVerifyLocations(FCtx, FCertCAFile, '') <> 1 then
        Exit;
    if FPFXfile <> '' then
    begin
      try
        st := TFileStream.Create(FPFXfile, fmOpenRead	 or fmShareDenyNone);
        try
          s := ReadStrFromStream(st, st.Size);
        finally
          st.Free;
        end;
        if not LoadPFX(s) then
          Exit;
      except
        on Exception do
          Exit;
      end;
    end;
    if FPFX <> '' then
      if not LoadPFX(FPfx) then
        Exit;
    SSLCheck;
    Result := True;
  finally
    SSLCheck;
  end;
end;


function TSSLOpenSSLOverride.NeedSigningCertificate: boolean;
begin
  Result := (FCertificateFile = '') and (FCertificate = '') and (FPFXfile = '') and (FPFX = '');
end;


function TSSLOpenSSLOverride.DeInit: Boolean;
begin
  Result := True;
  if assigned (Fssl) then
    sslfree(Fssl);
  Fssl := nil;
  if assigned (Fctx) then
  begin
    SslCtxFree(Fctx);
    Fctx := nil;
    ErrRemoveState(0);
  end;
  FSSLEnabled := False;
end;

function TSSLOpenSSLOverride.Prepare: Boolean;
begin
  Result := false;
  DeInit;
  if Init then
    Result := true
  else
    DeInit;
end;

function TSSLOpenSSLOverride.Prepare(aserver: Boolean): Boolean;
begin
  fserver := aserver;
  result := Prepare();
end;


function TSSLOpenSSLOverride.Accept: boolean;
var
  x: integer;
begin
  Result := False;
  if FSocket.Socket = INVALID_SOCKET then
    Exit;
  FServer := True;
  if Prepare then
  begin
{$IFDEF CIL}
    if sslsetfd(FSsl, FSocket.Socket.Handle.ToInt32) < 1 then
{$ELSE}
    if sslsetfd(FSsl, FSocket.Socket) < 1 then
{$ENDIF}
    begin
      SSLCheck;
      Exit;
    end;
    x := sslAccept(FSsl);
    if x < 1 then
    begin
      SSLcheck;
      Exit;
    end;
    FSSLEnabled := True;
    Result := True;
  end;
end;

function TSSLOpenSSLOverride.Shutdown: boolean;
begin
  if not IsSSLloaded then begin
    //prevent crash if OpenSSL has been unloaded.
    //this would only happen if the program is closed, so the main thread has run the ssl_openssl_lib finalization section,
    //but this functino is called from a secondary thread.
    //then sslShutdown cannot be called because it would try to enter a critsection which already has been destroyed
    FSSLEnabled := false;
    Fssl := nil;
    Fctx := nil;
    exit(false);
  end;
  if assigned(FSsl) then
    sslshutdown(FSsl);
  DeInit;
  Result := True;
end;

function TSSLOpenSSLOverride.BiShutdown: boolean;
var
  x: integer;
begin
  if assigned(FSsl) then
  begin
    x := sslshutdown(FSsl);
    if x = 0 then
    begin
      Synsock.Shutdown(FSocket.Socket, 1);
      sslshutdown(FSsl);
    end;
  end;
  DeInit;
  Result := True;
end;

function TSSLOpenSSLOverride.SendBuffer(Buffer: TMemory; Len: Integer): Integer;
var
  err: integer;
{$IFDEF CIL}
  s: ansistring;
{$ENDIF}
begin
  FLastError := 0;
  FLastErrorDesc := '';
  repeat
{$IFDEF CIL}
    s := StringOf(Buffer);
    Result := SslWrite(FSsl, s, Len);
{$ELSE}
    Result := SslWrite(FSsl, Buffer , Len);
{$ENDIF}
    err := SslGetError(FSsl, Result);
  until (err <> SSL_ERROR_WANT_READ) and (err <> SSL_ERROR_WANT_WRITE);
  if err = SSL_ERROR_ZERO_RETURN then
    Result := 0
  else
    if (err <> 0) then
      FLastError := err;
end;

function TSSLOpenSSLOverride.RecvBuffer(Buffer: TMemory; Len: Integer): Integer;
var
  err: integer;
{$IFDEF CIL}
  sb: stringbuilder;
  s: ansistring;
{$ENDIF}
begin
  FLastError := 0;
  FLastErrorDesc := '';
  repeat
{$IFDEF CIL}
    sb := StringBuilder.Create(Len);
    Result := SslRead(FSsl, sb, Len);
    if Result > 0 then
    begin
      sb.Length := Result;
      s := sb.ToString;
      System.Array.Copy(BytesOf(s), Buffer, length(s));
    end;
{$ELSE}
    Result := SslRead(FSsl, Buffer , Len);
{$ENDIF}
    err := SslGetError(FSsl, Result);
  until (err <> SSL_ERROR_WANT_READ) and (err <> SSL_ERROR_WANT_WRITE);
  if err = SSL_ERROR_ZERO_RETURN then
    Result := 0
  {pf}// Verze 1.1.0 byla s else tak jak to ted mam,
      // ve verzi 1.1.1 bylo ELSE zruseno, ale pak je SSL_ERROR_ZERO_RETURN
      // propagovano jako Chyba.
  {pf} else {/pf} if (err <> 0) then   
    FLastError := err;
end;

function TSSLOpenSSLOverride.WaitingData: Integer;
begin
  Result := sslpending(Fssl);
end;

function TSSLOpenSSLOverride.GetSSLVersion: string;
begin
  if not assigned(FSsl) then
    Result := ''
  else
    Result := SSlGetVersion(FSsl);
end;

function TSSLOpenSSLOverride.GetPeerSubject: string;
var
  cert: PX509;
  s: ansistring;
{$IFDEF CIL}
  sb: StringBuilder;
{$ENDIF}
begin
  if not assigned(FSsl) then
  begin
    Result := '';
    Exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  if not assigned(cert) then
  begin
    Result := '';
    Exit;
  end;
{$IFDEF CIL}
  sb := StringBuilder.Create(4096);
  Result := X509NameOneline(X509GetSubjectName(cert), sb, 4096);
{$ELSE}
  setlength(s, 4096);
  Result := X509NameOneline(X509GetSubjectName(cert), s, Length(s));
{$ENDIF}
  X509Free(cert);
end;


function TSSLOpenSSLOverride.GetPeerSerialNo: integer; {pf}
var
  cert: PX509;
  SN:   PASN1_INTEGER;
begin
  if not assigned(FSsl) then
  begin
    Result := -1;
    Exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  try
    if not assigned(cert) then
    begin
      Result := -1;
      Exit;
    end;
    SN := X509GetSerialNumber(cert);
    Result := Asn1IntegerGet(SN);
  finally
    X509Free(cert);
  end;
end;

function TSSLOpenSSLOverride.GetPeerName: string;
var
  s: ansistring;
begin
  s := GetPeerSubject;
  s := SeparateRight(s, '/CN=');
  Result := Trim(SeparateLeft(s, '/'));
end;

function TSSLOpenSSLOverride.GetPeerNameHash: cardinal; {pf}
var
  cert: PX509;
begin
  if not assigned(FSsl) then
  begin
    Result := 0;
    Exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  try
    if not assigned(cert) then
    begin
      Result := 0;
      Exit;
    end;
    Result := X509NameHash(X509GetSubjectName(cert));
  finally
    X509Free(cert);
  end;
end;

function TSSLOpenSSLOverride.GetPeerIssuer: string;
var
  cert: PX509;
  s: ansistring;
{$IFDEF CIL}
  sb: StringBuilder;
{$ENDIF}
begin
  if not assigned(FSsl) then
  begin
    Result := '';
    Exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  if not assigned(cert) then
  begin
    Result := '';
    Exit;
  end;
{$IFDEF CIL}
  sb := StringBuilder.Create(4096);
  Result := X509NameOneline(X509GetIssuerName(cert), sb, 4096);
{$ELSE}
  setlength(s, 4096);
  Result := X509NameOneline(X509GetIssuerName(cert), s, Length(s));
{$ENDIF}
  X509Free(cert);
end;

function TSSLOpenSSLOverride.GetPeerFingerprint: string;
var
  cert: PX509;
  x: integer;
{$IFDEF CIL}
  sb: StringBuilder;
{$ENDIF}
begin
  if not assigned(FSsl) then
  begin
    Result := '';
    Exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  if not assigned(cert) then
  begin
    Result := '';
    Exit;
  end;
{$IFDEF CIL}
  sb := StringBuilder.Create(EVP_MAX_MD_SIZE);
  X509Digest(cert, EvpGetDigestByName('MD5'), sb, x);
  sb.Length := x;
  Result := sb.ToString;
{$ELSE}
  setlength(Result, EVP_MAX_MD_SIZE);
  X509Digest(cert, EvpGetDigestByName('MD5'), Result, x);
  SetLength(Result, x);
{$ENDIF}
  X509Free(cert);
end;

function TSSLOpenSSLOverride.GetCertInfo: string;
var
  cert: PX509;
  x, y: integer;
  b: PBIO;
  s: AnsiString;
{$IFDEF CIL}
  sb: stringbuilder;
{$ENDIF}
begin
  if not assigned(FSsl) then
  begin
    Result := '';
    Exit;
  end;
  cert := SSLGetPeerCertificate(Fssl);
  if not assigned(cert) then
  begin
    Result := '';
    Exit;
  end;
  try {pf}
    b := BioNew(BioSMem);
    try
      X509Print(b, cert);
      x := bioctrlpending(b);
  {$IFDEF CIL}
      sb := StringBuilder.Create(x);
      y := bioread(b, sb, x);
      if y > 0 then
      begin
        sb.Length := y;
        s := sb.ToString;
      end;
  {$ELSE}
      setlength(s,x);
      y := bioread(b,s,x);
      if y > 0 then
        setlength(s, y);
  {$ENDIF}
      Result := ReplaceString(s, LF, CRLF);
    finally
      BioFreeAll(b);
    end;
  {pf}
  finally
    X509Free(cert);
  end;
  {/pf}
end;

function TSSLOpenSSLOverride.GetCipherName: string;
begin
  if not assigned(FSsl) then
    Result := ''
  else
    Result := SslCipherGetName(SslGetCurrentCipher(FSsl));
end;

function TSSLOpenSSLOverride.GetCipherBits: integer;
var
  x: integer;
begin
  if not assigned(FSsl) then
    Result := 0
  else
    Result := SSLCipherGetBits(SslGetCurrentCipher(FSsl), x);
end;

function TSSLOpenSSLOverride.GetCipherAlgBits: integer;
begin
  if not assigned(FSsl) then
    Result := 0
  else
    SSLCipherGetBits(SslGetCurrentCipher(FSsl), Result);
end;

function TSSLOpenSSLOverride.GetVerifyCert: integer;
begin
  if not assigned(FSsl) then
    Result := 1
  else
    Result := SslGetVerifyResult(FSsl);
end;



{==============================================================================}

resourcestring
  rsSSLErrorOpenSSLTooOld = 'OpenSSL version is too old for certificate checking. Required is OpenSSL 1.0.2+';
  rsSSLErrorOpenSSLTooOldForTLS13 = 'OpenSSL version is too old for TLS1.3 (functions SSL_set_min/max_proto_version not found)';
  rsSSLErrorCAFileLoadingFailed = 'Failed to load CA files.';
  rsSSLErrorSettingHostname = 'Failed to set hostname for certificate validation.';
  rsSSLErrorConnectionFailed = 'HTTPS connection failed after connecting to server. Some possible causes: handshake failure, mismatched HTTPS version/ciphers, invalid certificate';
  rsSSLErrorVerificationFailed = 'HTTPS certificate validation failed';

type
  PX509_VERIFY_PARAM = pointer;
  TOpenSSL_version = function(t: integer): pchar; cdecl;
  TSSL_get0_param = function(ctx: PSSL_CTX): PX509_VERIFY_PARAM; cdecl;
  TX509_VERIFY_PARAM_set_hostflags = procedure(param: PX509_VERIFY_PARAM; flags: cardinal); cdecl;
  TX509_VERIFY_PARAM_set1_host = function(param: PX509_VERIFY_PARAM; name: pchar; nameLen: SizeUInt): integer; cdecl;
  TSslCtxSetMinProtoVersion = function(ctx: PSSL_CTX; version: integer): integer; cdecl;
  TSslCtxSetMaxProtoVersion = function(ctx: PSSL_CTX; version: integer): integer; cdecl;
  TSslMethodTLS = function:PSSL_METHOD; cdecl;
  TSSLSetTlsextHostName = function(ctx: PSSL_CTX; name: pchar): integer; cdecl;

const X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS = 4;
var _SSL_get0_param: TSSL_get0_param = nil;
   _X509_VERIFY_PARAM_set_hostflags: TX509_VERIFY_PARAM_set_hostflags = nil;
   _X509_VERIFY_PARAM_set1_host: TX509_VERIFY_PARAM_set1_host = nil;
   _OpenSSL_version: TOpenSSL_version = nil;
   _SslCtxSetMinProtoVersion: TSslCtxSetMinProtoVersion = nil;
   _SslCtxSetMaxProtoVersion: TSslCtxSetMaxProtoVersion = nil;
   _SSLsetTLSextHostName: TSSLSetTlsextHostName = nil;


   SslMethodTLSV11: TSslMethodTLS = nil;
   SslMethodTLSV12: TSslMethodTLS = nil;
   SslMethodTLS: TSslMethodTLS = nil;


class procedure TSSLOpenSSLOverride.LoadOpenSSL;
begin
  if not ssl_openssl_lib.InitSSLInterface then exit;
  if (SSLLibHandle <> 0) and (SSLUtilHandle <> 0) then begin
    _SSL_get0_param := TSSL_get0_param(GetProcedureAddress(SSLLibHandle, 'SSL_get0_param'));
    _X509_VERIFY_PARAM_set_hostflags := TX509_VERIFY_PARAM_set_hostflags(GetProcedureAddress(SSLUtilHandle, 'X509_VERIFY_PARAM_set_hostflags'));
    _X509_VERIFY_PARAM_set1_host := TX509_VERIFY_PARAM_set1_host(GetProcedureAddress(SSLUtilHandle, 'X509_VERIFY_PARAM_set1_host'));
    _OpenSSL_version := TOpenSSL_version(GetProcedureAddress(SSLLibHandle, 'OpenSSL_version'));
    _SslCtxSetMinProtoVersion := TSslCtxSetMinProtoVersion(GetProcedureAddress(SSLLibHandle, 'SSL_CTX_set_min_proto_version'));
    if not assigned(_SslCtxSetMinProtoVersion) then
      _SslCtxSetMinProtoVersion := TSslCtxSetMinProtoVersion(GetProcedureAddress(SSLLibHandle, 'SSL_set_min_proto_version'));
    _SslCtxSetMaxProtoVersion := TSslCtxSetMaxProtoVersion(GetProcedureAddress(SSLLibHandle, 'SSL_CTX_set_max_proto_version'));
    if not assigned(_SslCtxSetMaxProtoVersion) then
      _SslCtxSetMaxProtoVersion := TSslCtxSetMinProtoVersion(GetProcedureAddress(SSLLibHandle, 'SSL_set_max_proto_version'));
    if not assigned(_SSLsetTLSextHostName) then
      _SSLsetTLSextHostName := TSSLSetTlsextHostName(GetProcedureAddress(SSLLibHandle, 'SSL_set_tlsext_host_name'));

    SslMethodTLSV11 := TSslMethodTLS(GetProcedureAddress(SSLLibHandle, 'TLSv1_1_method'));
    SslMethodTLSV12 := TSslMethodTLS(GetProcedureAddress(SSLLibHandle, 'TLSv1_2_method'));
    SslMethodTLS := TSslMethodTLS(GetProcedureAddress(SSLLibHandle, 'TLS_method'));
  end;
end;

function TSSLOpenSSLOverride.LibVersion: String;
begin
  Result := SSLeayversion(0);
  if assigned(_OpenSSL_version) then
    result += _OpenSSL_version(0);
end;

function TSSLOpenSSLOverride.customCertificateHandling: boolean;
var
  param: PX509_VERIFY_PARAM;
label onError;
begin
  result := false;
  if VerifyCert then begin
    //see https://wiki.openssl.org/index.php/Hostname_validation
    if not assigned(_SSL_get0_param) or not assigned(_X509_VERIFY_PARAM_set_hostflags) or not assigned(_X509_VERIFY_PARAM_set1_host) then begin
      setCustomError(rsSSLErrorOpenSSLTooOld, -2);
      exit;
    end;
    param := _SSL_get0_param(Fssl);
    if param = nil then
      goto onError;
    _X509_VERIFY_PARAM_set_hostflags(param, X509_CHECK_FLAG_NO_PARTIAL_WILDCARDS);
    if _X509_VERIFY_PARAM_set1_host(param, pchar(SNIHost), length(SNIHost)) = 0 then
      goto onError;
  end;
  result := true;
  exit;

onError:
  setCustomError(rsSSLErrorSettingHostname, -2);
  result := false;
end;

function TSSLOpenSSLOverride.customQuickClientPrepare: boolean;
begin
  if not assigned(FSsl) or not assigned(Fctx) or (FOldSSLType <> FSSLType) or (VerifyCert <> FOldVerifyCert)  then begin
    result := Prepare(false);
    if result and VerifyCert then
      if SslCtxLoadVerifyLocations(FCtx, CAFile, CAPath) <> 1 then begin
        SSLCheck;
        setCustomError(rsSSLErrorCAFileLoadingFailed);
        result := false;
      end;
  end else begin
    sslfree(Fssl);
    Fssl := SslNew(Fctx);
    result := FSsl <> nil;
    if not result then
      SSLCheck;
  end;
  if result then begin
    FOldSSLType := FSSLType;
    FOldVerifyCert := VerifyCert;
  end;
end;

procedure TSSLOpenSSLOverride.setCustomError(msg: string; id: integer);
begin
  outErrorCode := id;
  outErrorMessage := LineEnding + msg;
  outErrorMessage += LineEnding+'OpenSSL-Error: '+LastErrorDesc;
//  str(FSSLType, temp);
  outErrorMessage += LineEnding+'OpenSSL information: CA file: '+CAFile+' , CA dir: '+CAPath+' , '+ {temp+', '+}GetSSLVersion+', '+LibVersion;
end;



function TSSLOpenSSLOverride.Init: Boolean;
const
  TLS1_VERSION = $0301;
  TLS1_1_VERSION = $0302;
  TLS1_2_VERSION = $0303;
  TLS1_3_VERSION = $0304;
var fallbackMethod: PSSL_METHOD = nil;
    minVersion, maxVersion: integer;
var
  s: AnsiString;
  isTLSv1_3, isTLSv1_2: Boolean;
begin
  Result := False;
  FLastErrorDesc := '';
  FLastError := 0;
  Fctx := nil;
  isTLSv1_2 := (ord(FSSLType) = ord(LT_TLSv1_1) + 1) and (FSSLType < LT_SSHv2); //LT_TLSv1_2 or LT_TLSv1_3, but older synapse version do not have that
  isTLSv1_3 := (ord(FSSLType) = ord(LT_TLSv1_1) + 2) and (FSSLType < LT_SSHv2); //LT_TLSv1_3, but older synapse version do not have that
  //writeln(isTLSv1_3, ' ',assigned(_SslCtxSetMinProtoVersion), ' ',assigned(_SslCtxSetMaxProtoVersion));
  if isTLSv1_3 and not (assigned(_SslCtxSetMinProtoVersion) and assigned(_SslCtxSetMaxProtoVersion)) then begin
//    setCustomError(rsSSLErrorOpenSSLTooOldForTLS13);
    exit;
  end;

  case FSSLType of
    LT_SSLv2: begin fallbackMethod := SslMethodV2; minVersion := 0; maxVersion := minVersion; end;
    LT_SSLv3: begin fallbackMethod := SslMethodV3; minVersion := 0; maxVersion := minVersion; end;
    LT_TLSv1: begin fallbackMethod := SslMethodTLSV1; minVersion := TLS1_VERSION; maxVersion := minVersion; end;
    LT_TLSv1_1: begin fallbackMethod := SslMethodTLSV11; minVersion := TLS1_1_VERSION; maxVersion := minVersion; end;
    //LT_TLSv1_2: begin fallbackMethod := SslMethodTLSV12; minVersion := TLS1_2_VERSION; maxVersion := minVersion; end;
    LT_all: begin fallbackMethod := SslMethodV23; minVersion := TLS1_VERSION; maxVersion := TLS1_3_VERSION; end;
    else if isTLSv1_2 then begin fallbackMethod := SslMethodTLSV12; minVersion := TLS1_2_VERSION; maxVersion := minVersion;  end
    else if isTLSv1_3 then begin minVersion := TLS1_3_VERSION; maxVersion := TLS1_3_VERSION;  end
    else exit;
  end;

  if assigned(SslMethodTLS) and ( (FSSLType = LT_all) or (assigned(_SslCtxSetMinProtoVersion) and assigned(_SslCtxSetMaxProtoVersion)) ) then begin
    Fctx := SslCtxNew(SslMethodTLS);
    if Fctx <> nil then begin
      if assigned(_SslCtxSetMinProtoVersion) and assigned(_SslCtxSetMaxProtoVersion) then begin
        _SslCtxSetMinProtoVersion(Fctx, minVersion);
        _SslCtxSetMaxProtoVersion(Fctx, maxVersion); //todo: check result?
      end;
    end;
  end;

  if (Fctx = nil) and assigned(fallbackMethod) then
    Fctx := SslCtxNew(fallbackMethod);

  if Fctx = nil then
  begin
    SSLCheck;
    Exit;
  end
  else
  begin
    s := FCiphers;
    SslCtxSetCipherList(Fctx, s);
    if FVerifyCert then
      SslCtxSetVerify(FCtx, SSL_VERIFY_PEER, nil)
    else
      SslCtxSetVerify(FCtx, SSL_VERIFY_NONE, nil);
{$IFNDEF CIL}
    SslCtxSetDefaultPasswdCb(FCtx, @PasswordCallback);
    SslCtxSetDefaultPasswdCbUserdata(FCtx, self);
{$ENDIF}

    if server and NeedSigningCertificate then
    begin
      CreateSelfSignedcert(FSocket.ResolveIPToName(FSocket.GetRemoteSinIP));
    end;

    if not SetSSLKeys then
      Exit
    else
    begin
      Fssl := nil;
      Fssl := SslNew(Fctx);
      if Fssl = nil then
      begin
        SSLCheck;
        exit;
      end;
    end;
  end;
  Result := true;
end;


function TSSLOpenSSLOverride.Connect: boolean;
var
  x: integer;
  b: boolean;
  err: integer;
begin
  Result := False;
  if FSocket.Socket = INVALID_SOCKET then
    Exit;
  FServer := False;
  if customQuickClientPrepare() {!!override!!} then
  begin
    if not customCertificateHandling {!!override!!}  then
      exit;
{$IFDEF CIL}
    if sslsetfd(FSsl, FSocket.Socket.Handle.ToInt32) < 1 then
{$ELSE}
    if sslsetfd(FSsl, FSocket.Socket) < 1 then
{$ENDIF}
    begin
      SSLCheck;
      Exit;
    end;
    if SNIHost<>'' then
      if assigned(_SSLsetTLSextHostName) then
        _SSLsetTLSextHostName(Fssl, PAnsiChar(AnsiString(SNIHost)))
       else
        SSLCtrl(Fssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, PAnsiChar(AnsiString(SNIHost)));
    //if  (FSocket.ConnectionTimeout <= 0) then //do blocking call of SSL_Connect {!!override!!}
    begin
      x := sslconnect(FSsl);
      if x < 1 then
      begin
        SSLcheck;
        setCustomError(rsSSLErrorConnectionFailed, -3); {!!override!!}
        Exit;
      end;
    end
    //this must be commented out, because ConnectionTimeout is missing in Synapse SVN r40
    {else //do non-blocking call of SSL_Connect
    begin
      b := Fsocket.NonBlockMode;
      Fsocket.NonBlockMode := true;
      repeat
        x := sslconnect(FSsl);
        err := SslGetError(FSsl, x);
        if err = SSL_ERROR_WANT_READ then
          if not FSocket.CanRead(FSocket.ConnectionTimeout) then
            break;
        if err = SSL_ERROR_WANT_WRITE then
          if not FSocket.CanWrite(FSocket.ConnectionTimeout) then
            break;
      until (err <> SSL_ERROR_WANT_READ) and (err <> SSL_ERROR_WANT_WRITE);
      Fsocket.NonBlockMode := b;
      if err <> SSL_ERROR_NONE then
      begin
        SSLcheck;
        Exit;
      end;
    end};
    if FverifyCert then //seems like this is not needed, since sslconnect already fails on an invalid certificate  {!!override!!}
      if (GetVerifyCert <> 0) or (not DoVerifyCert) then begin
        setCustomError(rsSSLErrorVerificationFailed, -3);
        Exit;
      end;
    FSSLEnabled := True;
    Result := True;
  end;
end;


initialization
  SSLImplementation := TSSLOpenSSLOverride;

end.
