//+------------------------------------------------------------------+
//|                                            Candle_Size_Alert.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2018, MetaQuotes Software Corp."
#property link          "https://mql5.com"
#property version       "1.00"
#property description   "Shows candles with a size that is more than specified and,"
#property description   "if allowed in the settings, then displays an alert"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot HighSize
#property indicator_label1  "HighSize"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- enums
enum ENUM_INPUT_YES_NO
  {
   INPUT_YES   =  1,    // Yes
   INPUT_NO    =  0     // No
  };
//--- input parameters
input uint              InpLevelSize   =  20;         // Size level
input ENUM_INPUT_YES_NO InpOnlyLastBar =  INPUT_NO;   // Displays only last bar
input ENUM_INPUT_YES_NO InpEnableAlert =  INPUT_NO;   // Use alerts
//--- indicator buffers
double         BufferHighSize[];
//--- global variables
double         level_size_pip=0;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Size level in points
   level_size_pip=InpLevelSize*Point();
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferHighSize,INDICATOR_DATA);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,108);
//--- setting a indicators short name
   IndicatorSetString(INDICATOR_SHORTNAME,"Candle size alert");
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
//--- Set arrays as time series
   ArraySetAsSeries(BufferHighSize,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
//--- Checking for minimum number of bars
   if(rates_total<1) return 0;
//---
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-1;
      ArrayInitialize(BufferHighSize,EMPTY_VALUE);
     }
//---
   int beg=(InpOnlyLastBar ? 0 : limit);
   for(int i=beg; i>=0 && !IsStopped(); i--)
     {
      if(NormalizeDouble(high[i]-low[i]-level_size_pip,Digits())>=0)
        {
         if(InpEnableAlert && i==0 && BufferHighSize[i]==EMPTY_VALUE)
            Alert(Symbol(),", ",NameTimeframe(),": Candle size>=",InpLevelSize," pips");
         BufferHighSize[i]=high[i];
         if(InpOnlyLastBar)
            BufferHighSize[i+1]=EMPTY_VALUE;
        }
      else
         BufferHighSize[i]=EMPTY_VALUE;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
string NameTimeframe(void)
  {
   switch(Period())
     {
      case 1      : return "M1";
      case 2      : return "M2";
      case 3      : return "M3";
      case 4      : return "M4";
      case 5      : return "M5";
      case 6      : return "M6";
      case 10     : return "M10";
      case 12     : return "M12";
      case 15     : return "M15";
      case 20     : return "M20";
      case 30     : return "M30";
      case 16385  : return "H1";
      case 16386  : return "H2";
      case 16387  : return "H3";
      case 16388  : return "H4";
      case 16390  : return "H6";
      case 16392  : return "H8";
      case 16396  : return "H12";
      case 16408  : return "D1";
      case 32769  : return "W1";
      case 49153  : return "MN1";
      default     : return "Unknown Period";
     }
  }
//+------------------------------------------------------------------+
