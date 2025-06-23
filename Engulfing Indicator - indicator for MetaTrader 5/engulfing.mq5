//+------------------------------------------------------------------+
//|                                              Engulfing Indicator |
//|                                       Copyright 2024, Hieu Hoang |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, hieuhoangcntt@gmail.com"
#property indicator_chart_window
#property indicator_buffers 0
string object_names[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isGreenCandle(double open, double close)
  {
   return open < close;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isRedCandle(double open, double close)
  {
   return !isGreenCandle(open, close);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBullishEngulfing(int index,
                        const double &open[],
                        const double &close[])
  {
   if(
      isGreenCandle(open[index], close[index]) &&
      isRedCandle(open[index - 1], close[index - 1]) &&
      open[index] <= close[index - 1] &&
      close[index] > open[index - 1]
   )
      return true;
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBearishEngulfing(int index,
                        const double &open[],
                        const double &close[])
  {
   if(
      isRedCandle(open[index], close[index]) &&
      isGreenCandle(open[index - 1], close[index - 1]) &&
      open[index] >= close[index - 1] &&
      close[index] < open[index - 1]
   )
      return true;
   return false;
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectsDeleteAll(0);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void create_object(string name, ENUM_OBJECT obj_type,const datetime time, const double price)
  {
   ObjectCreate(0, name, obj_type, 0, time, price);
   ArrayResize(object_names, ArraySize(object_names) + 1);
   object_names[ArraySize(object_names) - 1] = name;
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
   int i = prev_calculated == 0 ? 1 : prev_calculated -1;
   for(; i < rates_total; i++)
     {
      if(isBullishEngulfing(i, open, close))
         create_object("Buy at " + close[i], OBJ_ARROW_BUY,time[i], low[i]);
      else
         if(isBearishEngulfing(i, open, close))
            create_object("Sell at " + close[i], OBJ_ARROW_SELL,time[i], high[i]);
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
void delete_objects()
  {
   for(int i = 0; i < ArraySize(object_names); i++)
     {
      ObjectDelete(0, object_names[i]);
     }
   ArrayResize(object_names, 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete_objects();
  }
//+------------------------------------------------------------------+
