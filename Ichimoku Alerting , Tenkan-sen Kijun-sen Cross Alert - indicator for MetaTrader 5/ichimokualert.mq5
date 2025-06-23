//+------------------------------------------------------------------+
//|                                                IchimokuAlert.mq5 |
//|                                        Copyright 2021, MSK Corp. |
//|                                                m.saket@gmail.com |
//+------------------------------------------------------------------+
#property copyright "2021, MSK Corp."
#property link      "m.saket@gmail.com"
#property description "Ichimoku Tenkan_sen Kinjun-sen Cross Alert"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_color1  Red
#property indicator_color2  Blue
#property indicator_label1  "Tenkan-sen"
#property indicator_label2  "Kijun-sen"
//--- input parameters
input int InpTenkan=9;     // Tenkan-sen
input int InpKijun=26;     // Kijun-sen
//--- indicator buffers
double    ExtTenkanBuffer[];
double    ExtKijunBuffer[];
int       LastBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtTenkanBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtKijunBuffer,INDICATOR_DATA);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpTenkan);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpKijun);
//--- lines shifts when drawing
   PlotIndexSetInteger(2,PLOT_SHIFT,InpKijun);
   PlotIndexSetInteger(3,PLOT_SHIFT,-InpKijun);
//--- change labels for DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"Tenkan-sen("+string(InpTenkan)+")");
   PlotIndexSetString(1,PLOT_LABEL,"Kijun-sen("+string(InpKijun)+")");
  }
//+------------------------------------------------------------------+
//| Ichimoku Kinko Hyo                                               |
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
//---
   if(prev_calculated==0)
      start=1;
   else
      start=prev_calculated-1;
//--- main loop
   for(int i=start; i<rates_total && !IsStopped(); i++)
     {
      //--- tenkan sen
      double price_max=Highest(high,InpTenkan,i);
      double price_min=Lowest(low,InpTenkan,i);
      ExtTenkanBuffer[i]=(price_max+price_min)/2.0;
      //--- kijun sen
      price_max=Highest(high,InpKijun,i);
      price_min=Lowest(low,InpKijun,i);
      ExtKijunBuffer[i]=(price_max+price_min)/2.0;
      double ee=ExtTenkanBuffer[i];
      double es=ExtKijunBuffer[i];
      double ew=ExtTenkanBuffer[i-1];
      double wq=ExtKijunBuffer[i-1];

      int nBars=Bars(_Symbol,PERIOD_CURRENT);
      if(LastBars!=nBars)
        {
         LastBars=nBars;
         if(ExtTenkanBuffer[i]>ExtKijunBuffer[i] && ExtTenkanBuffer[i-1]<=ExtKijunBuffer[i-1])
            SendNotification("Cross Up");
         if(ExtTenkanBuffer[i]<ExtKijunBuffer[i] && ExtTenkanBuffer[i-1]>=ExtKijunBuffer[i-1])
            SendNotification("Cross Up");
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| get price_max value for range                                      |
//+------------------------------------------------------------------+
double Highest(const double& array[],const int range,int from_index)
  {
   double res=0;
//---
   res=array[from_index];
   for(int i=from_index; i>from_index-range && i>=0; i--)
      if(res<array[i])
         res=array[i];
//---
   return(res);
  }
//+------------------------------------------------------------------+
//| get price_min value for range                                       |
//+------------------------------------------------------------------+
double Lowest(const double& array[],const int range,int from_index)
  {
   double res=0;
//---
   res=array[from_index];
   for(int i=from_index; i>from_index-range && i>=0; i--)
      if(res>array[i])
         res=array[i];
//---
   return(res);
  }
//+------------------------------------------------------------------+
