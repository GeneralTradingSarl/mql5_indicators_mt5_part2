//+------------------------------------------------------------------+
//|                                             Daily_Highs_Lows.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property description "Identify Daily Highs and Lows"
#property description "with line acting as support and resistance"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 2
#property indicator_plots 2

#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_color1 clrRed
#property indicator_width1 3
#property indicator_label1 "Prev Day High"

#property indicator_type2 DRAW_LINE
#property indicator_style2 STYLE_SOLID
#property indicator_color2 clrBlue
#property indicator_width2 3
#property indicator_label2 "Prev Day Low"
/// Define Buffers

double prevDayH[], prevDayL[];


/// Parameters


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,prevDayH,INDICATOR_DATA);
   SetIndexBuffer(1,prevDayL,INDICATOR_DATA);
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
   for(int i=prev_calculated;i<rates_total;i++)
     {
     
      int shift =iBarShift(_Symbol,PERIOD_D1,time[i]);
      double highD1 = iHigh(_Symbol,PERIOD_D1,shift+1);
      double lowD1 = iLow(_Symbol,PERIOD_D1,shift+1);
      
       prevDayH[i] = highD1;
       prevDayL[i] = lowD1;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
