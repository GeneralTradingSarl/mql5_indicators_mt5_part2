//+------------------------------------------------------------------+
//|                                                KnowSureThing.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 10
#property indicator_plots   2

#include <MovingAverages.mqh>

//--- plot KST
#property indicator_label1  "KST"
#property indicator_type1   DRAW_LINE
#property indicator_color1  C'0,150,136'
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- plot Signal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  C'244,67,54'
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- input parameters
input uint     InpPeriodROC1  =  10;   // ROC Length #1
input uint     InpPeriodROC2  =  15;   // ROC Length #2
input uint     InpPeriodROC3  =  20;   // ROC Length #3
input uint     InpPeriodROC4  =  30;   // ROC Length #4
input uint     InpPeriodSMA1  =  10;   // SMA Length #1
input uint     InpPeriodSMA2  =  10;   // SMA Length #2
input uint     InpPeriodSMA3  =  10;   // SMA Length #3
input uint     InpPeriodSMA4  =  15;   // SMA Length #4
input uint     InpPeriodSig   =  9;    // Signal Line Length

//--- indicator buffers
double         ExtBufferKST[];
double         ExtBufferSignal[];
double         ExtBufferROC1[];
double         ExtBufferROC2[];
double         ExtBufferROC3[];
double         ExtBufferROC4[];
double         ExtBufferSMA1[];
double         ExtBufferSMA2[];
double         ExtBufferSMA3[];
double         ExtBufferSMA4[];

//--- global variables
int      ExtPeriodROC1;
int      ExtPeriodROC2;
int      ExtPeriodROC3;
int      ExtPeriodROC4;
int      ExtPeriodSMA1;
int      ExtPeriodSMA2;
int      ExtPeriodSMA3;
int      ExtPeriodSMA4;
int      ExtPeriodSig;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtBufferKST,INDICATOR_DATA);
   SetIndexBuffer(1,ExtBufferSignal,INDICATOR_DATA);
   SetIndexBuffer(2,ExtBufferROC1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,ExtBufferROC2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtBufferROC3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(5,ExtBufferROC4,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,ExtBufferSMA1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,ExtBufferSMA2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,ExtBufferSMA3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,ExtBufferSMA4,INDICATOR_CALCULATIONS);
   
//--- setting buffer arrays as timeseries
   ArraySetAsSeries(ExtBufferKST,true);
   ArraySetAsSeries(ExtBufferSignal,true);
   ArraySetAsSeries(ExtBufferROC1,true);
   ArraySetAsSeries(ExtBufferROC2,true);
   ArraySetAsSeries(ExtBufferROC3,true);
   ArraySetAsSeries(ExtBufferROC4,true);
   ArraySetAsSeries(ExtBufferSMA1,true);
   ArraySetAsSeries(ExtBufferSMA2,true);
   ArraySetAsSeries(ExtBufferSMA3,true);
   ArraySetAsSeries(ExtBufferSMA4,true);
   
//--- setting the period, symbol short name and levels for the indicator
   ExtPeriodROC1=int(InpPeriodROC1<1 ? 1 : InpPeriodROC1);
   ExtPeriodROC2=int(InpPeriodROC2<1 ? 1 : InpPeriodROC2);
   ExtPeriodROC3=int(InpPeriodROC3<1 ? 1 : InpPeriodROC3);
   ExtPeriodROC4=int(InpPeriodROC4<1 ? 1 : InpPeriodROC4);
   ExtPeriodSMA1=int(InpPeriodSMA1<2 ? 2 : InpPeriodSMA1);
   ExtPeriodSMA2=int(InpPeriodSMA2<2 ? 2 : InpPeriodSMA2);
   ExtPeriodSMA3=int(InpPeriodSMA3<2 ? 2 : InpPeriodSMA3);
   ExtPeriodSMA4=int(InpPeriodSMA4<2 ? 2 : InpPeriodSMA4);
   ExtPeriodSig =int(InpPeriodSig <2 ? 2 : InpPeriodSig);
   
//--- setting the short name and levels for the indicator
   string param=StringFormat("KST (%lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu, %lu)",
                             ExtPeriodROC1,ExtPeriodROC2,ExtPeriodROC3,ExtPeriodROC4,
                             ExtPeriodSMA1,ExtPeriodSMA2,ExtPeriodSMA3,ExtPeriodSMA4,ExtPeriodSig);
   IndicatorSetString(INDICATOR_SHORTNAME,param);
   IndicatorSetInteger(INDICATOR_LEVELS,1);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0, 0.0);
   
