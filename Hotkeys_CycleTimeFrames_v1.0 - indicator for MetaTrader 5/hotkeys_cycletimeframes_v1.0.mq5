//+------------------------------------------------------------------+
//|                                 Hotkeys_CycleTimeFrames_v1.0.mq4 |
//|                                         Copyright 2021, NickBixy |
//|             https://www.forexfactory.com/showthread.php?t=904734 |
//+------------------------------------------------------------------+
#property copyright "NickBixy"
#property link      "https://www.forexfactory.com/showthread.php?t=904734"
//#property version   "1.00"
#property strict
#property description "Hotkeys N, M To Cycle Through Timeframes."
#property description "M for next timeframe."
#property description "N for prev timeframe."

#property indicator_chart_window

//+------------------------------------------------------------------+
int OnInit()
  {
   return(INIT_SUCCEEDED);
  }
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
         case 78://keycode for previous market watch symbol
            PrevTimeFrame();
            break;
         case 77://keycode for next market watch symbol
            NextTimeFrame();
            break;
        }
      ChartRedraw();
     }
  }
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
//+------------------------------------------------------------------+
void NextTimeFrame()
  {
   if(ChartPeriod(0)<PERIOD_M1)
     {
      ChartSetSymbolPeriod(0,NULL,PERIOD_M1);
     }
   else
      if(ChartPeriod(0)<PERIOD_M5)
        {
         ChartSetSymbolPeriod(0,NULL,PERIOD_M5);
        }
      else
         if(ChartPeriod(0)<PERIOD_M15)
           {
            ChartSetSymbolPeriod(0,NULL,PERIOD_M15);
           }
         else
            if(ChartPeriod(0)<PERIOD_M30)
              {
               ChartSetSymbolPeriod(0,NULL,PERIOD_M30);
              }
            else
               if(ChartPeriod(0)<PERIOD_H1)
                 {
                  ChartSetSymbolPeriod(0,NULL,PERIOD_H1);
                 }
               else
                  if(ChartPeriod(0)<PERIOD_H4)
                    {
                     ChartSetSymbolPeriod(0,NULL,PERIOD_H4);
                    }
                  else
                     if(ChartPeriod(0)<PERIOD_D1)
                       {
                        ChartSetSymbolPeriod(0,NULL,PERIOD_D1);
                       }
                     else
                        if(ChartPeriod(0)<PERIOD_W1)
                          {
                           ChartSetSymbolPeriod(0,NULL,PERIOD_W1);
                          }
                        else
                           if(ChartPeriod(0)<PERIOD_MN1)
                             {
                              ChartSetSymbolPeriod(0,NULL,PERIOD_MN1);
                             }
                           else
                              ChartSetSymbolPeriod(0,NULL,PERIOD_M1);

  }
//+------------------------------------------------------------------+
void PrevTimeFrame()
  {
   if(ChartPeriod(0)>PERIOD_MN1)
     {
      ChartSetSymbolPeriod(0,NULL,PERIOD_MN1);
     }
   else
      if(ChartPeriod(0)>PERIOD_W1)
        {
         ChartSetSymbolPeriod(0,NULL,PERIOD_W1);
        }
      else
         if(ChartPeriod(0)>PERIOD_D1)
           {
            ChartSetSymbolPeriod(0,NULL,PERIOD_D1);
           }
         else
            if(ChartPeriod(0)>PERIOD_H4)
              {
               ChartSetSymbolPeriod(0,NULL,PERIOD_H4);
              }
            else
               if(ChartPeriod(0)>PERIOD_H1)
                 {
                  ChartSetSymbolPeriod(0,NULL,PERIOD_H1);
                 }
               else
                  if(ChartPeriod(0)>PERIOD_M30)
                    {
                     ChartSetSymbolPeriod(0,NULL,PERIOD_M30);
                    }
                  else
                     if(ChartPeriod(0)>PERIOD_M15)
                       {
                        ChartSetSymbolPeriod(0,NULL,PERIOD_M15);
                       }
                     else
                        if(ChartPeriod(0)>PERIOD_M5)
                          {
                           ChartSetSymbolPeriod(0,NULL,PERIOD_M5);
                          }
                        else
                           if(ChartPeriod(0)>PERIOD_M1)
                             {
                              ChartSetSymbolPeriod(0,NULL,PERIOD_M1);
                             }
                           else
                              ChartSetSymbolPeriod(0,NULL,PERIOD_MN1);

  }
//+------------------------------------------------------------------+
