//+------------------------------------------------------------------+
//|                                                        iWPR+.mq5 |
//|                   Copyright 2009-2019, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//|                              https://www.mql5.com/en/users/3rjfx |
//+------------------------------------------------------------------+
#property copyright   "2009-2019, MetaQuotes Software Corp. ~ By 3rjfx ~ Created: 26/12/2019"
#property link        "http://www.mql5.com"
#property link        "https://www.mql5.com/en/users/3rjfx"
#property version     "1.00"
#property description "iWPR+ is an iWPR %Range function with a positive value."
#property description "Because I don't like the negative value of the iWPR function."
#property strict
/*Update to remove bar errors.*/
//---
#property indicator_separate_window
#property indicator_level1     20.0
#property indicator_level2     80.0
#property indicator_levelstyle STYLE_SOLID
#property indicator_levelcolor clrSilver
#property indicator_levelwidth 1
#property indicator_maximum    100.0
#property indicator_minimum    0.0
#property indicator_buffers    2
#property indicator_plots      1
#property indicator_type1      DRAW_LINE
#property indicator_color1     clrRed
//---
//--- input parameters
input int          InpPeriod = 14; // iWPR+ Period
//--- buffers
double WPRBuffer[];
double RANGE[];
//--- global variables
int       ExtPeriodWPR;
#define DATA_LIMIT  100
//---------//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- check for input value
   if(InpPeriod<3)
     {
      ExtPeriodWPR=14;
      Print("Incorrect InpPeriod value. Indicator will use value= ",ExtPeriodWPR);
     }
   else ExtPeriodWPR=InpPeriod;
//---- name for DataWindow and indicator subwindow label
   IndicatorSetString(INDICATOR_SHORTNAME,"iWPR+%R"+"("+string(ExtPeriodWPR)+")");
//---- indicator's buffer
   SetIndexBuffer(0,WPRBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,RANGE,INDICATOR_CALCULATIONS);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ExtPeriodWPR+1);
//--- digits   
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//---
   return(INIT_SUCCEEDED);
  }
//---------//
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
    int i,limit,barc;
//---- insufficient data
   if(rates_total<DATA_LIMIT)
      return(0);
//--- last counted bar will be recounted
   limit=rates_total-prev_calculated;
   if(limit==0) limit=DATA_LIMIT;
   if(prev_calculated>0) limit++;
   barc=limit-InpPeriod-2;
   //--
   ArrayResize(WPRBuffer,limit);
   ArrayResize(RANGE,limit);
   ArraySetAsSeries(WPRBuffer,true);
   ArraySetAsSeries(RANGE,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(time,true);
   //--
   for(i=barc; i>=0; i--)
     {
       double RHigh=high[ArrayMaximum(high,i,InpPeriod)];
       double RLow=low[ArrayMinimum(low,i,InpPeriod)];
       RANGE[i]=(RHigh-close[i])/(RHigh-RLow)*100;
       WPRBuffer[i]=fabs(100-RANGE[i]);
     }
   //---
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+