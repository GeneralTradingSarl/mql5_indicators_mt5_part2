//+------------------------------------------------------------------+
//|                                                  Hammer Indicator|
//|                            Copyright 2024, Rama Destrian Hartadi |
//|               Web Address: https://www.mql5.com/en/users/vilraxq |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, vilraxq"
#property indicator_chart_window
#property indicator_buffers 0

string m_objectNames[];

input double MaxRatioShortWick = 0.05;
input double MinRatioLongWick = 0.7;
input double MinCandleSize = 10.0;

//+------------------------------------------------------------------+
//| Function to check if the candle is green                         |
//+------------------------------------------------------------------+
bool IsGreenCandle(double open, double close)
  {
   return open < close;
  }

//+------------------------------------------------------------------+
//| Function to check if the candle is red                           |
//+------------------------------------------------------------------+
bool IsRedCandle(double open, double close)
  {
   return !IsGreenCandle(open, close);
  }

//+------------------------------------------------------------------+
//| Function to detect Green Hammer                                  |
//+------------------------------------------------------------------+
bool IsGreenHammer(int index,
                   const double &open[],
                   const double &close[],
                   const double &high[],
                   const double &low[],
                   double maxRatioShortWick,
                   double minRatioLongWick,
                   double minCandleSize)
  {

   double candleSize = high[index] - low[index];
   if(candleSize < minCandleSize * _Point)
      return false;

   return (IsGreenCandle(open[index], close[index]) &&
           high[index] - close[index] < candleSize * maxRatioShortWick &&
           open[index] - low[index] > candleSize * minRatioLongWick);
  }

//+------------------------------------------------------------------+
//| Function to detect Red Hammer                                    |
//+------------------------------------------------------------------+
bool IsRedHammer(int index,
                 const double &open[],
                 const double &close[],
                 const double &high[],
                 const double &low[],
                 double maxRatioShortWick,
                 double minRatioLongWick,
                 double minCandleSize)
  {

   double candleSize = high[index] - low[index];
   if(candleSize < minCandleSize * _Point)
      return false;

   return (IsRedCandle(open[index], close[index]) &&
           high[index] - open[index] < candleSize * maxRatioShortWick &&
           close[index] - low[index] > candleSize * minRatioLongWick);
  }

//+------------------------------------------------------------------+
//| Function to detect Green Inverted Hammer                         |
//+------------------------------------------------------------------+
bool IsGreenInvertedHammer(int index,
                           const double &open[],
                           const double &close[],
                           const double &high[],
                           const double &low[],
                           double maxRatioShortWick,
                           double minRatioLongWick,
                           double minCandleSize)
  {

   double candleSize = high[index] - low[index];
   if(candleSize < minCandleSize * _Point)
      return false;

   return (IsGreenCandle(open[index], close[index]) &&
           close[index] - low[index] < candleSize * maxRatioShortWick &&
           high[index] - open[index] > candleSize * minRatioLongWick);
  }

//+------------------------------------------------------------------+
//| Function to detect Red Inverted Hammer                           |
//+------------------------------------------------------------------+
bool IsRedInvertedHammer(int index,
                         const double &open[],
                         const double &close[],
                         const double &high[],
                         const double &low[],
                         double maxRatioShortWick,
                         double minRatioLongWick,
                         double minCandleSize)
  {

   double candleSize = high[index] - low[index];
   if(candleSize < minCandleSize * _Point)
      return false;

   return (IsRedCandle(open[index], close[index]) &&
           open[index] - low[index] < candleSize * maxRatioShortWick &&
           high[index] - close[index] > candleSize * minRatioLongWick);
  }

//+------------------------------------------------------------------+
//| Indicator Initialization                                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectsDeleteAll(0);
   return (INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Main indicator function                                          |
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

   int i = prev_calculated == 0 ? 1 : prev_calculated - 1;
   for(; i < rates_total; i++)
     {
      if(IsGreenHammer(i, open, close, high, low, MaxRatioShortWick, MinRatioLongWick, MinCandleSize))
        {
         CreateObject(time[i], low[i], 233, 1, clrGreen, "Green Hammer");
        }
      else
         if(IsRedHammer(i, open, close, high, low, MaxRatioShortWick, MinRatioLongWick, MinCandleSize))
           {
            CreateObject(time[i], low[i], 233, 1, clrRed, "Red Hammer");
           }
         else
            if(IsGreenInvertedHammer(i, open, close, high, low, MaxRatioShortWick, MinRatioLongWick, MinCandleSize))
              {
               CreateObject(time[i], high[i], 234, -1, clrGreen, "Green Inverted Hammer");
              }
            else
               if(IsRedInvertedHammer(i, open, close, high, low, MaxRatioShortWick, MinRatioLongWick, MinCandleSize))
                 {
                  CreateObject(time[i], high[i], 234, -1, clrRed, "Red Inverted Hammer");
                 }
     }

   return (rates_total);
  }

//+------------------------------------------------------------------+
//| Delete objects on deinit                                         |
//+------------------------------------------------------------------+
void DeleteObjects()
  {
   for(int i = 0; i < ArraySize(m_objectNames); i++)
     {
      ObjectDelete(0, m_objectNames[i]);
     }
   ArrayResize(m_objectNames, 0);
  }

//+------------------------------------------------------------------+
//| Indicator Deinitialization                                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   DeleteObjects();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateObject(datetime time, double price, int arrowCode, int direction, color clr, string txt)
  {
   string objName = "";
   StringConcatenate(objName, "Signal@", time, "at", DoubleToString(price,_Digits),"(", arrowCode,")");
   if(ObjectCreate(0, objName, OBJ_ARROW, 0, time, price))
     {
      ObjectSetInteger(0, objName, OBJPROP_ARROWCODE, arrowCode);
      ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
      if(direction > 0)
         ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_TOP);
      if(direction < 0)
         ObjectSetInteger(0, objName, OBJPROP_ANCHOR, ANCHOR_BOTTOM);

     }
   string objNameDesc = objName + txt;
   if(ObjectCreate(0, objNameDesc, OBJ_TEXT, 0, time, price))
     {
      ObjectSetString(0, objNameDesc, OBJPROP_TEXT, "  " + txt);
      ObjectSetInteger(0, objNameDesc, OBJPROP_COLOR, clr);
     }
  }
//+------------------------------------------------------------------+
