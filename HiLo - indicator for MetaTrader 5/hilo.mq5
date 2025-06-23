//+------------------------------------------------------------------+
//|                                                         HiLo.mq5 |
//|                                     Copyright 2023, Leandro Souza|
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2
#property indicator_type1 DRAW_LINE
#property indicator_color1 clrDodgerBlue
#property indicator_type2 DRAW_LINE
#property indicator_color2 clrRed

//--- indicator buffers
double HighLineBuffer[];
double LowLineBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0, HighLineBuffer);
   SetIndexBuffer(1, LowLineBuffer);

   IndicatorSetString(INDICATOR_SHORTNAME, "Daily High/Low");
   IndicatorSetInteger(INDICATOR_DIGITS, _Digits);
//--- indicator labels
   PlotIndexSetString(0, PLOT_LABEL, "Highest");
   PlotIndexSetString(1, PLOT_LABEL, "Lowest");

//--- Set indicator as drawing lines
   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);

//--- Set indicator width
   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 1);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 1);

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
                const int &spread[]) {


   int start = prev_calculated == 0
               ? 0
               : prev_calculated-1;


   for(int i = start; i < rates_total; i++) {
      if(i == 0) {
         HighLineBuffer[i] = high[i];
         LowLineBuffer[i] = low[i];
         continue;
      }

      MqlDateTime current_time, previous_time;
      TimeToStruct(time[i], current_time);
      TimeToStruct(time[i-1], previous_time);
      if(current_time.day == previous_time.day && current_time.mon == previous_time.mon) {
         if(high[i] >= HighLineBuffer[i-1]) {
            HighLineBuffer[i] = high[i];
         } else {
            HighLineBuffer[i] = HighLineBuffer[i-1];
         }

         if(low[i] <= LowLineBuffer[i-1]) {
            LowLineBuffer[i] = low[i];
         } else {
            LowLineBuffer[i] = LowLineBuffer[i-1];
         }
      } else {
         HighLineBuffer[i] = high[i];
         LowLineBuffer[i] = low[i];
      }
   }

   return(rates_total);
}

//+------------------------------------------------------------------+
