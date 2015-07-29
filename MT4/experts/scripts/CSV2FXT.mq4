/*
    Copyright (C) 2009-2012 Birt Ltd <birt@eareview.net>

    This license governs use of the accompanying software. If you use the software, you accept this license. If you do not accept the license, do not use the software.
    
    1. Definitions

    The terms "reproduce", "reproduction", and "distribution" have the same meaning here as under U.S. copyright law.
    "You" means the licensee of the software, who is not engaged in designing, developing, or testing other software that has the same or substantially the same features or functionality as the software.
    "Your company" means the company you worked for when you downloaded the software.
    "Reference use" means use of the software within your company as a reference, in read only form, for the sole purposes of debugging and maintaining your products to run properly in conjuction with the software. For clarity, "reference use" does NOT include (a) the right to use the software for purposes of designing, developing, or testing other software that has the same or substantially the same features or functionality as the software, and (b) the right to distribute the software outside of your household or company.
    "Licensed patents" means any Licensor patent claims which read directly on the software as distributed by the Licensor under this license.
    
    2. Grant of Rights

    (A) Copyright Grant- Subject to the terms of this license, the Licensor grants you a non-transferable, non-exclusive, worldwide, royalty-free copyright license to use and to reproduce the software for reference use.
    (B) Patent Grant- Subject to the terms of this license, the Licensor grants you a non-transferable, non-exclusive, worldwide, royalty-free patent license under licensed patents for reference use.
    
    3. Limitations

    (A) No Trademark License- This license does not grant you any rights to use the Licensor's name, logo, or trademarks.
    (B) If you begin patent litigation against the Licensor over patents that you think may apply to the software (including a cross-claim or counterclaim in a lawsuit), your license to the software ends automatically.
    (C) The software is licensed "as-is." You bear the risk of using it. The Licensor gives no express warranties, guarantees or conditions. You may have additional consumer rights under your local laws which this license cannot change. To the extent permitted under your local laws, the Licensor excludes the implied warranties of merchantability, fitness for a particular purpose and non-infringement.
*/
#property copyright "birt"
#property link      "http://eareview.net/"
#property show_inputs

#define FILE_ATTRIBUTE_READONLY 1
#define GENERIC_READ -2147483648
#define OPEN_EXISTING 3
#define FILE_SHARE_READ 1
#define FILE_ATTRIBUTE_NORMAL 128
#define FILE_START 0
#define FILE_END 2
#define MAX_PATH 260
#define MB_ICONQUESTION 0x00000020
#define MB_ICONEXCLAMATION 0x00000030
#define MB_ICONSTOP 0x00000010
#define MB_YESNO 0x00000004
#define IDYES 6
#define INVALID_FILE_ATTRIBUTES -1
#define MOVEFILE_REPLACE_EXISTING 1

#import "kernel32.dll"
   int  SetFileAttributesA(string file, int attributes);
   int  GetFileAttributesA(string file);
   int  CreateFileA(string lpFileName, int dwDesiredAccess, int dwShareMode, int lpSecurityAttributes, int dwCreationDisposition, int dwFlagsAndAttributes, int hTemplateFile);
   int  GetFileSize(int hFile, int& lpFileSizeHigh[]);
   int  SetFilePointer(int hFile, int lDistanceToMove, int& lpDistanceToMoveHigh[], int dwMoveMethod);
   int  ReadFile(int hFile, int &lpBuffer[], int nNumberOfBytesToRead, int &lpNumberOfBytesRead[], int lpOverlapped);
   int  CloseHandle(int hObject);
   int  MoveFileExA(string lpExistingFileName, string lpNewFileName, int dwFlags);
#import "CsvReader.dll"
   int    CsvOpen(string fileName, int delimiter);
   string CsvReadString(int fd);
   double CsvReadDouble(int fd);
   int    CsvIsLineEnding(int fd);
   int    CsvIsEnding(int fd);
   int    CsvClose(int fd);
   int    CsvSeek(int fd, int offset, int origin);
#import

#include <FXTHeader.mqh>
extern string CSV2FXT_version_0.43="";
extern string CsvFile="";
extern bool   CreateHst=true;
extern string ValueInfo="All spreads & commissions are in pips regardless of the number of digits.";
extern double Spread = 0.0;
extern string DateInfo1="Use YYYY.MM.DD as date format for start/end date.";
extern string DateInfo2="Leave the fields empty to use the awhole CSV file.";
extern string StartDate="";
extern string EndDate="";
extern bool   UseRealSpread=false;
extern double SpreadPadding = 0.0;
extern string CommissionInfo = "Only fill in the desired commission type.";
extern double PipsCommission = 0.0;
extern double MoneyCommission = 0.0;
extern string Leverage = "automatic (current account leverage)";
extern string GMTOffsetInfo1 = "Specify the target GMT Offset.";
extern string GMTOffsetInfo2 = "The FXT GMT offset is the GMT offset of the resulting FXT file.";
extern int    FXTGMTOffset = 0;
extern string GMTOffsetInfo3 = "The CSV GMT offset is the GMT offset of the input tick data CSV file.";
extern string CSVGMTOffset = "autodetect";
extern string DSTInfo1 = "0 - no DST, 1 - US DST, 2 - Europe DST, 3 - Russian DST, 4 - Australian AEDT";
extern int    FXTDST = 0;
extern string CSVDST = "autodetect";
extern bool   RemoveDuplicateTicks = true;
extern string TimeShiftInfo = "See the guide for more info.";
extern bool   TimeShift = false;
extern bool   CreateM1 = false;
extern bool   CreateM5 = false;
extern bool   CreateM15 = false;
extern bool   CreateM30 = false;
extern bool   CreateH1 = false;
extern bool   CreateH4 = false;
extern bool   CreateD1 = false;
extern bool   CreateW1 = false;
extern bool   CreateMN = false;
// this was removed from the externs because mostly nobody needs it
//extern string VolumeInfo1="Only enable this if you actually need it.";
bool UseRealVolume=false;

int      ExtSrcGMT = 0;
int      ExtSrcDST = 0;

int      ExtPeriods[9] = { 1, 5, 15, 30, 60, 240, 1440, 10080, 43200 };
int      ExtPeriodCount = 9;
int      ExtPeriodSeconds[9];
int      ExtHstHandle[9];
int      ExtFxtHandle[9];
bool     ExtPeriodSelection[9] = { false, false, false, false, false, false, false, false, false };

datetime start_date=0;
datetime end_date=0;

int      ExtTicks;
int      ExtBars[9];
int      ExtCsvHandle=-1;
datetime ExtLastTime;
datetime ExtLastBarTime[9];
double   ExtLastOpen[9];
double   ExtLastLow[9];
double   ExtLastHigh[9];
double   ExtLastClose[9];
double   ExtLastVolume[9];
double   ExtSpread;

int      ExtStartTick = 0;
int      ExtEndTick = 0;
int      ExtLastYear = 0;

int      ExtCsvDelimiter = 0;

int      ExtFieldTypes[];
int      ExtFieldCount;
int      ExtDateField = -1;
int      ExtDateFormat = -1;
int      ExtDateSeparator = 0;
int      ExtBidField1 = -1;
bool     ExtBidField1SpecialCase = false; // only useful for code visual indication
int      ExtBidField2 = -1;
int      ExtAskField1 = -1;
bool     ExtAskField1SpecialCase = false;
int      ExtAskField2 = -1;
int      ExtVolumeBidField = -1;
bool     ExtVolumeBidFieldSpecialCase = true;
int      ExtVolumeAskField = -1;
bool     ExtVolumeAskFieldSpecialCase = true;
double   ExtVolumeDivide = false;
double   ExtTickMaxDifference = 0.1; // if there's more than 10% between ticks, something is definitely wrong

datetime ExtFirstDate = 0;
datetime ExtLastDate = 0;

int      ExtMinHoursGap = 2;

#define FIELD_TYPE_STRING 0
#define FIELD_TYPE_NUMBER 1
#define KNOWN_DATE_FORMATS 20

