//+------------------------------------------------------------------+
//|                    Elders Safe Zone(barabashkakvn's edition).mq5 |
//|                                                        Cubesteak |
//|                                                www.cubesteak.net |
//+------------------------------------------------------------------+
#property copyright "Cubesteak"
#property link      "www.cubesteak.net"
#property version   "1.000"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 1
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrBlueViolet
//--- input parameters
input int      LookBack    = 10;       // LookBack
input int      StopFactor  = 3;        // StopFactor
input int      EMALength   = 13;       // EMALength
//--- indicator buffers
double         ExtBuffer[];
double         ExtMaBuffer[];
//--- MA handle
int            ExtMaHandle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtMaBuffer,INDICATOR_CALCULATIONS);
//--- set accuracy
   IndicatorSetInteger(INDICATOR_DIGITS,Digits()+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,EMALength);
//--- sets drawing line empty value--
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//--- get MA handles
   ExtMaHandle=iMA(Symbol(),Period(),EMALength,0,MODE_EMA,PRICE_CLOSE);
//--- if the handle is not created 
   if(ExtMaHandle==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
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
   if(rates_total<EMALength)
      return(0);
//--- not all data may be calculated
   int calculated=BarsCalculated(ExtMaHandle);
   if(calculated<rates_total)
     {
      Print("Not all data of ExtMaHandle is calculated (",calculated," bars ). Error",GetLastError());
      return(0);
     }
//--- we can copy not all data
   int to_copy;
   if(prev_calculated>rates_total || prev_calculated<0)
      to_copy=rates_total;
   else
     {
      to_copy=rates_total-prev_calculated;
      if(prev_calculated>0)
         to_copy++;
     }
//--- get MA buffer
   if(IsStopped())
      return(0); //Checking for stop flag
   if(CopyBuffer(ExtMaHandle,0,0,to_copy,ExtMaBuffer)<=0)
     {
      Print("Getting fast EMA is failed! Error",GetLastError());
      return(0);
     }
//---
   int limit;
   if(prev_calculated==0)
     {
      limit=LookBack+1;
      ArrayInitialize(ExtBuffer,0.0);
     }
   else
      limit=prev_calculated-1;
   double SafeStop=0;
//--- calculate 
   for(int i=limit;i<rates_total && !IsStopped();i++) // time[rates_total-1] -> current time
     {
      double EMA0=ExtMaBuffer[i];
      double EMA1=ExtMaBuffer[i-1];
      double EMA2=ExtMaBuffer[i-2];
      double PreSafeStop=ExtBuffer[i-1];
      double Pen=0;
      int Counter=0;
      if(EMA0>EMA1)
        {
         for(int value1=0;value1<=LookBack; value1++)
           {
            if(low[i-value1]<low[i-value1-1])
              {
               Pen=low[i-value1-1]-low[i-value1]+Pen;
               Counter=Counter+1;
              }
           }
         if(Counter!=0)
            SafeStop=close[i]-((double)StopFactor*(Pen/(double)Counter));
         else
            SafeStop=close[i]-((double)StopFactor*Pen);
         if((SafeStop<PreSafeStop) && (EMA1>EMA2))
            SafeStop=PreSafeStop;
        }
      if(EMA0<EMA1)
        {
         for(int value1=0;value1<=LookBack; value1++)
           {
            if(high[i-value1]>high[i-value1-1])
              {
               Pen=high[i-value1]-high[i-value1-1]+Pen;
               Counter=Counter+1;
              }
           }
         if(Counter!=0)
            SafeStop=close[i]+((double)StopFactor *(Pen/(double)Counter));
         else
            SafeStop=close[i]+((double)StopFactor*Pen);
         if((SafeStop>PreSafeStop) && (EMA1<EMA2))
            SafeStop=PreSafeStop;
        }
      PreSafeStop=SafeStop;
      ExtBuffer[i]=SafeStop;
     }
////--- calculate Signal
//   SimpleMAOnBuffer(rates_total,prev_calculated,0,InpSignalSMA,ExtMacdBuffer,ExtSignalBuffer);
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
