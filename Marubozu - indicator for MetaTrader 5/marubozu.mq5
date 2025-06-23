//+------------------------------------------------------------------+
//|                                                     Marubozu.mq5 |
//|                                      Rajesh Nait, Copyright 2023 |
//|                  https://www.mql5.com/en/users/rajeshnait/seller |
//+------------------------------------------------------------------+
#property copyright "Rajesh Nait, Copyright 2023"
#property link      "https://www.mql5.com/en/users/rajeshnait/seller"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//--- plot Bullish Marubozu
#property indicator_label1  "+M"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLimeGreen
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Bearish Marubozu
#property indicator_label2  "-M"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrDeepPink
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- input parameters
input group             "Bullish Marubozu"
sinput uchar               InpBullishMarubozuCode              = 167;         // Bullish Marubozu: code for style DRAW_ARROW (font Wingdings)
sinput int                 InpBullishMarubozuShift             = 10;          // Bullish Marubozu: vertical shift of arrows in pixels
input group             "Bearish Marubozu"
sinput uchar               InpBearishMarubozuCode          = 167;         // Bearish Marubozu: code for style DRAW_ARROW (font Wingdings)
sinput int                 InpBearishMarubozuShift         = 10;          // Bearish Marubozu: vertical shift of arrows in pixels
//--- indicator buffers
double   BullishMarubozuBuffer[];
double   BearishMarubozuBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
//--- indicator buffers mapping
   SetIndexBuffer(0,BullishMarubozuBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BearishMarubozuBuffer,INDICATOR_DATA);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,InpBullishMarubozuCode);
   PlotIndexSetInteger(1,PLOT_ARROW,InpBearishMarubozuCode);
//--- set the vertical shift of arrows in pixels
   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,InpBullishMarubozuShift);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-InpBearishMarubozuShift);
//--- set as an empty value 0.0
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
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
                const int &spread[]) {
//---
   if(rates_total<3)
      return(0);
//---
   int limit=prev_calculated-1;
   if(prev_calculated==0) {
      limit=1;
      BullishMarubozuBuffer[0]=0.0;
      BearishMarubozuBuffer[0]=0.0;
   }
   for(int i=limit; i<rates_total; i++) {
      BullishMarubozuBuffer[i]=0.0;
      BearishMarubozuBuffer[i]=0.0;
      if(i>0) {

         if(open[i]==high[i] && close[i]==low[i]) {
            BearishMarubozuBuffer[i]=high[i];
         }

         if(close[i]==high[i] && open[i]==low[i]) {
            BullishMarubozuBuffer[i]=low[i];
         }
      }
   }
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