int start()
  {
   for(int try=0; try<5; try++) if (IsConnected()) break; else Sleep(3000);
   if (!IsConnected()) {
      MessageBox("This script requires a connection to the broker.", "CSV2FXT", MB_ICONSTOP);
      return;
   }
   if (!IsDllsAllowed()) {
      MessageBox("DLL calls are not allowed! They need to be enabled for this script to run (go to Tools->Options->Expert Advisors, enable Allow DLL calls and disable Confirm DLL calls).", "CSV2FXT", MB_ICONSTOP);
      return;
   }
   if (HasExtraDigit()) {
      Spread *= 10;
      SpreadPadding *= 10;
   }
   else {
      Spread = NormalizeDouble(Spread, 0);
      SpreadPadding = NormalizeDouble(SpreadPadding, 0);
   }
   if (UseRealSpread) {
      UseRealVolume = false;
   }
   for (int i = 0; i < ExtPeriodCount; i++) {
      if (ExtPeriods[i] == Period()) {
         ExtPeriodSelection[i] = true;
         break;
      }
   }
   int LeverageVal = AccountLeverage();
   if (IsNumeric(Leverage)) {
      LeverageVal = StrToInteger(Leverage);
   }
   
   if(CreateM1 == true) ExtPeriodSelection[0] = true;
   if(CreateM5 == true) ExtPeriodSelection[1] = true;
   if(CreateM15 == true) ExtPeriodSelection[2] = true;
   if(CreateM30 == true) ExtPeriodSelection[3] = true;
   if(CreateH1 == true) ExtPeriodSelection[4] = true;
   if(CreateH4 == true) ExtPeriodSelection[5] = true;
   if(CreateD1 == true) ExtPeriodSelection[6] = true;
   if(CreateW1 == true) ExtPeriodSelection[7] = true;
   if(CreateMN == true) ExtPeriodSelection[8] = true;
   
   if (CsvFile == "") {
      CsvFile = StringSubstr(Symbol(),0,6) + ".csv";
   }
   ExtCsvHandle=FileOpen(CsvFile,FILE_CSV|FILE_READ,',');
   if(ExtCsvHandle<0) {
      MessageBox("Can\'t open input file experts\\files\\"  + CsvFile, "CSV2FXT", MB_ICONSTOP);
      return(-1);
   }
   FileClose(ExtCsvHandle);
   if (!UseRealSpread && Spread == 0) {
      if (TimeDayOfWeek(TimeLocal()) == 0 || TimeDayOfWeek(TimeLocal()) == 6) {
         double currentSpread = Ask - Bid;
         double point = Point;
         if (HasExtraDigit()) {
            point *= 10;
         }
         currentSpread /= point;
         int response = MessageBox("You are building an FXT file with fixed spread using the current broker spread (" + DoubleToStr(currentSpread, 1) + " pips) during the weekend. Are you sure you want to proceed?", "Spread warning", MB_YESNO | MB_ICONQUESTION);
         if (response != IDYES) {
            return(0);
         }
      }
   }
   if (StringLen(StartDate) > 0) {
      start_date = StrToTime(StartDate);
   }
   if (StringLen(EndDate) > 0) {
      end_date = StrToTime(EndDate);
   }
   if (!FigureOutCSVFormat(CsvFile)) {
      MessageBox("Bad CSV format. Aborting.", "CSV2FXT", MB_ICONSTOP);
      return;
   }
   datetime cur_time,cur_open;
   double   tick_price;
   double   tick_volume;
//----
   ExtTicks = 0;
   ExtLastTime=0;
//---- open input csv-file
   ExtCsvHandle=CsvOpen(TerminalPath() + "\\experts\\files\\" + CsvFile, ExtCsvDelimiter);
   if (ExtCsvHandle < 0) {
      MessageBox("Error opening CSV file. Aborting.", "CSV2FXT", MB_ICONSTOP);
      return;
   }
//---- open output fxt files
   if (!OpenFxtFiles()) {
      MessageBox("Unable to open any of the FXT files. Aborting.", "CSV2FXT", MB_ICONSTOP);
      return;
   }
//----
   for (i = 0; i < ExtPeriodCount; i++) {
      ExtPeriodSeconds[i] = ExtPeriods[i] * 60;
      ExtBars[i]=0;
      ExtLastBarTime[i]=0;
   }
   if (HasExtraDigit()) {
      PipsCommission *= 10;
   }
   for (i = 0; i < ExtPeriodCount; i++) {
      if (ExtPeriodSelection[i]) {
         WriteHeader(ExtFxtHandle[i],Symbol(),ExtPeriods[i],0,Spread,PipsCommission,MoneyCommission,LeverageVal);
      }
   }
//---- open hst-files and write it's header
   if(CreateHst) WriteHstHeaders();
   int progress = -1;
   if (ExtLastDate != 0) {
      ObjectCreate("csv2fxt-label",OBJ_LABEL,0,0,0,0,0);
      ObjectSet("csv2fxt-label",OBJPROP_XDISTANCE,30);
      ObjectSet("csv2fxt-label",OBJPROP_YDISTANCE,30);
   }
   double span = ExtLastDate - ExtFirstDate;
   datetime firstTick = 0;
//---- csv read loop
   while(!IsStopped())
     {
      //---- if end of file reached exit from loop
      bool hasMoreRecords = ReadNextTick(cur_time,tick_price,tick_volume);
      if (ExtLastDate != 0) {
         if (firstTick == 0) firstTick = cur_time;
         double currentProgress = (cur_time - firstTick);
         currentProgress /= span;
         currentProgress *= 100;
         if (ExtLastDate != 0 &&
             currentProgress >= progress + 1) {
             progress = MathFloor(currentProgress);
             ObjectSetText("csv2fxt-label",progress + "%",16,"Tahoma",Gold);
             WindowRedraw();
         }
      }
      if (TimeYear(cur_time) != ExtLastYear) {
         ExtLastYear = TimeYear(cur_time);
         Print("Starting to process " + Symbol() + " " + ExtLastYear + ".");
      }
      for (i = 0; i < ExtPeriodCount; i++) {
       //---- calculate bar open time from tick time
       cur_open=cur_time/ExtPeriodSeconds[i];
       cur_open*=ExtPeriodSeconds[i];
       //---- new bar?
       bool newBar = false;
       if (i < 7) {
         if(ExtLastBarTime[i]!=cur_open) {
            newBar = true;
         }
       }
       else if (i == 7) {
         // weekly timeframe
         if (cur_time - ExtLastBarTime[i] >= ExtPeriodSeconds[i]) {
            newBar = true;
         }
         if (newBar) {
            cur_open = cur_time;
            cur_open -= cur_open % (1440 * 60);
            while (TimeDayOfWeek(cur_open) != 0) {
               cur_open -= 1440 * 60;
            }
         }
       }
       else if (i == 8) {
         // monthly timeframe
         if (ExtLastBarTime[i] == 0) {
            newBar = true;
         }
         if (TimeDay(cur_time) < 5 && (cur_time - ExtLastBarTime[i] > 10 * 1440 * 60)) {
            newBar = true;
         }
         if (newBar) {
            cur_open = cur_time;
            cur_open -= cur_open % (1440 * 60);
            while (TimeDay(cur_open) != 1) {
               cur_open -= 1440 * 60;
            }
         }
       }
       if(newBar)
         {
          if(ExtBars[i]>0) {
            WriteBar(i);
            if (i == 0) { // fill in flat the M1 bars if there was no tick for several minutes
              int diff = (cur_open - ExtLastBarTime[i]) / ExtPeriodSeconds[i];
              if (diff > 1 && diff < 5) {
                 int tempLastBarTime = ExtLastBarTime[i];
                 ExtLastLow[i] = ExtLastClose[i];
                 ExtLastHigh[i] = ExtLastClose[i];
                 ExtLastOpen[i] = ExtLastClose[i];
                 ExtLastVolume[i] = 0;
                 for (int k = 1; k < diff; k++) {
                    ExtLastBarTime[i] = tempLastBarTime + k * ExtPeriodSeconds[i];
                    WriteBar(i);
                    ExtBars[i]++;
                 }
              }
            }
          }
          ExtLastBarTime[i]=cur_open;
          ExtLastOpen[i]=tick_price;
          ExtLastLow[i]=tick_price;
          ExtLastHigh[i]=tick_price;
          ExtLastClose[i]=tick_price;
          if (tick_volume > 0) {
            ExtLastVolume[i]=tick_volume;
          }
          else {
            ExtLastVolume[i]=1;
          }
          ExtBars[i]++;
         }
       else
         {
          //---- check for minimum and maximum
          if(ExtLastLow[i]>tick_price)  ExtLastLow[i]=tick_price;
          if(ExtLastHigh[i]<tick_price) ExtLastHigh[i]=tick_price;
          ExtLastClose[i]=tick_price;
          ExtLastVolume[i]+=tick_volume;
         }
      }

      if (start_date > 0 && cur_time < start_date) continue;
      if (end_date > 0 && cur_time >= end_date) {
        break;
      }
      if (ExtStartTick == 0) ExtStartTick = cur_time;
      ExtEndTick = cur_time;
      WriteTick();
      if(!hasMoreRecords) break;
     }
//---- finalize
   for (i = 0; i < ExtPeriodCount; i++) {
    WriteBar(i);
    if(ExtHstHandle[i]>0) FileClose(ExtHstHandle[i]);
   }
   CsvClose(ExtCsvHandle);
   for (i = 0; i < ExtPeriodCount; i++) {
      if (ExtPeriodSelection[i]) {
//---- store processed bars amount
         FileFlush(ExtFxtHandle[i]);
         FileSeek(ExtFxtHandle[i],216,SEEK_SET);
         FileWriteInteger(ExtFxtHandle[i],ExtBars[i],LONG_VALUE);
         FileWriteInteger(ExtFxtHandle[i],ExtStartTick,LONG_VALUE);
         FileWriteInteger(ExtFxtHandle[i],ExtEndTick,LONG_VALUE);
         FileClose(ExtFxtHandle[i]);
         string fileName=Symbol()+ExtPeriods[i]+"_0.fxt";
         SetFileAttributesA(TerminalPath() + "\\experts\\files\\" + fileName, FILE_ATTRIBUTE_READONLY);
      }
   }
   Print(ExtTicks," ticks added.");
   if (ExtLastDate != 0) {
      ObjectDelete("csv2fxt-label");
      WindowRedraw();
   }
   string hstFiles = "";
   string note = "";
   if (CreateHst) {
      hstFiles = " and the HST files to history\\" + AccountServer();
      note = "\nNote: this will overwrite any existing " + Symbol() + " HST files in the history\\" + AccountServer() + " folder!";
   }
   if (MessageBox("Processing for " + Symbol() + " has finished.\nWould you like to move the FXT file(s) to tester\\history" + hstFiles + "?" + note, "CSV2FXT", MB_YESNO | MB_ICONQUESTION) == IDYES) {
      for (i = 0; i < ExtPeriodCount; i++) {
         if (ExtPeriodSelection[i] && ExtFxtHandle[i] >= 0) {
            fileName=Symbol()+ExtPeriods[i]+"_0.fxt";
            int attr = GetFileAttributesA(TerminalPath() + "\\tester\\history\\" + fileName);
            bool copyOk = false;
            if (attr == INVALID_FILE_ATTRIBUTES) {
               copyOk = true;
            }
            else if ((attr & FILE_ATTRIBUTE_READONLY) != 0) {
               if (MessageBox("File tester\\history\\" + fileName + " already exists and has its readonly attribute set. Would you like to overwrite it?", "CSV2FXT", MB_ICONQUESTION | MB_YESNO) == IDYES) {
                  SetFileAttributesA(TerminalPath() + "\\tester\\history\\" + fileName, FILE_ATTRIBUTE_NORMAL);
                  copyOk = true;
               }
            }
            else {
               copyOk = true;
            }
            if (copyOk) {
               if (MoveFileExA(TerminalPath() + "\\experts\\files\\" + fileName, TerminalPath() + "\\tester\\history\\" + fileName, MOVEFILE_REPLACE_EXISTING) == 0) {
                  MessageBox("Unable to move experts\\files\\" + fileName + " to " + "tester\\history\\" + fileName + ".", "CSV2FXT", MB_ICONEXCLAMATION);
               }
            }
         }
      }
      if (CreateHst) {
         string targetPath = "history\\" + AccountServer() + "\\";
         for (i = 0; i < ExtPeriodCount; i++) {
            fileName = Symbol() + ExtPeriods[i] + ".hst";
            if (MoveFileExA(TerminalPath() + "\\experts\\files\\" + fileName, TerminalPath() + "\\" + targetPath + fileName, MOVEFILE_REPLACE_EXISTING) == 0) {
               MessageBox("Unable to move experts\\files\\" + fileName + " to " + targetPath + fileName + ".");
            }
         }
         MessageBox("You should restart your MT4 terminal at this point to make sure the HST files are properly synchronized.", "CSV2FXT", MB_ICONEXCLAMATION);
      }
   }
//----
   return(0);
  }

