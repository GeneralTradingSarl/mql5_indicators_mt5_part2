//+------------------------------------------------------------------+
//|                                      LifeHack Balance Equity.mq5 |
//|                              Copyright © 2016, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2016, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "1.008"
#property description "Balance Equity Indicator"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_color1  clrBlue
#property indicator_color2  clrGreen
#property indicator_width1  2
#property indicator_width2  2
#property indicator_label1  "Balance"
#property indicator_label2  "Equity"
//--- indicator buffers
double         BalanceBuffer[];
//double         EquityBuffer_0[];
double         EquityBuffer[];
//--- parameters
int            Visiblebars=300;
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,BalanceBuffer,INDICATOR_DATA);
//SetIndexBuffer(1,EquityBuffer_0,INDICATOR_CALCULATIONS);
   SetIndexBuffer(1,EquityBuffer,INDICATOR_DATA);
   ArraySetAsSeries(BalanceBuffer,true);
//ArraySetAsSeries(EquityBuffer_0,true);
   ArraySetAsSeries(EquityBuffer,true);
//--- name for DataWindow and indicator subwindow label 
   IndicatorSetString(INDICATOR_SHORTNAME,"Balance Equity ");
   PlotIndexSetString(0,PLOT_LABEL,"Balance");
   PlotIndexSetString(1,PLOT_LABEL,"Equity");
//--- construct a short indicator name based on input parameters 
   IndicatorSetInteger(INDICATOR_DIGITS,2);
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
   if(prev_calculated==0)
     {
      for(int i=0;i<rates_total;i++)
        {
         BalanceBuffer[i]=AccountInfoDouble(ACCOUNT_BALANCE);
         EquityBuffer[i]=AccountInfoDouble(ACCOUNT_EQUITY);
         //EquityBuffer_0[i]=0.0;
        }
      return(rates_total);
     }
//---
   BalanceBuffer[0]=AccountInfoDouble(ACCOUNT_BALANCE);
   EquityBuffer[0]=AccountInfoDouble(ACCOUNT_EQUITY);
//EquityBuffer_0[0]=0;
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
