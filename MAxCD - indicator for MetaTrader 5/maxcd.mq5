//+------------------------------------------------------------------+
//|                                                        MAxCD.mq5 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                              https://www.mql5.com/en/users/3rjfx |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, Roberto Jacobs (3rjfx) ~ By 3rjfx ~ Created: 2019/07/18"
#property link      "https://www.mql5.com/en/users/3rjfx"
#property version   "1.00"
#property description "Three Moving Averages Convergence/Divergence."
//--
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   3
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_color1  clrBlueViolet
#property indicator_color2  clrSnow
#property indicator_color3  clrAqua
#property indicator_width1  2
#property indicator_width2  2
#property indicator_width3  2
#property indicator_label1  "MAIN"
#property indicator_label2  "MIDLE"
#property indicator_label3  "FAST"
//--
//--- indicator buffers
double MA1720[];
double MA2320[];
double MA1723[];
double ExtMAIN[];
double ExtMIDL[];
double ExtFAST[];
//--
string ind_name;
//--
#define CDM1  10
#define CDM2  23
#define CDM3  20
#define BAR   53
//--- MA handles
int   CDM1MaHandle;
int   CDM2MaHandle;
int   CDM3MaHandle;
//---------//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   //--
   SetIndexBuffer(0,ExtMAIN,INDICATOR_DATA);
   SetIndexBuffer(1,ExtMIDL,INDICATOR_DATA);
   SetIndexBuffer(2,ExtFAST,INDICATOR_DATA);
   SetIndexBuffer(3,MA1720,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,MA2320,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,MA1723,INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(0,PLOT_SHOW_DATA,true);
   PlotIndexSetInteger(1,PLOT_SHOW_DATA,true);
   PlotIndexSetInteger(2,PLOT_SHOW_DATA,true); 
//---
   ind_name="MAxCD";
   IndicatorSetString(INDICATOR_SHORTNAME,ind_name);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   //--
   CDM1MaHandle=iMA(Symbol(),0,CDM1,0,MODE_LWMA,PRICE_CLOSE);
   CDM2MaHandle=iMA(Symbol(),0,CDM2,0,MODE_LWMA,PRICE_OPEN);
   CDM3MaHandle=iMA(Symbol(),0,CDM3,0,MODE_SMMA,PRICE_MEDIAN);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
//--- check for data
   if(rates_total<BAR)
      return(0);
//--- not all data may be calculated
   int calculated=BarsCalculated(CDM1MaHandle);
   if(calculated<rates_total) return(0);
   calculated=BarsCalculated(CDM2MaHandle);
   if(calculated<rates_total) return(0);
   calculated=BarsCalculated(CDM3MaHandle);
   if(calculated<rates_total) return(0);
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }
//--- get CDM1 MA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(CDM1MaHandle,0,0,to_copy,MA1720)<=0)
     {
      Print("Getting CDM1 MA buffers is failed! Error",GetLastError());
      return(0);
     }
//--- get CDM2 MA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(CDM2MaHandle,0,0,to_copy,MA2320)<=0)
     {
      Print("Getting CDM2 MA buffers is failed! Error",GetLastError());
      return(0);
     }
//--- get CDM3 MA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(CDM3MaHandle,0,0,to_copy,MA1723)<=0)
     {
      Print("Getting CDM3 MA buffers is failed! Error",GetLastError());
      return(0);
     }
//---
   int i,limit;
   if(prev_calculated==0)
      limit=1;
   else limit=prev_calculated-1;
   //--
//---
   ArrayResize(ExtMAIN,limit);
   ArrayResize(ExtMIDL,limit);
   ArrayResize(ExtFAST,limit);
   ArrayResize(MA1720,limit);
   ArrayResize(MA2320,limit);
   ArrayResize(MA1723,limit);
   ArraySetAsSeries(ExtMAIN,true);
   ArraySetAsSeries(ExtMIDL,true);
   ArraySetAsSeries(ExtFAST,true);
   ArraySetAsSeries(MA1720,true);
   ArraySetAsSeries(MA2320,true);
   ArraySetAsSeries(MA1723,true);
//---
   for(i=limit-1; i>=0; i--)
     {
       ExtMAIN[i]=MA1720[i]-MA1723[i];
       ExtMIDL[i]=MA2320[i]-MA1723[i];
       ExtFAST[i]=MA1720[i]-MA2320[i];
     }
   //--
//--- done
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+