int lastTickTimeMin = -1;
double lastTickBid = 0;
double lastTickAsk = 0;
int extraFieldsMsg = 0;
int wrongPricesMsg = 0;
int gapAlertMsg = 0;

bool OpenFxtFiles() {
   for (int i = 0; i < ExtPeriodCount; i++) {
      if (ExtPeriodSelection[i]) {
         string fileName=Symbol()+ExtPeriods[i]+"_0.fxt";
         ExtFxtHandle[i]=FileOpen(fileName,FILE_BIN|FILE_WRITE);
         if(ExtFxtHandle[i]<0) {
            int attr = GetFileAttributesA(TerminalPath() + "\\experts\\files\\" + fileName);
            if ((attr & FILE_ATTRIBUTE_READONLY) != 0) {
               if (MessageBox("File experts\\files\\" + fileName + " already exists and has its readonly attribute set. Would you like to overwrite it?", "CSV2FXT", MB_ICONQUESTION | MB_YESNO) == IDYES) {
                  SetFileAttributesA(TerminalPath() + "\\experts\\files\\" + fileName, FILE_ATTRIBUTE_NORMAL);
                  ExtFxtHandle[i]=FileOpen(fileName,FILE_BIN|FILE_WRITE);
                  if (ExtFxtHandle[i]<0) {
                     MessageBox("Was unable to open experts\\files\\" + fileName + " even after removing its readonly attribute. Proceeding with any others.", "CSV2FXT", MB_ICONEXCLAMATION);
                  }
               }
            }
            else {
               MessageBox("Unable to open experts\\files\\" + fileName + ". Proceeding with any others.", "CSV2FXT", MB_ICONEXCLAMATION);
            }
         }
      }
   }
   bool result = false;
   for (i = 0; i < ExtPeriodCount; i++) {
      if (ExtPeriodSelection[i] && ExtFxtHandle[i] >= 0) {
         result = true;
      }
      else {
         ExtPeriodSelection[i] = false;
      }
   }
   return (result);
}

