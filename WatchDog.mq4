//+------------------------------------------------------------------+
//|                                                     WatchDog.mq4 |
//|                                                Copyright, Kirill |
//|                                         http://www.ForexBoat.com |
//+------------------------------------------------------------------+
#property copyright "Copyright, Kirill"
#property link      "http://www.ForexBoat.com"
#property copyright "Copyright 2021, Vladimir Zhbanko"
#property link      "https://vladdsm.github.io/myblog_attempt/"
#property version   "2.00"
#property strict

/*
v.2.00
Added option Account Monitoring - purpose is to write a file with current account profit (balance and equity)
*/


extern int AccountRow = 1;  
extern int DelayMinutes = 5;    
extern bool    eMailAlert                       = False;
extern bool OptAccountMonitoring = True;
 
 
// AccountRow   - Your favourites account number
// DelayMinutes - Delay in minutes, has to be greater than the chart timeframe
#include <18_EmailFromMT4.mqh>
#include <WinUser32.mqh>
#include <08_TerminalNumber.mqh>

#import "user32.dll"
  int GetParent(int hWnd);
  int GetDlgItem(int hDlg, int nIDDlgItem);
  int GetLastActivePopup(int hWnd);
#import
 
#define VK_HOME 0x24
#define VK_DOWN 0x28
#define VK_ENTER 0x0D
 
#define PAUSE 1000
datetime Old_Time=0;
bool is_reconect = true;
 
void OnInit()
{
   Old_Time=iTime(NULL,0,0);
   
   //send email on Sunday Morning once platform re-starts to work...
      if(eMailAlert)
        {
         EmailFromMT4(AccountRow);
        }
        
   
   
   OnTick();
}
 
void OnTick()
{

    //log account amount to file
    if(OptAccountMonitoring)
      {
        InfoAccountToCSV(T_Num());   
      }
    

   if (!IsDllsAllowed())
   {
      Alert("Watchdog: DLLs not alllowed!");
      return;
   }
   
   while (!IsStopped())
   {
      RefreshRates();
      if (Old_Time  == iTime(NULL,0,0)) is_reconect=true;
      else is_reconect=false;
      Old_Time=iTime(NULL,0,0);
      if (is_reconect)
      {
         Print("Watchdog: The chart has not been updated in " + string(DelayMinutes) + " minutes. Initating reconnection procedure...");
         Login(AccountRow);
      }
      

      //log account amount to file
      if(OptAccountMonitoring)
      {
        InfoAccountToCSV(T_Num());   
      }
      
      Sleep(DelayMinutes*60*1000);
   }
   
   
   return;
}

void Login(int Num)
{
   int hwnd = WindowHandle(Symbol(), Period());
   int hwnd_parent = 0;
   
   while (!IsStopped())
   {
      hwnd = GetParent(hwnd);
      if (hwnd == 0) break;
      hwnd_parent = hwnd;
   }
   
   if (hwnd_parent != 0)  
   {
      hwnd = GetDlgItem(hwnd_parent, 0xE81C); 
      hwnd = GetDlgItem(hwnd, 0x52);
      hwnd = GetDlgItem(hwnd, 0x8A70);
      
      PostMessageA(hwnd, WM_KEYDOWN, VK_HOME,0); 
      
      while (Num > 1)  
      {
         PostMessageA(hwnd, WM_KEYDOWN,VK_DOWN, 0); 
         Num--;
      }
      
      PostMessageA(hwnd, WM_KEYDOWN, VK_ENTER, 0);  
      Sleep(PAUSE);                                 
      
      hwnd = GetLastActivePopup(hwnd_parent);  
      PostMessageA(hwnd, WM_KEYDOWN, VK_ENTER, 0); 
   }
 
   return;
}

//+------------------------------------------------------------------+
//| FUNCTION ACCOUNT PROFIT TO CSV
//+------------------------------------------------------------------+
void InfoAccountToCSV(int TermNumber)
{
   //*3*_Logging account status to the file csv for further account management in R
                // record info to the file csv
                 string fileName = "AccountResultsT"+string(TermNumber)+".csv";//create the name of the file same for all symbols...
                 datetime TIME = iTime(Symbol(), PERIOD_CURRENT, 0);  //Time of the bar of the applied chart symbol
                 RefreshRates();
                 double myBalance = AccountBalance();
                 double myEquity  = AccountEquity();
                 double myProfit  = DoubleToStr(myEquity - myBalance);
                 Comment(fileName);
                 // open file handle
                 int handle = FileOpen(fileName,FILE_CSV|FILE_WRITE|FILE_SHARE_READ|FILE_SHARE_WRITE);
                              FileSeek(handle,0,SEEK_END);
                 string data = string(TIME) + "," + string(myBalance) + "," + string(myEquity) + "," + string(myProfit);
                 FileWrite(handle,data);   //write data to the file during each for loop iteration
                 FileClose(handle);        //close file when data write is over
}