//+------------------------------------------------------------------+
//|                                      Hotkeys_TimeFrames_v1.0.mq5 |
//|                                         Copyright 2021, NickBixy |
//|             https://www.forexfactory.com/showthread.php?t=904734 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, NickBixy"
#property link      "https://www.forexfactory.com/showthread.php?t=904734"
#property version   "1.00"
#property indicator_chart_window
#property description "Hotkeys Timeframes 1-9 numbers on keyboard but not on number-pad."
#property description "1=m1, 2=m5, 3=m15, 4=m30, 5=h1, 6=h4, 7=d1, 8=w1, 9=mn ."

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   
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
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   if(id==CHARTEVENT_KEYDOWN)
     {
      //if want to change default hotkeys for next and previous symbol in market watch
      //use this website to find keycode https://keycode.info
      //https://keycode.info
      switch(int(lparam))
        {
         case 49:
            ChartSetSymbolPeriod(0,NULL,PERIOD_M1);
            break;
         case 50:
            ChartSetSymbolPeriod(0,NULL,PERIOD_M5);
            break;
         case 51:
            ChartSetSymbolPeriod(0,NULL,PERIOD_M15);
            break;
         case 52:
            ChartSetSymbolPeriod(0,NULL,PERIOD_M30);
            break;
         case 53:
            ChartSetSymbolPeriod(0,NULL,PERIOD_H1);
            break;
         case 54:
            ChartSetSymbolPeriod(0,NULL,PERIOD_H4);
            break;
         case 55:
            ChartSetSymbolPeriod(0,NULL,PERIOD_D1);
            break;
         case 56:
            ChartSetSymbolPeriod(0,NULL,PERIOD_W1);
            break;
         case 57:
            ChartSetSymbolPeriod(0,NULL,PERIOD_MN1);
            break;
        }
      ChartRedraw();
     }
  }