// Dukascopy custom exported data format:
// yyyy.mm.dd hh:mm:ss,bid,ask,bid_volume,ask_volume
bool ReadNextTick(datetime& cur_time, double& tick_price, double& tick_volume)
  {
  tick_volume = 0;
//----
   bool hadOlderTickError = false;
   while(!IsStopped())
	{
      // read record
      datetime date_time = 0;
      double dblAsk = 0, dblBid = 0, dblAskVol = 0, dblBidVol = 0;
      bool brokenRecord = false;
      for (int i = 0; i < ExtFieldCount; i++) {
         if (ExtFieldTypes[i] == FIELD_TYPE_STRING) {
            string field = CsvReadString(ExtCsvHandle);
            if (ExtDateField == i) {
               if (ParseDate(field, ExtDateFormat, date_time)) {
                  if (date_time == 0) {
                     brokenRecord = true;
                     break;
                  }
               }
               else {
                  brokenRecord = true;
                  break;
               }
            }
            else if (ExtAskField1 == i) {
               dblAsk = SpecialStrToDouble(field);
               if (dblAsk == 0) {
                  brokenRecord = true;
                  break;
               }
            }
            else if (ExtBidField1 == i) {
               dblBid = SpecialStrToDouble(field);
               if (dblBid == 0) {
                  brokenRecord = true;
                  break;
               }
            }
	         else if (ExtVolumeAskField == i) {
	            dblAskVol = SpecialStrToDouble(field);
	         }
	         else if (ExtVolumeBidField == i) {
	            dblBidVol = SpecialStrToDouble(field);
	         }
         }
         else {
            double value = CsvReadDouble(ExtCsvHandle);
	         if (ExtAskField1 == i) {
               if (value == 0) {
                  brokenRecord = true;
                  break;
               }
	            dblAsk = value;
	         }
	         else if (ExtBidField1 == i) {
               if (value == 0) {
                  brokenRecord = true;
                  break;
               }
	            dblBid = value;
	         }
	         else if (ExtAskField2 == i) {
	            dblAsk += MakeFractional(DoubleToStr(value, 0));
	         }
	         else if (ExtBidField2 == i) {
	            dblBid += MakeFractional(DoubleToStr(value, 0));
	         }
	         else if (ExtVolumeAskField == i) {
	            dblAskVol = value;
	         }
	         else if (ExtVolumeBidField == i) {
	            dblBidVol = value;
	         }
	      }
	   }

	   if (!CsvIsEnding(ExtCsvHandle) && !CsvIsLineEnding(ExtCsvHandle) && extraFieldsMsg < 20 &&
	        ExtLastTime != 0) { // don't report this if it's the header row
	      Print("Extra fields detected & discarded in the CSV file in record after " + TimeToStr(ExtLastTime, TIME_MINUTES|TIME_DATE|TIME_SECONDS));
	      extraFieldsMsg++;
	      if (extraFieldsMsg >= 20) {
	        Print("The extra fields message repeated over 20 times so far. It is now suppressed to avoid cluttering your log files.");
	      }
	   }

	   if (!SkipToNextLine(ExtCsvHandle)) { // in case there are extra fields (broken CSVs), skip to the next record
	      // file is ending
	      return (false);
	   }
	   
	   if (brokenRecord) {
	      if (ExtLastTime != 0) {  // don't report this if it's the header row
	        Print("Broken record in the CSV file after " + TimeToStr(ExtLastTime, TIME_MINUTES|TIME_DATE|TIME_SECONDS));
	      }
	      continue;
	   }
	   
	   dblAsk = NormalizeDouble(dblAsk, Digits);
	   dblBid = NormalizeDouble(dblBid, Digits);
	   
	   if (wrongPricesMsg < 20 && ExtLastTime != 0) {
	     if ( (lastTickAsk != 0 && MathAbs(dblAsk - lastTickAsk) > lastTickAsk * ExtTickMaxDifference) ||
	          (lastTickBid != 0 && MathAbs(dblBid - lastTickBid) > lastTickBid * ExtTickMaxDifference) ||
	          MathAbs(dblBid - dblAsk) > lastTickBid * ExtTickMaxDifference) {
           Print("There seems to be something wrong with the prices for the tick at " + TimeToStr(date_time, TIME_MINUTES|TIME_DATE|TIME_SECONDS) + ". Skipping it. Skipped tick ask: " + DoubleToStr(dblAsk, Digits) + ", bid: " + DoubleToStr(dblBid, Digits) + "; previous tick ask: " + DoubleToStr(lastTickAsk, Digits) + ", bid: " + DoubleToStr(lastTickBid, Digits) + ".");
	        wrongPricesMsg++;
	        if (wrongPricesMsg >= 20) {
	          Print("The wrong prices message repeated over 20 times so far. It is now suppressed to avoid cluttering your log files.");
             Alert("Your CSV file appears to have a lot of damaged prices. You should check the experts log for more information.");
	        }
	        continue;
	     }
      }
      
      date_time -= ExtSrcGMT * 3600;
      date_time -= DSTOffset(cur_time, ExtSrcDST);
	  
      cur_time = date_time + FXTGMTOffset * 3600;
      cur_time += DSTOffset(cur_time, FXTDST);
      if (TimeShift) {
         cur_time -= 883612800;
      }
      tick_price = dblBid;
      
      if (UseRealSpread) {
         ExtSpread = dblAsk - tick_price + SpreadPadding * Point;
         if (ExtSpread < 0) ExtSpread = 0;
      }
      
      if (!UseRealVolume) {
         tick_volume = 1;
      }
      else {
         tick_volume += dblAskVol / ExtVolumeDivide + dblBidVol / ExtVolumeDivide;
      }
      if (tick_volume <= 0) {
         tick_volume = 1;
      }

      if (RemoveDuplicateTicks) {
         if (TimeMinute(cur_time) == lastTickTimeMin && dblBid == lastTickBid && (!UseRealSpread || dblAsk == lastTickAsk)) continue;
      }
      lastTickTimeMin = TimeMinute(cur_time);
      lastTickAsk = dblAsk;
      lastTickBid = dblBid;
      
      if (ExtLastTime != 0 && cur_time >= ExtLastTime + ExtMinHoursGap * 3600) {
         int day = TimeDayOfWeek(cur_time);
         bool alert = true;
         double gap = (cur_time - ExtLastTime) / (3600);
         if (day == 0 || day == 1) { // Sunday or Monday
            if (gap >= 42 && gap <= 54) { // weekend duration accounting for an early or late market start
               alert = false;
            }
         }
         int curDay = TimeDay(cur_time);
         int curMonth = TimeMonth(cur_time);
         int oldDay = TimeDay(ExtLastTime);
         int oldMonth = TimeMonth(ExtLastTime);
         if (curMonth == 12 && curDay > 24 && curDay < 28 && oldMonth == 12 && oldDay <= 24 && oldDay > 21) { // Christmas, accounting for potential weekend before and after
            alert = false;
         }
         if (curMonth == 1 && curDay < 4 && oldMonth == 12 && oldDay >= 29) { // New year, accounting for potential weekend before and after
            alert = false;
         }
         if (alert) {
            string msg = "Possible error: gap after " + TimeToStr(ExtLastTime, TIME_MINUTES|TIME_DATE|TIME_SECONDS) + " (" + DoubleToStr(gap, 1) + " hours).";
            if (gapAlertMsg < 5) {
               Alert(msg);
            }
            gapAlertMsg++;
            Print(msg);
            if (gapAlertMsg == 5) {
               Print("There were 5 gap errors so far. Since your CSV file is starting to look like Schweizer cheese, alerts are now suppressed.");
            }
         }
      }
      //---- time must go forward. if no then read further
      if(cur_time>=ExtLastTime) break;
      if (!hadOlderTickError) {
         Print("Error in the CSV file: encountered older timestamp(s) right after the tick at " + TimeToStr(ExtLastTime, TIME_DATE|TIME_MINUTES|TIME_SECONDS) + " (older timestamp: " + TimeToStr(cur_time, TIME_DATE|TIME_MINUTES|TIME_SECONDS) + ").");
         hadOlderTickError = TRUE;
      }
   }
   ExtLastTime=cur_time;
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void WriteTick()
  {
//---- current bar state
   for (int i = 0; i < ExtPeriodCount; i++) {
      if (ExtPeriodSelection[i]) {
         FileWriteInteger(ExtFxtHandle[i], ExtLastBarTime[i], LONG_VALUE);
         FileWriteDouble(ExtFxtHandle[i], ExtLastOpen[i], DOUBLE_VALUE);
         FileWriteDouble(ExtFxtHandle[i], ExtLastLow[i], DOUBLE_VALUE);
         FileWriteDouble(ExtFxtHandle[i], ExtLastHigh[i], DOUBLE_VALUE);
         FileWriteDouble(ExtFxtHandle[i], ExtLastClose[i], DOUBLE_VALUE);
         if (UseRealSpread) {
            FileWriteDouble(ExtFxtHandle[i], ExtSpread, DOUBLE_VALUE);
         }
         else {
            FileWriteDouble(ExtFxtHandle[i], ExtLastVolume[i], DOUBLE_VALUE);
         }
//---- incoming tick time
         FileWriteInteger(ExtFxtHandle[i], ExtLastTime, LONG_VALUE);
//---- flag 4 (it must be not equal to 0)
         FileWriteInteger(ExtFxtHandle[i], 4, LONG_VALUE);
      }
   }
//---- ticks counter
   ExtTicks++;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void WriteHstHeaders()
  {
//---- History header
   for (int i = 0; i < ExtPeriodCount; i++) {
      int    i_version=400;
      string c_copyright;
      string c_symbol=Symbol();
      int    i_period=ExtPeriods[i];
      int    i_digits=Digits;
      int    i_unused[15];
//----  
      ExtHstHandle[i]=FileOpen(c_symbol+i_period+".hst", FILE_BIN|FILE_WRITE);
      if(ExtHstHandle[i] < 0) Print("Error opening " + c_symbol + i_period);
//---- write history file header
      c_copyright="(C)opyright 2003, MetaQuotes Software Corp.";
      FileWriteInteger(ExtHstHandle[i], i_version, LONG_VALUE);
      FileWriteString(ExtHstHandle[i], c_copyright, 64);
      FileWriteString(ExtHstHandle[i], c_symbol, 12);
      FileWriteInteger(ExtHstHandle[i], i_period, LONG_VALUE);
      FileWriteInteger(ExtHstHandle[i], i_digits, LONG_VALUE);
      FileWriteArray(ExtHstHandle[i], i_unused, 0, 15);
   }
  }
//+------------------------------------------------------------------+
//| write corresponding hst-file                                     |
//+------------------------------------------------------------------+
void WriteBar(int i)
  {
   if(ExtHstHandle[i]>0)
     {
      FileWriteInteger(ExtHstHandle[i], ExtLastBarTime[i], LONG_VALUE);
      FileWriteDouble(ExtHstHandle[i], ExtLastOpen[i], DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle[i], ExtLastLow[i], DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle[i], ExtLastHigh[i], DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle[i], ExtLastClose[i], DOUBLE_VALUE);
      FileWriteDouble(ExtHstHandle[i], ExtLastVolume[i], DOUBLE_VALUE);
     }
  }
//+------------------------------------------------------------------+

int DSTOffset(int t, int DSTType) {
   if (isDST(t, DSTType)) {
      return (3600);
   }
   return (0);
}

bool isDST(int t, int zone = 0) {
   if (zone == 2 || zone == 3) { // Europe & Russia
      if (zone == 3 && t > D'28.03.2011') return (false); // no DST for Russia after 28.03.2011
      datetime dstStart = StrToTime(TimeYear(t) + ".03.31 01:00");
      while (TimeDayOfWeek(dstStart) != 0) { // last Sunday of March
         dstStart -= 3600 * 24;
      }
      datetime dstEnd = StrToTime(TimeYear(t) + ".10.31 01:00");
      while (TimeDayOfWeek(dstEnd) != 0) { // last Sunday of October
         dstEnd -= 3600 * 24;
      }
      if (t >= dstStart && t < dstEnd) {
         return (true);
      }
      else {
         return (false);
      }
   }
   else if (zone == 1) { // US
      dstStart = StrToTime(TimeYear(t) + ".03.01 00:00"); // should be Saturday 21:00 GMT (New York is at GMT-5 and it changes at 2AM) but it doesn't really matter since we have no market during the weekend
      int sundayCount = 0;
      while (true) { // second Sunday of March
         if (TimeDayOfWeek(dstStart) == 0) {
            sundayCount++;
            if (sundayCount == 2) break;
         }
         dstStart += 3600 * 24;
      }
      dstEnd = StrToTime(TimeYear(t) + ".11.01 00:00");
      while (TimeDayOfWeek(dstEnd) != 0) { // first Sunday of November
         dstEnd += 3600 * 24;
      }
      if (t >= dstStart && t < dstEnd) {
         return (true);
      }
      else {
         return (false);
      }
   }
   else if (zone == 4) { // Australia
      datetime nonDstStart = StrToTime(TimeYear(t) + ".04.01 01:00");
      while (TimeDayOfWeek(nonDstStart) != 0) { // first Sunday of April
         nonDstStart += 3600 * 24;
      }
      datetime nonDstEnd = StrToTime(TimeYear(t) + ".10.01 01:00");
      while (TimeDayOfWeek(nonDstEnd) != 0) { // first Sunday of October
         nonDstEnd += 3600 * 24;
      }
      if (t >= nonDstStart && t < nonDstEnd) {
         return (false);
      }
      else {
         return (true);
      }
   }
   return (false);
}


bool FigureOutCSVFormat(string CsvFile) {
   if (IsCorrectDelimiter(CsvFile, ',')) {
      Print("CSV delimiter: comma (,).");
      ExtCsvDelimiter = ',';
   }
   else if (IsCorrectDelimiter(CsvFile, ';')) {
      Print("CSV delimiter: semicolon (;).");
      ExtCsvDelimiter = ';';
   }
   else if (IsCorrectDelimiter(CsvFile, '\t')) {
      Print("CSV delimiter: tab.");
      ExtCsvDelimiter = '\t';
   }
   else if (IsCorrectDelimiter(CsvFile, '|')) {
      Print("CSV delimiter: pipe.");
      ExtCsvDelimiter = '|';
   }
   else {
      MessageBox("Could not figure out the CSV delimiter.", "CSV2FXT", MB_ICONSTOP);
      return (false);
   }
   int csvHandle = CsvOpen(TerminalPath() + "\\experts\\files\\" + CsvFile, ExtCsvDelimiter);
   if (csvHandle < 0) {
      MessageBox("Error opening CSV file. Aborting.", "CSV2FXT", MB_ICONSTOP);
      return (false);
   }
   int i = 0;
   SkipToNextLine(csvHandle); // skip a potential header, just in case there are problems with the locale & comma
   while (true) {
      string discarded = CsvReadString(csvHandle);
      i++;
      if (CsvIsLineEnding(csvHandle) == 1) {
         break;
      }
   }
   ExtFieldCount = i;
   ArrayResize(ExtFieldTypes, ExtFieldCount);
   CsvSeek(csvHandle, 0, SEEK_SET);
   string field = CsvReadString(csvHandle);
   if (HasLetters(field)) {
      // 2 possible cases: header line or first field is the pair name
      field = CsvReadString(csvHandle);
      if (HasLetters(field)) {
         // next field is also text, we must be dealing with a header line
         SkipToNextLine(csvHandle);
      }
      else {
         // the first field is the currency pair name, what a waste of space
         CsvSeek(csvHandle, 0, SEEK_SET);
      }
   }
   else {
      CsvSeek(csvHandle, 0, SEEK_SET);
   }
   double price1 = 0, price2 = 0, volume1 = 0, volume2 = 0;
   int price1field1 = -1, price1field2 = -1, price2field1 = -1, price2field2 = -1, volume1field = -1, volume2field = -1;
   bool splitRecord = false;
   bool price1specialCase = false;
   bool price2specialCase = false;
   bool volume1specialCase = false;
   bool volume2specialCase = false;
   bool assignedPrice1 = false;
   bool assignedPrice2 = false;
   bool assignedVolume1 = false;
   bool assignedVolume2 = false;
   bool askFirst = false;
   string firstDate = "";
   int fieldid = 0;
   while (fieldid < ExtFieldCount) {
      field = CsvReadString(csvHandle);
      if (HasLetters(field)) {
         // we've probably had a header and we're now on line 1 reading the currency pair name or something
         Print ("Column " + (fieldid) + " appears to be a text field, ignoring it. Sample: " + field);
         ExtFieldTypes[fieldid] = FIELD_TYPE_STRING;
      }
      else if (IsNumeric(field)) {
         Print ("Column " + (fieldid) + " is a numeric field.");
         ExtFieldTypes[fieldid] = FIELD_TYPE_NUMBER;
         if (HasComma(field)) {
            // we have a special case, the delimiter is not comma and the numbers look like 1,2345
            ExtFieldTypes[fieldid] = FIELD_TYPE_STRING; // have to read it as a string
            if (splitRecord) {
               // cannot have a split record where the second part has a decimal separator
               MessageBox("Comma issues detected, perhaps extra field.", "CSV2FXT", MB_ICONSTOP);
               CsvClose(csvHandle);
               return (false);
            }
            double value = SpecialStrToDouble(field);
            if (!assignedPrice1) {
               price1 = value;
               price1specialCase = true;
               assignedPrice1 = true;
               price1field1 = fieldid;
            }
            else if (!assignedPrice2) {
               price2 = value;
               price2specialCase = true;
               assignedPrice2 = true;
               price2field1 = fieldid;
            }
            else if (!assignedVolume1) {
               volume1 = value;
               volume1specialCase = true;
               assignedVolume1 = true;
               volume1field = fieldid;
            }
            else if (!assignedVolume2) {
               volume2 = value;
               volume2specialCase = true;
               assignedVolume2 = true;
               volume2field = fieldid;
            }
         }
         else if (HasDot(field)) {
            // looks like a perfectly good numeric value
            if (splitRecord) {
               // cannot have a split record where the second part has a decimal separator
               MessageBox("Comma issues detected, perhaps extra field.", "CSV2FXT", MB_ICONSTOP);
               CsvClose(csvHandle);
               return (false);
            }
            value = StrToDouble(field);
            if (!assignedPrice1) {
               price1 = value;
               assignedPrice1 = true;
               price1field1 = fieldid;
            }
            else if (!assignedPrice2) {
               price2 = value;
               assignedPrice2 = true;
               price2field1 = fieldid;
            }
            else if (!assignedVolume1) {
               volume1 = value;
               assignedVolume1 = true;
               volume1field = fieldid;
            }
            else if (!assignedVolume2) {
               volume2 = value;
               assignedVolume2 = true;
               volume2field = fieldid;
            }
         }
         else {
            // no dot, no comma, must mean that the separator is a comma and the user has a locale with comma as decimal separator
            // or we're dealing with an integer such as the volume
            if (splitRecord) {
               // this one belongs to the previous field
               splitRecord = false;
               value = MakeFractional(field);
               if (!assignedPrice1) {
                  price1 += value;
                  assignedPrice1 = true;
                  price1field2 = fieldid;
               }
               else if (!assignedPrice2) {
                  price2 += value;
                  assignedPrice2 = true;
                  price2field2 = fieldid;
               }
            }
            else {
               value = StrToInteger(field);
               if (!assignedPrice1) {
                  price1 = value;
                  price1field1 = fieldid;
                  splitRecord = true;
               }
               else if (!assignedPrice2) {
                  price2 = value;
                  price2field1 = fieldid;
                  splitRecord = true;
               }
               else if (!assignedVolume1) {
                  volume1 = value;
                  volume1field = fieldid;
                  assignedVolume1 = true;
               }
               else if (!assignedVolume2) {
                  volume2 = value;
                  volume2field = fieldid;
                  assignedVolume2 = true;
               }
            }
         }
      }
      else if (LooksLikeDate(field)) {
         ExtDateField = fieldid;
         firstDate = field;
         Print ("The date column appears to be " + fieldid + ". Sample: " + field);
      }
      fieldid++;
   }
   // sort out the prices
   double askPrice, bidPrice;
   while (price1 == price2) {
      for (i = 0; i < ExtFieldCount; i++) {
         if (ExtFieldTypes[i] == FIELD_TYPE_STRING) {
            field = CsvReadString(csvHandle);
            if (price1field1 == i) {
               price1 = SpecialStrToDouble(field);
            }
            else if (price2field1 == i) {
               price2 = SpecialStrToDouble(field);
            }
         }
         else {
            value = CsvReadDouble(csvHandle);
	         if (price1field1 == i) {
	            price1 = value;
	         }
	         else if (price2field1 == i) {
	            price2 = value;
	         }
	         else if (price1field2 == i) {
	            price1 += MakeFractional(DoubleToStr(value, 0));
	         }
	         else if (price2field2 == i) {
	            price2 += MakeFractional(DoubleToStr(value, 0));
	         }
	      }
	   }
   }
   if (price1 > price2) {
      // the first price is the ask price
      askFirst = true;
      askPrice = price1;
      bidPrice = price2;
      ExtAskField1 = price1field1;
      ExtAskField2 = price1field2;
      ExtAskField1SpecialCase = price1specialCase;
      ExtBidField1 = price2field1;
      ExtBidField2 = price2field2;
      ExtBidField1SpecialCase = price2specialCase;
   }
   else {
      // the bid price comes first
      askFirst = false;
      bidPrice = price1;
      askPrice = price2;
      ExtBidField1 = price1field1;
      ExtBidField2 = price1field2;
      ExtBidField1SpecialCase = price1specialCase;
      ExtAskField1 = price2field1;
      ExtAskField2 = price2field2;
      ExtAskField1SpecialCase = price2specialCase;
   }
   if (ExtAskField2 >= 0) {
      Print("Ask price columns: " + ExtAskField1 + ", " + ExtAskField2 + ". Sample: " + DoubleToStr(askPrice, Digits));
   }
   else {
      Print("Ask price column: " + ExtAskField1 + ". Sample: " + DoubleToStr(askPrice, Digits));
   }
   if (ExtBidField2 >= 0) {
      Print("Bid price columns: " + ExtBidField1 + ", " + ExtBidField2 + ". Sample: " + DoubleToStr(bidPrice, Digits));
   }
   else {
      Print("Bid price column: " + ExtBidField1 + ". Sample: " + DoubleToStr(bidPrice, Digits));
   }
   if (ExtAskField1 < 0 || ExtBidField1 < 0) {
      MessageBox("Unable to identify the ask & bid columns.", "CSV2FXT", MB_ICONSTOP);
      CsvClose(csvHandle);
      return (false);
   }
   if (volume2field >= 0) {
      // we have 2 volume fields
      Print ("We have two volume columns. Arranging them in the same order as the ask/bid prices.");
      double askVolume, bidVolume;
      if (askFirst) {
         askVolume = volume1;
         bidVolume = volume2;
         ExtVolumeAskField = volume1field;
         ExtVolumeAskFieldSpecialCase = volume1specialCase;
         ExtVolumeBidField = volume2field;
         ExtVolumeBidFieldSpecialCase = volume2specialCase;
      }
      else {
         bidVolume = volume1;
         askVolume = volume2;
         ExtVolumeBidField = volume1field;
         ExtVolumeBidFieldSpecialCase = volume1specialCase;
         ExtVolumeAskField = volume2field;
         ExtVolumeAskFieldSpecialCase = volume2specialCase;
      }
      Print ("Ask volume column: " + ExtVolumeAskField + ". Sample: " + askVolume);
      Print ("Bid volume column: " + ExtVolumeBidField + ". Sample: " + bidVolume);
   }
   else if (volume2field >= 0) {
      ExtVolumeAskField = volume1field;
      ExtVolumeAskFieldSpecialCase = volume1specialCase;
      Print ("Volume column: " + ExtVolumeAskField + ". Sample: " + volume1);
   }
   if (volume1 > 100000) {
      ExtVolumeDivide = 100000;
   }
   else {
      ExtVolumeDivide = 1;
   }
   // figure out the date format
   SkipToNextLine(csvHandle);
   int validFormatsCount = 2;
   int lastValidFormat = -1;
   bool validDateFormats[KNOWN_DATE_FORMATS];
   int day[KNOWN_DATE_FORMATS];
   int month[KNOWN_DATE_FORMATS];
   int year[KNOWN_DATE_FORMATS];
   for (i = 0; i < KNOWN_DATE_FORMATS; i++) { // check all date formats
      validDateFormats[i] = true;
      day[i] = 0;
      month[i] = 0;
      year[i] = 0;
   }
   while (validFormatsCount > 1) {
      validFormatsCount = 0;
      datetime d;
      fieldid = 0;
      while (fieldid <= ExtDateField) {
         field = CsvReadString(csvHandle);
         fieldid++;
      }
      if (StringLen(field) == 0) break; // empty last line for short files
      for(i = 0; i < KNOWN_DATE_FORMATS; i++) {
         if (validDateFormats[i]) {
            if (ParseDate(field, i, d, true)) {
               int curday = TimeDay(d);
               int curmonth = TimeMonth(d);
               int curyear = TimeYear(d);
               if (month[i] != curmonth && day[i] == curday) {
                  // can't change the month without changing the day
                  validDateFormats[i] = false;
               }
               else if (year[i] != curyear && (month[i] == curmonth || day[i] == curday)) {
                  // can't change the year without changing the month and day
                  validDateFormats[i] = false;
               }
               day[i] = curday;
               month[i] = curmonth;
               year[i] = curyear;
               if (validDateFormats[i]) {
                  validFormatsCount++;
                  lastValidFormat = i;
               }
            }
            else {
               validDateFormats[i] = false;
            }
         }
      }
      if (validFormatsCount == 0) {
         CsvClose(csvHandle);
         MessageBox("Unable to understand date format.", "CSV2FXT", MB_ICONSTOP);
         return (false);
      }
      if (!SkipToNextLine(csvHandle)) {
         break; // break if the file is ending
      }
   }
   if (validFormatsCount > 1) {
      CsvClose(csvHandle);
      MessageBox("Unable to clearly identify the date format. Please use a larger CSV file.", "CSV2FXT", MB_ICONSTOP);
      return (false);
   }
   ExtDateFormat = lastValidFormat;
   ParseDate(firstDate, ExtDateFormat, ExtFirstDate);
   Print("Date format identified: " + DateFormatToStr(ExtDateFormat) + ". Elucidating value: " + field);
   CsvClose(csvHandle);
   // try to figure out the data source
   if (IsNumeric(CSVGMTOffset)) {
      ExtSrcGMT = StrToInteger(CSVGMTOffset);
   }
   if (IsNumeric(CSVDST)) {
      ExtSrcDST = StrToInteger(CSVDST);
   }
   if (ExtDateFormat == 8 && ExtDateField == 0 && ExtAskField1 == 1 && ExtBidField1 == 2 && ExtVolumeAskField == 3 && ExtVolumeBidField == 4 && ExtVolumeDivide == 1) {
      // Dukascopy via JForex
      Print("Your tick data source seems to be Dukascopy, downloaded via JForex.");
      if (!IsNumeric(CSVGMTOffset, true)) {
         ExtSrcGMT = 0;
      }
      if (!IsNumeric(CSVDST, true)) {
         ExtSrcDST = 0;
      }
   }
   else if (ExtDateField == 0 && ExtAskField1 == 1 && ExtBidField1 == 2 && ExtVolumeAskField == 3 && ExtVolumeBidField == 4 && ExtVolumeDivide == 1 &&
            (ExtDateFormat == 9 || ExtDateFormat == 10)
            ) {
      // Dukascopy via website
      Print("Your tick data source seems to be Dukascopy, downloaded via the dukascopy.com website.");
      if (!IsNumeric(CSVGMTOffset, true)) {
         ExtSrcGMT = 0;
      }
      if (!IsNumeric(CSVDST, true)) {
         ExtSrcDST = 0;
      }
   }
   else if (ExtDateFormat == 8 && ExtDateField == 0 && ExtBidField1 == 1 && ExtAskField1 == 2 && ExtVolumeBidField == 3 && ExtVolumeAskField == 4 && ExtVolumeDivide == 100000) {
      // Dukascopy via PHP scripts or Dukascopier
      Print("Your tick data source seems to be Dukascopy, downloaded via PHP scripts or Dukascopier.");
      if (!IsNumeric(CSVGMTOffset, true)) {
         ExtSrcGMT = 0;
      }
      if (!IsNumeric(CSVDST, true)) {
         ExtSrcDST = 0;
      }
   }
   else if (ExtDateFormat == 13 && ExtDateField == 0 && ExtVolumeAskField == -1) {
      // Oanda
      Print("Your tick data source seems to be Oanda.");
      if (!IsNumeric(CSVGMTOffset, true)) {
         ExtSrcGMT = 0;
      }
      if (!IsNumeric(CSVDST, true)) {
         ExtSrcDST = 0;
      }
   }
   else if (ExtDateFormat == 0 && ExtDateField == 1 && ExtVolumeAskField == -1) {
      // Integral/Pepperstone
      Print("Your tick data source seems to be Integral (TrueFX) or Pepperstone.");
      if (!IsNumeric(CSVGMTOffset, true)) {
         ExtSrcGMT = 0;
      }
      if (!IsNumeric(CSVDST, true)) {
         ExtSrcDST = 0;
      }
   }
   else if (ExtDateFormat == 8 && ExtDateField == 1 && ExtVolumeAskField == -1) {
      // MB Trading
      Print("Your tick data source seems to be MB Trading.");
      if (!IsNumeric(CSVGMTOffset, true)) {
         ExtSrcGMT = -5;
      }
      if (!IsNumeric(CSVDST, true)) {
         ExtSrcDST = 1;
      }
   }
   else if (ExtDateFormat == 16 && ExtDateField == 0 && ExtBidField1 == 1 && ExtAskField1 == 2) {
      // histdata.com
      Print("Your tick data source seems to be histdata.com.");
      if (!IsNumeric(CSVGMTOffset, true)) {
         ExtSrcGMT = -5;
      }
      if (!IsNumeric(CSVDST, true)) {
         ExtSrcDST = 1;
      }
      if (!IsNumeric(CSVGMTOffset, true) || !IsNumeric(CSVDST, true)) {
         Alert("For histdata.com tick data you should configure the source GMT & DST parameters manually.");
      }
   }
   if (!IsNumeric(CSVGMTOffset, 1) || !IsNumeric(CSVDST, 1)) {
      string cmt = "Autoconfigured";
      string sep = "";
      if (!IsNumeric(CSVGMTOffset, 1)) {
         cmt = cmt + " source GMT to " + ExtSrcGMT;
         sep = " and";
      }
      if (!IsNumeric(CSVDST, 1)) {
         cmt = cmt + sep + " source DST to " + ExtSrcDST;
      }
      cmt = cmt + ".";
      Print(cmt);
   }
   
   // figure out the last date in the file
   if (IsDllsAllowed()) {
      int fd = CreateFileA(TerminalPath() + "\\experts\\files\\" + CsvFile, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
      if (fd >= 0) {
         int bytesread[1];
         bytesread[0] = 0;
         int size = GetFileSize(fd, bytesread);
         if (size >= 0 && size < 256) {
            bytesread[0]--;
            size = -1 - (256 - size);
         } else size -= 256;
         int seek = SetFilePointer(fd, size, bytesread, FILE_START);
         bytesread[0] = 0;
         if (seek == -1) {
            Print("Failed to seek to the end of the file. The progress indicator will not be available.");
         }
         else {
            int arrayBuffer[64];
            if (ReadFile(fd, arrayBuffer, 256, bytesread, 0) != 1) {
               Print("Failed to read the end of the file. The progress indicator will not be available.");
            }
            else {
               string randname = "tmp-" + GetTickCount() + "-" + MathRand() + ".csv";
               int csvEnd = FileOpen(randname, FILE_BIN|FILE_WRITE);
               FileWriteArray(csvEnd, arrayBuffer, 0, bytesread[0] / 4);
               FileClose(csvEnd);
               csvEnd = CsvOpen(TerminalPath() + "\\experts\\files\\" + randname, ExtCsvDelimiter);
               if (csvEnd >= 0) {
                  while (SkipToNextLine(csvEnd)) {
                     fieldid = 0;
                     while (fieldid <= ExtDateField) {
                        string fieldcontent = CsvReadString(csvEnd);
                        if (StringLen(fieldcontent) > 0) {
                           field = fieldcontent;
                        }
                        fieldid++;
                     }
                  }
                  if (ParseDate(field, ExtDateFormat, ExtLastDate)) {
                     Print("Last date in file: " + TimeToStr(ExtLastDate, TIME_DATE|TIME_MINUTES|TIME_SECONDS) + " (file: " + field + ")");
                  }
                  if (end_date != 0 && end_date < ExtLastDate) {
                     ExtLastDate = end_date;
                  }
                  CsvClose(csvEnd);
               }
               FileDelete(randname);
               if (ExtLastDate <= 0) {
                  Print("Something went wrong, was unable to determine the last date in the file.");
               }
            }
         }
         CloseHandle(fd);
      }
   }
   return (true);
}

bool IsCorrectDelimiter(string CsvFile, int delimiter) {
   int csvHandle = FileOpen(CsvFile,FILE_CSV|FILE_READ,delimiter);
   string discarded = FileReadString(csvHandle, 1024);
   bool result = true;
   if (FileIsLineEnding(csvHandle)) {
      result = false;
   }
   FileClose(csvHandle);
   return (result);
}

bool HasLetters(string field) {
   bool result = false;
   for (int i = 0; i < StringLen(field); i++) {
      int char = StringGetChar(field, i);
      if ((char >= 65 && char <= 90) || // A to Z
          (char >= 97 && char <= 122)) {// a to z
          result = true;
          break;
      }
   }
   return (result);
}

bool HasDot(string field) {
   return (StringFind(field, ".") >= 0);
}

bool HasComma(string field) {
   return (StringFind(field, ",") >= 0);
}

bool IsNumeric(string field, bool negative = false) {
   bool result = true;
   field = StringTrimRight(StringTrimLeft(field));
   for (int i = 0; i < StringLen(field); i++) {
      int char = StringGetChar(field, i);
      if ((char >= 48 && char <= 57) || // 0 to 9
          char == 46 || char == 44 || // dot or comma
          (negative && char == 45)) { // -
         // all good
      }
      else {
         result = false;
         break;
      }
   }
   return (result);
}

bool LooksLikeDate(string field) {
   bool result = true;
   field = StringTrimRight(StringTrimLeft(field));
   for (int i = 0; i < StringLen(field); i++) {
      int char = StringGetChar(field, i);
      if ((char >= 48 && char <= 57) || // 0 to 9
          char == 45 || char == 47 || char == 46 || char == 32 || char == 58) { // - / . [space] :
         // all good
      }
      else {
          result = false;
          break;
      }
   }
   return (result);
}

bool SkipToNextLine(int csvHandle) {
   bool result = true;
   while (!(CsvIsLineEnding(csvHandle) == 1) && !(CsvIsEnding(csvHandle) == 1)) {
      CsvReadString(csvHandle);
   }
   if (CsvIsEnding(csvHandle) == 1) {
      result = false;
   }
   return (result);
}

double SpecialStrToDouble(string field) {
   field = StringSubstr(field, 0, StringFind(field, ",")) + "." + StringSubstr(field, StringFind(field, ",") + 1);
   return (StrToDouble(field));
}

double MakeFractional(string field) {
   double value = StrToInteger(field);
   field = StringTrimLeft(StringTrimRight(field));
   for (int i = 0; i < StringLen(field); i++) {
      value /= 10;
   }
   return (value);
}

bool IsDateSeparator(int char) {
   bool result = false;
   if (char == 45 || char == 47 || char == 46 || char == 32) { // - / . [space]
      result = true;
   }
   return (result);
}

bool ParseDate(string field, int i, datetime &d, bool check = false) {
   bool result = false;
   switch (i) {
      case 0:
         result = ParseDate0(field, d, check);
         break;
      case 1:
         result = ParseDate1(field, d, check);
         break;
      case 2:
         result = ParseDate2(field, d, check);
         break;
      case 3:
         result = ParseDate3(field, d, check);
         break;
      case 4:
         result = ParseDate4(field, d, check);
         break;
      case 5:
         result = ParseDate5(field, d, check);
         break;
      case 6:
         result = ParseDate6(field, d, check);
         break;
      case 7:
         result = ParseDate7(field, d, check);
         break;
      case 8:
         result = ParseDate8(field, d, check);
         break;
      case 9:
         result = ParseDate9(field, d, check);
         break;
      case 10:
         result = ParseDate10(field, d, check);
         break;
      case 11:
         result = ParseDate11(field, d, check);
         break;
      case 12:
         result = ParseDate12(field, d, check);
         break;
      case 13:
         result = ParseDate13(field, d, check);
         break;
      case 14:
         result = ParseDate14(field, d, check);
         break;
      case 15:
         result = ParseDate15(field, d, check);
         break;
      case 16:
         result = ParseDate16(field, d, check);
         break;
      case 17:
         result = ParseDate17(field, d, check);
         break;
      case 18:
         result = ParseDate18(field, d, check);
         break;
      case 19:
         result = ParseDate19(field, d, check);
         break;
   }
   return (result);
}

bool CheckDateCommon(string year, string month, string day, string hour, string minute, string second) {
   if (StringLen(year) == 4) {
      if (!IsNumeric(year) || StrToInteger(year) < 1970 || StrToInteger(year) > 2038) {
         return (false);
      }
   }
   else if (StringLen(year) == 2) {
      if (!IsNumeric(year) || (StrToInteger(year) > 38 && StrToInteger(year) < 70)) {
         return (false);
      }   
   }
   else {
      return (false);
   }
   if (!IsNumeric(month) || StrToInteger(month) < 1 || StrToInteger(month) > 12) {
      return (false);
   }
   if (!IsNumeric(day) || StrToInteger(day) < 1 || StrToInteger(day) > 31) {
      return (false);
   }
   if (!IsNumeric(hour) || StrToInteger(hour) < 0 || StrToInteger(hour) > 23) {
      return (false);
   }
   if (!IsNumeric(minute) || StrToInteger(minute) < 0 || StrToInteger(minute) > 60) {
      return (false);
   }
   if (!IsNumeric(second) || StrToInteger(second) < 0 || StrToInteger(second) > 60) {
      return (false);
   }
   return (true);
}

bool ParseDate0(string field, datetime &d, bool check) {
   // 20091231 12:34:56
   // 01234567890123456
   if (StringLen(field) < 17) return (false);
   string year = StringSubstr(field, 0, 4);
   string month = StringSubstr(field, 4, 2);
   string day = StringSubstr(field, 6, 2);
   string time = StringSubstr(field, 9, 8);
   if (check) {
      string hour = StringSubstr(field, 9, 2);
      string minute = StringSubstr(field, 12, 2);
      string second = StringSubstr(field, 15, 2);
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
   }
   string parsabledate = year + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate1(string field, datetime &d, bool check) {
   // 20093112 12:34:56
   // 01234567890123456
   if (StringLen(field) < 17) return (false);
   string year = StringSubstr(field, 0, 4);
   string day = StringSubstr(field, 4, 2);
   string month = StringSubstr(field, 6, 2);
   string time = StringSubstr(field, 9, 8);
   if (check) {
      string hour = StringSubstr(field, 9, 2);
      string minute = StringSubstr(field, 12, 2);
      string second = StringSubstr(field, 15, 2);
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
   }
   string parsabledate = year + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate2(string field, datetime &d, bool check) {
   // 31122009 12:34:56
   // 01234567890123456
   if (StringLen(field) < 17) return (false);
   string day = StringSubstr(field, 0, 2);
   string month = StringSubstr(field, 2, 2);
   string year = StringSubstr(field, 4, 4);
   string time = StringSubstr(field, 9, 8);
   if (check) {
      string hour = StringSubstr(field, 9, 2);
      string minute = StringSubstr(field, 12, 2);
      string second = StringSubstr(field, 15, 2);
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
   }
   string parsabledate = year + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate3(string field, datetime &d, bool check) {
   // 12312009 12:34:56
   // 01234567890123456
   if (StringLen(field) < 17) return (false);
   string month = StringSubstr(field, 0, 2);
   string day = StringSubstr(field, 2, 2);
   string year = StringSubstr(field, 4, 4);
   string time = StringSubstr(field, 9, 8);
   if (check) {
      string hour = StringSubstr(field, 9, 2);
      string minute = StringSubstr(field, 12, 2);
      string second = StringSubstr(field, 15, 2);
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
   }
   string parsabledate = year + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate4(string field, datetime &d, bool check) {
   // 123109 12:34:56
   // 012345678901234
   if (StringLen(field) < 15) return (false);
   string month = StringSubstr(field, 0, 2);
   string day = StringSubstr(field, 2, 2);
   string year = StringSubstr(field, 4, 2);
   string time = StringSubstr(field, 9, 8);
   int yearval = StrToInteger(year);
   if (yearval > 70) {
      yearval += 1900;
   }
   else {
      yearval += 2000;
   }
   if (check) {
      string hour = StringSubstr(field, 7, 2);
      string minute = StringSubstr(field, 10, 2);
      string second = StringSubstr(field, 13, 2);
      if (StringGetChar(field, 6) != 32) { // space in the middle
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
   }
   string parsabledate = yearval + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate5(string field, datetime &d, bool check) {
   // 311209 12:34:56
   // 012345678901234
   if (StringLen(field) < 15) return (false);
   string day = StringSubstr(field, 0, 2);
   string month = StringSubstr(field, 2, 2);
   string year = StringSubstr(field, 4, 2);
   string time = StringSubstr(field, 9, 8);
   int yearval = StrToInteger(year);
   if (yearval > 70) {
      yearval += 1900;
   }
   else {
      yearval += 2000;
   }
   if (check) {
      string hour = StringSubstr(field, 7, 2);
      string minute = StringSubstr(field, 10, 2);
      string second = StringSubstr(field, 13, 2);
      if (StringGetChar(field, 6) != 32) { // space in the middle
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
   }
   string parsabledate = yearval + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate6(string field, datetime &d, bool check) {
   // 093112 12:34:56
   // 012345678901234
   if (StringLen(field) < 15) return (false);
   string year = StringSubstr(field, 0, 2);
   string day = StringSubstr(field, 2, 2);
   string month = StringSubstr(field, 4, 2);
   string time = StringSubstr(field, 9, 8);
   int yearval = StrToInteger(year);
   if (yearval > 70) {
      yearval += 1900;
   }
   else {
      yearval += 2000;
   }
   if (check) {
      string hour = StringSubstr(field, 7, 2);
      string minute = StringSubstr(field, 10, 2);
      string second = StringSubstr(field, 13, 2);
      if (StringGetChar(field, 6) != 32) { // space in the middle
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
   }
   string parsabledate = yearval + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate7(string field, datetime &d, bool check) {
   // 091231 12:34:56
   // 012345678901234
   if (StringLen(field) < 15) return (false);
   string year = StringSubstr(field, 0, 2);
   string month = StringSubstr(field, 2, 2);
   string day = StringSubstr(field, 4, 2);
   string time = StringSubstr(field, 9, 8);
   int yearval = StrToInteger(year);
   if (yearval > 70) {
      yearval += 1900;
   }
   else {
      yearval += 2000;
   }
   if (check) {
      string hour = StringSubstr(field, 7, 2);
      string minute = StringSubstr(field, 10, 2);
      string second = StringSubstr(field, 13, 2);
      if (StringGetChar(field, 6) != 32) { // space in the middle
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
   }
   string parsabledate = yearval + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate8(string field, datetime &d, bool check) {
   // 2009?12?31 12:34:56
   // 0123456789012345678
   if (StringLen(field) < 19) return (false);
   string year = StringSubstr(field, 0, 4);
   string month = StringSubstr(field, 5, 2);
   string day = StringSubstr(field, 8, 2);
   string time = StringSubstr(field, 11, 8);
   if (check) {
      string hour = StringSubstr(field, 11, 2);
      string minute = StringSubstr(field, 14, 2);
      string second = StringSubstr(field, 17, 2);
      if (StringGetChar(field, 10) != 32) { // space in the middle
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 4))) { // separator 1
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 7))) { // separator 2
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = StringGetChar(field, 4);
   }
   string parsabledate = year + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate9(string field, datetime &d, bool check) {
   // 2009?31?12 12:34:56
   // 0123456789012345678
   if (StringLen(field) < 19) return (false);
   string year = StringSubstr(field, 0, 4);
   string day = StringSubstr(field, 5, 2);
   string month = StringSubstr(field, 8, 2);
   string time = StringSubstr(field, 11, 8);
   if (check) {
      string hour = StringSubstr(field, 11, 2);
      string minute = StringSubstr(field, 14, 2);
      string second = StringSubstr(field, 17, 2);
      if (StringGetChar(field, 10) != 32) { // space in the middle
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 4))) { // separator 1
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 7))) { // separator 2
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = StringGetChar(field, 4);
   }
   string parsabledate = year + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate10(string field, datetime &d, bool check) {
   // 31?12?2009 12:34:56
   // 0123456789012345678
   if (StringLen(field) < 19) return (false);
   string day = StringSubstr(field, 0, 2);
   string month = StringSubstr(field, 3, 2);
   string year = StringSubstr(field, 6, 4);
   string time = StringSubstr(field, 11, 8);
   if (check) {
      string hour = StringSubstr(field, 11, 2);
      string minute = StringSubstr(field, 14, 2);
      string second = StringSubstr(field, 17, 2);
      if (StringGetChar(field, 10) != 32) { // space in the middle
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 2))) { // separator 1
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 5))) { // separator 2
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = StringGetChar(field, 2);
   }
   string parsabledate = year + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate11(string field, datetime &d, bool check) {
   // 12?31?2009 12:34:56
   // 0123456789012345678
   if (StringLen(field) < 19) return (false);
   string month = StringSubstr(field, 0, 2);
   string day = StringSubstr(field, 3, 2);
   string year = StringSubstr(field, 6, 4);
   string time = StringSubstr(field, 11, 8);
   if (check) {
      string hour = StringSubstr(field, 11, 2);
      string minute = StringSubstr(field, 14, 2);
      string second = StringSubstr(field, 17, 2);
      if (StringGetChar(field, 10) != 32) { // space in the middle
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 2))) { // separator 1
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 5))) { // separator 2
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = StringGetChar(field, 2);
   }
   string parsabledate = year + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate12(string field, datetime &d, bool check) {
   // 12?31?09 12:34:56
   // 01234567890123456
   if (StringLen(field) < 17) return (false);
   string month = StringSubstr(field, 0, 2);
   string day = StringSubstr(field, 3, 2);
   string year = StringSubstr(field, 6, 2);
   string time = StringSubstr(field, 9, 8);
   int yearval = StrToInteger(year);
   if (yearval > 70) {
      yearval += 1900;
   }
   else {
      yearval += 2000;
   }
   if (check) {
      string hour = StringSubstr(field, 9, 2);
      string minute = StringSubstr(field, 12, 2);
      string second = StringSubstr(field, 15, 2);
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 2))) { // separator 1
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 5))) { // separator 2
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = StringGetChar(field, 2);
   }
   string parsabledate = yearval + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate13(string field, datetime &d, bool check) {
   // 31?12?09 12:34:56
   // 01234567890123456
   if (StringLen(field) < 17) return (false);
   string day = StringSubstr(field, 0, 2);
   string month = StringSubstr(field, 3, 2);
   string year = StringSubstr(field, 6, 2);
   string time = StringSubstr(field, 9, 8);
   int yearval = StrToInteger(year);
   if (yearval > 70) {
      yearval += 1900;
   }
   else {
      yearval += 2000;
   }
   if (check) {
      string hour = StringSubstr(field, 9, 2);
      string minute = StringSubstr(field, 12, 2);
      string second = StringSubstr(field, 15, 2);
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 2))) { // separator 1
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 5))) { // separator 2
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = StringGetChar(field, 2);
   }
   string parsabledate = yearval + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate14(string field, datetime &d, bool check) {
   // 09?12?31 12:34:56
   // 01234567890123456
   if (StringLen(field) < 17) return (false);
   string year = StringSubstr(field, 0, 2);
   string month = StringSubstr(field, 3, 2);
   string day = StringSubstr(field, 6, 2);
   string time = StringSubstr(field, 9, 8);
   int yearval = StrToInteger(year);
   if (yearval > 70) {
      yearval += 1900;
   }
   else {
      yearval += 2000;
   }
   if (check) {
      string hour = StringSubstr(field, 9, 2);
      string minute = StringSubstr(field, 12, 2);
      string second = StringSubstr(field, 15, 2);
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 2))) { // separator 1
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 5))) { // separator 2
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = StringGetChar(field, 2);
   }
   string parsabledate = yearval + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate15(string field, datetime &d, bool check) {
   // 09?31?12 12:34:56
   // 01234567890123456
   if (StringLen(field) < 17) return (false);
   string year = StringSubstr(field, 0, 2);
   string day = StringSubstr(field, 3, 2);
   string month = StringSubstr(field, 6, 2);
   string time = StringSubstr(field, 9, 8);
   int yearval = StrToInteger(year);
   if (yearval > 70) {
      yearval += 1900;
   }
   else {
      yearval += 2000;
   }
   if (check) {
      string hour = StringSubstr(field, 9, 2);
      string minute = StringSubstr(field, 12, 2);
      string second = StringSubstr(field, 15, 2);
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 2))) { // separator 1
         return (false);
      }
      if (!IsDateSeparator(StringGetChar(field, 5))) { // separator 2
         return (false);
      }
      if (!IsNumeric(year) || (StrToInteger(year) > 38 && StrToInteger(year) < 70)) {
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = StringGetChar(field, 2);
   }
   string parsabledate = yearval + "." + month + "." + day + " " + time;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate16(string field, datetime &d, bool check) {
   // 20121231 123456???
   // 01234567890123456
   if (StringLen(field) < 15) return (false);
   string year = StringSubstr(field, 0, 4);
   string month = StringSubstr(field, 4, 2);
   string day = StringSubstr(field, 6, 2);
   string hour = StringSubstr(field, 9, 2);
   string minute = StringSubstr(field, 11, 2);
   string second = StringSubstr(field, 13, 2);
   int yearval = StrToInteger(year);
   if (check) {
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!IsNumeric(year) || (StrToInteger(year) > 38 && StrToInteger(year) < 70)) {
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = 0;
   }
   string parsabledate = yearval + "." + month + "." + day + " " + hour + ":" + minute + ":" + second;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate17(string field, datetime &d, bool check) {
   // 20123112 123456???
   // 01234567890123456
   if (StringLen(field) < 15) return (false);
   string year = StringSubstr(field, 0, 4);
   string day = StringSubstr(field, 4, 2);
   string month = StringSubstr(field, 6, 2);
   string hour = StringSubstr(field, 9, 2);
   string minute = StringSubstr(field, 11, 2);
   string second = StringSubstr(field, 13, 2);
   int yearval = StrToInteger(year);
   if (check) {
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!IsNumeric(year) || (StrToInteger(year) > 38 && StrToInteger(year) < 70)) {
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = 0;
   }
   string parsabledate = yearval + "." + month + "." + day + " " + hour + ":" + minute + ":" + second;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate18(string field, datetime &d, bool check) {
   // 31122012 123456???
   // 01234567890123456
   if (StringLen(field) < 15) return (false);
   string day = StringSubstr(field, 0, 2);
   string month = StringSubstr(field, 2, 2);
   string year = StringSubstr(field, 4, 4);
   string hour = StringSubstr(field, 9, 2);
   string minute = StringSubstr(field, 11, 2);
   string second = StringSubstr(field, 13, 2);
   int yearval = StrToInteger(year);
   if (check) {
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!IsNumeric(year) || (StrToInteger(year) > 38 && StrToInteger(year) < 70)) {
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = 0;
   }
   string parsabledate = yearval + "." + month + "." + day + " " + hour + ":" + minute + ":" + second;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

bool ParseDate19(string field, datetime &d, bool check) {
   // 12312012 123456???
   // 01234567890123456
   if (StringLen(field) < 15) return (false);
   string month = StringSubstr(field, 0, 2);
   string day = StringSubstr(field, 2, 2);
   string year = StringSubstr(field, 4, 4);
   string hour = StringSubstr(field, 9, 2);
   string minute = StringSubstr(field, 11, 2);
   string second = StringSubstr(field, 13, 2);
   int yearval = StrToInteger(year);
   if (check) {
      if (StringGetChar(field, 8) != 32) { // space in the middle
         return (false);
      }
      if (!IsNumeric(year) || (StrToInteger(year) > 38 && StrToInteger(year) < 70)) {
         return (false);
      }
      if (!CheckDateCommon(year, month, day, hour, minute, second)) {
         return (false);
      }
      ExtDateSeparator = 0;
   }
   string parsabledate = yearval + "." + month + "." + day + " " + hour + ":" + minute + ":" + second;
   d = StrToTime(parsabledate);
   return (d >= 0);
}

string DateFormatToStr(int i) {
   string result = "unknown";
   string separator = "";
   if (ExtDateSeparator > 0) {
      separator = StringSetChar(separator, 0, ExtDateSeparator);
   }
   switch (i) {
      case 0:
         result = "YYYYMMDD hh:mm:ss";
         break;
      case 1:
         result = "YYYYDDMM hh:mm:ss";
         break;
      case 2:
         result = "DDMMYYYY hh:mm:ss";
         break;
      case 3:
         result = "MMDDYYYY hh:mm:ss";
         break;
      case 4:
         result = "MMDDYY hh:mm:ss";
         break;
      case 5:
         result = "DDMMYY hh:mm:ss";
         break;
      case 6:
         result = "YYDDMM hh:mm:ss";
         break;
      case 7:
         result = "YYMMDD hh:mm:ss";
         break;
      case 8:
         result = "YYYY" + separator + "MM" + separator + "DD hh:mm:ss";
         break;
      case 9:
         result = "YYYY" + separator + "DD" + separator + "MM hh:mm:ss";
         break;
      case 10:
         result = "DD" + separator + "?MM" + separator + "YYYY hh:mm:ss";
         break;
      case 11:
         result = "MM" + separator + "DD" + separator + "YYYY hh:mm:ss";
         break;
      case 12:
         result = "MM" + separator + "DD" + separator + "YY hh:mm:ss";
         break;
      case 13:
         result = "DD" + separator + "MM" + separator + "YY hh:mm:ss";
         break;
      case 14:
         result = "YY" + separator + "MM" + separator + "DD hh:mm:ss";
         break;
      case 15:
         result = "YY" + separator + "DD" + separator + "MM hh:mm:ss";
         break;
      case 16:
         result = "YYYYMMDD hhmmss";
         break;
      case 17:
         result = "YYYYDDMM hhmmss";
         break;
      case 18:
         result = "DDMMYYYY hhmmss";
         break;
      case 19:
         result = "MMDDYYYY hhmmss";
         break;
   }
   return (result);
}

bool HasExtraDigit() {
// add code here if you're backtesting a symbol with strange particularities, such as a misc CFD or e.g. XAGJPY
   if (Digits % 2 == 1) {
      return (true);
   }
   return (false);
}