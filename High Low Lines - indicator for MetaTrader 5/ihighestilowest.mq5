//+------------------------------------------------------------------+
//|                                              iHighestiLowest.mq5 |
//|                                       Copyright 2022, D4rk Ryd3r |
//|                                    https://twitter.com/DarkRyd3r |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, D4rk Ryd3r"
#property link      "https://twitter.com/DarkRyd3r"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

input int PrevBars = 55; // Enter Previous number of Bars

MqlRates History[];
int HighestCandle, LowestCandle;
double SecondHigh[],SecondLow[];
string prefix = "Line_";
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping

   ArraySetAsSeries(History,true);
   ArraySetAsSeries(SecondHigh,true);
   ArraySetAsSeries(SecondLow,true);
   
//---
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,prefix);
   
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
                const int &spread[]) {
//---

   CopyRates(_Symbol,_Period,0,PrevBars,History);

   CopyHigh(_Symbol,_Period,0,PrevBars,SecondHigh);
   HighestCandle = ArrayMaximum(SecondHigh,0,PrevBars);

   CopyLow(_Symbol,_Period,0,PrevBars,SecondLow);
   LowestCandle = ArrayMinimum(SecondLow,0,PrevBars);

   ObjectCreate(NULL,prefix+"SecondHigh", OBJ_HLINE,0,0,History[HighestCandle].high);
   ObjectSetInteger(0,prefix+"SecondHigh",OBJPROP_COLOR,clrMagenta);
   ObjectSetInteger(0,prefix+"SecondHigh",OBJPROP_WIDTH,3);
   ObjectMove(NULL,prefix+"SecondHigh",0,0, History[HighestCandle].high);

   ObjectCreate(NULL,prefix+"SecondLow", OBJ_HLINE,0,0,History[LowestCandle].low);
   ObjectSetInteger(0,prefix+"SecondLow",OBJPROP_COLOR,clrCrimson);
   ObjectSetInteger(0,prefix+"SecondLow",OBJPROP_WIDTH,3);
   ObjectMove(NULL,prefix+"SecondLow",0,0, History[LowestCandle].low);

//--- return value of prev_calculated for next call
   return(rates_total);
}

//+------------------------------------------------------------------+
