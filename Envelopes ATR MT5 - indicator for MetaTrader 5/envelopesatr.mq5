//+------------------------------------------------------------------+
//|                                                 EnvelopesATR.mq5 |
//|                                              Copyright 2016, Tor |
//|                                             http://einvestor.ru/ |
//+------------------------------------------------------------------+
#property copyright "2016, Tor"
#property link      "http://einvestor.ru/"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   4
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_color2  clrRed
#property indicator_color3  clrDeepSkyBlue
#property indicator_color4  clrDarkOrange
#property indicator_label1  "MA Upper band"
#property indicator_label2  "MA Lower band"
#property indicator_label3  "ATR Upper band"
#property indicator_label4  "Atr Lower band"
//--- input parameters
input int                InpATRperiod=14;              // ATR Period

input int                InpMAPeriod=14;              // MA Period
input int                InpMAShift=0;                // Shift
input ENUM_MA_METHOD     InpMAMethod=MODE_SMA;        // MA Method
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // MA Applied price
input double             InpDeviation=0.1;            // Deviation %
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum TypeEnv
  {
   DEV=0,     // Deviation %
   DAT=1,     // Deviation by ATR
   DDA=2,     // Deviation % + Deviation by ATR
  };
//--- input parameters
input TypeEnv EnvelopesType=DDA; // Envelopes Type
//--- indicator buffers
double                   ExtUpBuffer[];
double                   ExtDownBuffer[];
double                   ExtUp2Buffer[];
double                   ExtDown2Buffer[];
double                   ExtMABuffer[];
double                   ExtATRBuffer[];
//--- MA handle
int                      ExtMAHandle;
int                      ExtATRHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   if(EnvelopesType==0)
     {
      SetIndexBuffer(0,ExtUpBuffer,INDICATOR_DATA);
      SetIndexBuffer(1,ExtDownBuffer,INDICATOR_DATA);
      SetIndexBuffer(2,ExtUp2Buffer,INDICATOR_CALCULATIONS);
      SetIndexBuffer(3,ExtDown2Buffer,INDICATOR_CALCULATIONS);
     }
   if(EnvelopesType==1)
     {
      SetIndexBuffer(0,ExtUpBuffer,INDICATOR_CALCULATIONS);
      SetIndexBuffer(1,ExtDownBuffer,INDICATOR_CALCULATIONS);
      SetIndexBuffer(2,ExtUp2Buffer,INDICATOR_DATA);
      SetIndexBuffer(3,ExtDown2Buffer,INDICATOR_DATA);
     }
   if(EnvelopesType==2)
     {
      SetIndexBuffer(0,ExtUpBuffer,INDICATOR_DATA);
      SetIndexBuffer(1,ExtDownBuffer,INDICATOR_DATA);
      SetIndexBuffer(2,ExtUp2Buffer,INDICATOR_DATA);
      SetIndexBuffer(3,ExtDown2Buffer,INDICATOR_DATA);
     }
   SetIndexBuffer(4,ExtMABuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,ExtATRBuffer,INDICATOR_CALCULATIONS);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpMAPeriod-1);
//--- name for DataWindow
   IndicatorSetString(INDICATOR_SHORTNAME,"Env("+string(InpMAPeriod)+")");
   PlotIndexSetString(0,PLOT_LABEL,"Env("+string(InpMAPeriod)+")Upper");
   PlotIndexSetString(1,PLOT_LABEL,"Env("+string(InpMAPeriod)+")Lower");
   PlotIndexSetString(2,PLOT_LABEL,"EnvATR("+string(InpMAPeriod)+")Upper");
   PlotIndexSetString(3,PLOT_LABEL,"EnvATR("+string(InpMAPeriod)+")Lower");
//---- line shifts when drawing
   PlotIndexSetInteger(0,PLOT_SHIFT,InpMAShift);
   PlotIndexSetInteger(1,PLOT_SHIFT,InpMAShift);
   PlotIndexSetInteger(2,PLOT_SHIFT,InpMAShift);
   PlotIndexSetInteger(3,PLOT_SHIFT,InpMAShift);
//---
   ExtMAHandle=iMA(NULL,0,InpMAPeriod,0,InpMAMethod,InpAppliedPrice);
   ExtATRHandle=iATR(NULL,0,InpATRperiod);
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Envelopes                                                        |
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
   int    i,limit;
//--- check for bars count
   if(rates_total<InpMAPeriod)
      return(0);
   int calculated=BarsCalculated(ExtMAHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtMAHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0) to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0) to_copy++;
     }
//---- get ma buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtMAHandle,0,0,to_copy,ExtMABuffer)<=0)
     {
      Print("Getting MA data is failed! Error",GetLastError());
      return(0);
     }
   if(CopyBuffer(ExtATRHandle,0,0,to_copy,ExtATRBuffer)<=0)
     {
      Print("Getting ATR data is failed! Error",GetLastError());
      return(0);
     }
//--- preliminary calculations
   limit=prev_calculated-1;
   if(limit<InpMAPeriod)
      limit=InpMAPeriod;
//--- the main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      ExtUpBuffer[i] = EMPTY_VALUE;
      ExtDownBuffer[i] = EMPTY_VALUE;
      ExtUp2Buffer[i] = EMPTY_VALUE;
      ExtDown2Buffer[i] = EMPTY_VALUE;
      if(EnvelopesType==0 || EnvelopesType==2)
        {
         ExtUpBuffer[i]=(1+InpDeviation/100.0)*ExtMABuffer[i];
         ExtDownBuffer[i]=(1-InpDeviation/100.0)*ExtMABuffer[i];
        }
      if(EnvelopesType==1 || EnvelopesType==2)
        {
         ExtUp2Buffer[i]=ExtMABuffer[i]+ExtATRBuffer[i];
         ExtDown2Buffer[i]=ExtMABuffer[i]-ExtATRBuffer[i];
        }
     }
//--- done
   return(rates_total);
  }
//+------------------------------------------------------------------+
