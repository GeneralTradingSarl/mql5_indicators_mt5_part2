//+------------------------------------------------------------------+
//|                                    Swing Highs & Lows.mq5        |
//|                                    Copyright 2024, Philani       |
//|                                          indices.group@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Indices Group (Pty) Ltd"
#property link      "https://indices-investment-group.thinkific.com"
#property description   " Finds swing highs and swing lows, use it with any \n "
#property  description " market structure strategy"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 2
#property indicator_plots   2

//--- plot Swing High
#property indicator_label1  "Swing High"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrRed
#property indicator_width1  2

//--- plot Swing Low
#property indicator_label2  "Swing Low"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrBlue
#property indicator_width2  2

//--- input parameters
input int      InpRangeBars = 12;    // Number of bars to check on each side

//--- indicator buffers
double         SwingHighBuffer[];
double         SwingLowBuffer[];

//--- variables to store swing points
double         H1 = 0;
double         L1 = 0;
datetime       H1Time = 0;
datetime       L1Time = 0;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   //--- indicator buffers mapping
   SetIndexBuffer(0, SwingHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, SwingLowBuffer, INDICATOR_DATA);
   
   //--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0, PLOT_ARROW, 234);
   PlotIndexSetInteger(1, PLOT_ARROW, 233);
   
   //--- setting indicator digits
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   
   //--- name for DataWindow and indicator subwindow label
   string short_name = "Improved Swing High/Low Identifier";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   
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
   int start;
   
   if(prev_calculated == 0)
      start = InpRangeBars;
   else
      start = prev_calculated - 1;
   
   for(int i = start; i < rates_total - InpRangeBars && !IsStopped(); i++)
     {
      SwingHighBuffer[i] = EMPTY_VALUE;
      SwingLowBuffer[i] = EMPTY_VALUE;
      
      bool isSwingHigh = true;
      bool isSwingLow = true;
      
      // Check for Swing High
      for(int j = 1; j <= InpRangeBars; j++)
        {
         if(high[i] <= high[i+j] || high[i] <= high[i-j])
           {
            isSwingHigh = false;
            break;
           }
        }
      
      // Check for Swing Low
      for(int j = 1; j <= InpRangeBars; j++)
        {
         if(low[i] >= low[i+j] || low[i] >= low[i-j])
           {
            isSwingLow = false;
            break;
           }
        }
      
      if(isSwingHigh)
        {
         SwingHighBuffer[i] = high[i];
         CreateLabel("SwingHigh_" + IntegerToString(i), time[i], high[i], "H", clrRed);
         if(high[i] > H1 || H1 == 0)
           {
            H1 = high[i];
            H1Time = time[i];
           }
        }
      
      if(isSwingLow)
        {
         SwingLowBuffer[i] = low[i];
         CreateLabel("SwingLow_" + IntegerToString(i), time[i], low[i], "L", clrBlue);
         if(low[i] < L1 || L1 == 0)
           {
            L1 = low[i];
            L1Time = time[i];
           }
        }
     }
   
   return(rates_total);
  }

//+------------------------------------------------------------------+
//| Create a text label on the chart                                 |
//+------------------------------------------------------------------+
void CreateLabel(const string name, const datetime time, const double price, const string text, const color clr)
  {
   ObjectCreate(0, name, OBJ_TEXT, 0, time, price);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
  }

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, "SwingHigh_");
   ObjectsDeleteAll(0, "SwingLow_");
  }