//--- success
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
//--- checking for the minimum number of bars for calculation
   int roc_max=fmax(ExtPeriodROC1,fmax(ExtPeriodROC2,fmax(ExtPeriodROC3,ExtPeriodROC4)));
   int sma_max=fmax(ExtPeriodSMA1,fmax(ExtPeriodSMA2,fmax(ExtPeriodSMA3,ExtPeriodSMA4)));
   int max=fmax(roc_max,sma_max);
   if(rates_total<roc_max)
      return 0;
      
//--- setting predefined indicator arrays as timeseries
   ArraySetAsSeries(close,true);
      
//--- checking and calculating the number of bars to be calculated
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-1-max;
      ArrayInitialize(ExtBufferKST,EMPTY_VALUE);
      ArrayInitialize(ExtBufferSignal,EMPTY_VALUE);
      ArrayInitialize(ExtBufferROC1,0);
      ArrayInitialize(ExtBufferROC2,0);
      ArrayInitialize(ExtBufferROC3,0);
      ArrayInitialize(ExtBufferROC4,0);
      ArrayInitialize(ExtBufferSMA1,0);
      ArrayInitialize(ExtBufferSMA2,0);
      ArrayInitialize(ExtBufferSMA3,0);
      ArrayInitialize(ExtBufferSMA4,0);
     }

//--- calculate RAW data
   for(int i=limit; i>=0; i--)
     {
      ExtBufferROC1[i]=GetROC(i,ExtPeriodROC1,close);
      ExtBufferROC2[i]=GetROC(i,ExtPeriodROC2,close);
      ExtBufferROC3[i]=GetROC(i,ExtPeriodROC3,close);
      ExtBufferROC4[i]=GetROC(i,ExtPeriodROC4,close);
     }
   if(SimpleMAOnBuffer(rates_total,prev_calculated,0,ExtPeriodSMA1,ExtBufferROC1,ExtBufferSMA1)==0)
      return 0;
   if(SimpleMAOnBuffer(rates_total,prev_calculated,0,ExtPeriodSMA2,ExtBufferROC2,ExtBufferSMA2)==0)
      return 0;
   if(SimpleMAOnBuffer(rates_total,prev_calculated,0,ExtPeriodSMA3,ExtBufferROC3,ExtBufferSMA3)==0)
      return 0;
   if(SimpleMAOnBuffer(rates_total,prev_calculated,0,ExtPeriodSMA4,ExtBufferROC4,ExtBufferSMA4)==0)
      return 0;
     
//--- calculation Know Sure Thing
   for(int i=limit; i>=0; i--)
      ExtBufferKST[i]=ExtBufferSMA1[i] + 2 * ExtBufferSMA2[i] + 3 * ExtBufferSMA3[i] + 4 * ExtBufferSMA4[i];
      
//--- calcilate signal line and return value of prev_calculated for next call
   return(SimpleMAOnBuffer(rates_total,prev_calculated,max,ExtPeriodSig,ExtBufferKST,ExtBufferSignal));
  }
//+------------------------------------------------------------------+
//| Returns the Price Rate of Change                                 |
//+------------------------------------------------------------------+
double GetROC(const int index,const int period,const double &price[])
  {
   return(price[index]!=0 ? (price[index]-price[index+period]) / price[index] * 100.0 : 0);
  }
//+------------------------------------------------------------------+
