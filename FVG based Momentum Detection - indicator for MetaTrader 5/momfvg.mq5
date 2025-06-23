//+------------------------------------------------------------------+
//|                                              MomFVG.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//|                                          Author: Yashar Seyyedin |
//|       Web Address: https://www.mql5.com/en/users/yashar.seyyedin |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
//--- plot UpMom
#property indicator_label1  "UpMom"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot DnMom
#property indicator_label2  "DnMom"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- indicator buffers
double         UpMomBuffer[];
double         DnMomBuffer[];

//--- input parameters
input int window_size=50; //window size

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,UpMomBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,DnMomBuffer,INDICATOR_DATA);

   ArraySetAsSeries(UpMomBuffer,true);
   ArraySetAsSeries(DnMomBuffer,true);
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
   int BARS=MathMax(rates_total-prev_calculated-window_size, 1);
   for(int i=BARS;i>=0;i--)
     {
      UpMomBuffer[i] = 0;
      for(int j=i+1;j<i+window_size;j++)
         UpMomBuffer[i] += FVGUpMom(j);

      DnMomBuffer[i] = 0;
      for(int j=i+1;j<i+window_size;j++)
         DnMomBuffer[i] += FVGDnMom(j);
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FVGUpMom(int j)
  {
   double high = iHigh(_Symbol, PERIOD_CURRENT, j+1);
   double low = iLow(_Symbol, PERIOD_CURRENT, j-1);
   return MathMax(low-high, 0);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FVGDnMom(int j)
  {
   double high = iHigh(_Symbol, PERIOD_CURRENT, j-1);
   double low = iLow(_Symbol, PERIOD_CURRENT, j+1);
   return MathMax(low-high, 0);
  }
//+------------------------------------------------------------------+
