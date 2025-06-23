//+------------------------------------------------------------------+
//|                                              MA Zigzag Trend.mq5 |
//|                                   Copyright 2017, Paran Software |
//+------------------------------------------------------------------+
#property copyright "2017, Paran Software"
#property description "MA Zigzag Trend Indicator"
#property version   "1.00"

//--- Indicator Settings
#property indicator_chart_window
#property  indicator_buffers  3
#property indicator_plots     1
#property indicator_type1     DRAW_COLOR_SECTION
#property indicator_color1    Blue, Red
#property indicator_width1    2
#property indicator_label1    "MA Zigzag Trend"

//--- Input Parameter
input int InpSlowPeriod = 33;    // MA Period

//--- Buffers
double MAZigzag[];
double ZigzagColor[];
double PastTrendsVal[];

//--- global variable
int      MA_Period;
int      MA_Handle;
double   prevVal = 0;
//+------------------------------------------------------------------+
//| Paran indicator initialization function                          |
//+------------------------------------------------------------------+
void OnInit()
{
   string short_name;
   if(InpSlowPeriod < 2)
      MA_Period = 55;
   else MA_Period = InpSlowPeriod;
   
   //--- indicator buffers mapping
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
   SetIndexBuffer(0, MAZigzag);
   SetIndexBuffer(1, ZigzagColor, INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2, PastTrendsVal, INDICATOR_DATA);
   
   short_name = "MA(" + string(MA_Period) + ") Zigzag  ";
   IndicatorSetString(INDICATOR_SHORTNAME, short_name);
   short_name = "MA Zigzag  ";
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetString(0, PLOT_LABEL, short_name);
   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, MA_Period);

   MA_Handle = iMA(NULL,0, MA_Period, 0, MODE_SMA, PRICE_CLOSE);
}

//+------------------------------------------------------------------+
//| Paran MA Derivative indicator                                    |
//+------------------------------------------------------------------+
 int OnCalculate (const int rates_total,     // size of input time series 
                 const int prev_calculated,  // bars handled in previous call 
                 const datetime& time[],     // Time 
                 const double& open[],       // Open 
                 const double& high[],       // High 
                 const double& low[],        // Low 
                 const double& close[],      // Close 
                 const long& tick_volume[],  // Tick Volume 
                 const long& volume[],       // Real Volume 
                 const int& spread[])        // Spread 
{
   int i, Pos;
   
//--- Check for Abnormal Starting
   if (rates_total < 2)
      return(0);
//--- Data length
   int data_length;
   if(prev_calculated > rates_total || prev_calculated < 0)
      data_length = rates_total;
   else
   {
      data_length = rates_total - prev_calculated;
      if (prev_calculated > 0)
         data_length++;
   }
   data_length = CopyBuffer(MA_Handle, 0, 0, data_length, PastTrendsVal);
   if ( data_length <= 0)
   {
      Print("Getting MA is failed! Error ", GetLastError());
      return(0);
   }
//----- Main Calculation Loop
   Pos = (prev_calculated == 0)?MA_Period:prev_calculated - 1;
   
   for(i = Pos; i < rates_total - 1 && !IsStopped(); i++)
   {
      if ((PastTrendsVal[i+1] - PastTrendsVal[i])*(PastTrendsVal[i] - PastTrendsVal[i-1]) < 0)
      {
         double hi = MathMax(MathMax(high[i], high[i-1]), MathMax(high[i-2], high[i-3]));
         double lo = MathMin(MathMin(low[i], low[i-1]), MathMin(low[i-2], low[i-3]));
         
         if (prevVal < PastTrendsVal[i])
         {
            MAZigzag[i] = hi;
            ZigzagColor[i] = 1.0;
         }
         else
         {
            MAZigzag[i] = lo;
            ZigzagColor[i] = 0.0;
         }
         prevVal = MAZigzag[i];
      }
   }
   
   return(rates_total);
}
