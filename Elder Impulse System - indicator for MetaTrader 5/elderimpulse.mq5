//+------------------------------------------------------------------+
//|                                                 ElderImpulse.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Cuong Thai"
#include <MovingAverages.mqh>
#property indicator_buffers 8
#property indicator_plots 1                  //Number of graphic plots
#property indicator_type1 DRAW_COLOR_BARS    //Drawing style - color candles
#property indicator_color1 Red,Blue,Green
//--- input parameters
input int      InpFast=12;
input int      InpSlow=16;
input int      EMA=13;
input ENUM_APPLIED_PRICE InpAppliedPrice=PRICE_CLOSE; // Applied price
//--- indicator buffers
double buffer_open[],buffer_high[],buffer_low[],buffer_close[]; //Buffers for data
double barColors[];
double ExtFastMaBuffer[];
double ExtSlowMaBuffer[];
double ExtEMaBuffer[];
//--- MA handles
int ExtFastMaHandle;
int ExtSlowMaHandle;
int ExtEMaHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,buffer_open,INDICATOR_DATA);
   SetIndexBuffer(1,buffer_high,INDICATOR_DATA);
   SetIndexBuffer(2,buffer_low,INDICATOR_DATA);
   SetIndexBuffer(3,buffer_close,INDICATOR_DATA);
   SetIndexBuffer(4,barColors,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(5,ExtFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(6,ExtSlowMaBuffer,INDICATOR_CALCULATIONS);

   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,3);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,Red);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,Blue);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,2,Green);

   ExtFastMaHandle=iMA(NULL,0,InpFast,0,MODE_EMA,InpAppliedPrice);
   ExtSlowMaHandle=iMA(NULL,0,InpSlow,0,MODE_EMA,InpAppliedPrice);
   ExtEMaHandle=iMA(NULL,0,EMA,0,MODE_EMA,InpAppliedPrice);
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
//--- check for data
   if(rates_total<EMA)
      return(0);
//--- not all data may be calculated
   int calculated=BarsCalculated(ExtFastMaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtFastMaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
     }
   calculated=BarsCalculated(ExtSlowMaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtSlowMaHandle is calculated (",calculated,"bars ). Error",GetLastError());
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
//--- get Fast EMA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtFastMaHandle,0,0,to_copy,ExtFastMaBuffer)<=0)
     {
      Print("Getting fast EMA is failed! Error",GetLastError());
      return(0);
     }
//--- get Slow EMA buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtSlowMaHandle,0,0,to_copy,ExtSlowMaBuffer)<=0)
     {
      Print("Getting slow EMA is failed! Error",GetLastError());
      return(0);
     }
//--- get EMA13 buffer
   if(IsStopped()) return(0); //Checking for stop flag
   if(CopyBuffer(ExtEMaHandle,0,0,to_copy,ExtEMaBuffer)<=0)
     {
      Print("Getting EMA 13 is failed! Error",GetLastError());
      return(0);
     }
//---
   int limit;
   if(prev_calculated==0)
      limit=1;
   else
      limit=prev_calculated;
//--- calculate MACD
   double Macd1 = 0.0;
   double Macd2 = 0.0;
   for(int i=limit;i<rates_total && !IsStopped();i++) 
     {
      //Set data for plotting
      buffer_open[i]=open[i];
      buffer_high[i]=high[i];
      buffer_low[i]=low[i];
      buffer_close[i]=close[i];
      Macd2=ExtFastMaBuffer[i]-ExtSlowMaBuffer[i];
      Macd1=ExtFastMaBuffer[i-1]-ExtSlowMaBuffer[i-1];
      if((Macd2>Macd1) && (ExtEMaBuffer[i]>ExtEMaBuffer[i-1]))
         barColors[i]=2;
      else if((Macd2<Macd1) && (ExtEMaBuffer[i]<ExtEMaBuffer[i-1]))
         barColors[i]=0;
      else
         barColors[i]=1;
     }
//--- return value of prev_calculated for next call
   return(rates_total-1);
  }
//+------------------------------------------------------------------+
