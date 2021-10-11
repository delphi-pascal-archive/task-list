unit TaskUnit;

(*
 Utility for enumerating all running tasks on a system,
 including modules used by each task
 ---
 Author : Dirk Claessens <dirk.claessens16@yucom.be>
 ---
 FREEWARE, but use at your own risk.
 ---
*)   

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, tlHelp32, Buttons;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    btnGo: TSpeedButton;
    CheckBox1: TCheckBox;
    procedure BtnGoClick(Sender: TObject);
  private
    { Private declarations }
    procedure GetModules( ProcessID: DWORD; Buf : TStrings );
    procedure GetProcesses( IncludeModules: boolean; Buf: TStrings);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.BtnGoClick(Sender: TObject);
begin
  memo1.clear;
  Memo1.Lines.BeginUpdate;
  GetProcesses( CheckBox1.Checked, Memo1.Lines);
  Memo1.Lines.EndUpdate;
end;

{--------------------------------------------------------------------}
{  Enumerates running tasks, optionally enumerates modules in        }
{  use by each task                                                  }
{--------------------------------------------------------------------}
procedure TForm1.GetProcesses( IncludeModules: boolean; Buf: TStrings);
const
  FmtProc = '%8.8x   %8.8x %8.8x  %3.3d    %3.3d     %3.3d  %s';
var
  hSnap     : THandle;
  ProcessEntry : TProcessEntry32; // <<==see TLHelp32.pas for details
  Proceed   : Boolean;
begin
  // get a snapshot handle
  hSnap := CreateToolhelp32Snapshot( TH32CS_SNAPALL , 0 );
  if HSnap <> -1 then
  begin
   ProcessEntry.dwSize := SizeOf(TProcessEntry32);
   Proceed := Process32First(hSnap, ProcessEntry);
   while Proceed do
   begin
     with ProcessEntry do
     begin
      Buf.add('  ');
      Buf.Add('------------------------------------------------------');
      Buf.Add('ProcessID  ParentID ModuleID  Usage  Threads Prio Path');
      Buf.Add( Format( FmtProc, [Th32ProcessID, th32ParentProcessID,
                                         Th32ModuleID, cntUsage, cntThreads,
                                         pcPriClassBase, szEXEFile]));
      Buf.Add('------------------------------------------------------');

      if IncludeModules then
         GetModules( ProcessEntry.Th32ProcessID, Buf );
     end;
     Proceed := Process32Next( hSnap, ProcessEntry);
   end;
   CloseHandle( hSnap );
  end
  else
    ShowMessage( 'Oops...' + SysErrorMessage(GetLastError));
end;

{-------------------------------------------------------------}
{  Enumerates modules in use by a given ProcessID             }
{-------------------------------------------------------------}
procedure TForm1.GetModules( ProcessID: DWORD; Buf: TStrings );
const
  FmtMod = '    %8.8x  %6.1f     %4.4d %15s  %-s';
var
 hSnap : THandle;
 ModuleEntry : TModuleEntry32; // <<==see TLHelp32.pas for details
 Proceed     : Boolean;
begin
  hSnap := CreateToolhelp32Snapshot( TH32CS_SNAPMODULE , ProcessID );
  if HSnap <> -1 then
  begin
   //
   Buf.Add(' ');
   Buf.Add('    Modules used by ProcessID ' + IntToHex(ProcessID,8));
   Buf.Add('    ModuleID   Size(kb) Usage     Module        Path');
   Buf.Add('    --------   -------- ------    ------        ----');
   //
   ModuleEntry.dwSize := SizeOf(TModuleEntry32);
   Proceed :=  Module32First(hSnap, ModuleEntry);
   while Proceed do
   begin
     with ModuleEntry do
       Buf.add( Format( FmtMod, [Th32ModuleID, ModBaseSize/1024,
                                 GlblCntUsage,
                                 szModule,
                                 ExtractFilePath(szEXEPath)])
              );
     Proceed := Module32Next( hSnap, ModuleEntry);
   end;
   //
   CloseHandle( hSnap );
  end
  else
    ShowMessage( 'Oops...' + SysErrorMessage(GetLastError));
end;

end.
