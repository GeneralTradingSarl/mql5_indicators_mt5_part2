//+------------------------------------------------------------------+
//|                                                          GMA.mq5 |
//|                                                     Yuriy Tokman |
//|                                                http://ytg.com.ua |
//+------------------------------------------------------------------+
#property copyright "Yuriy Tokman"
#property link      "http://ytg.com.ua"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 1
#property indicator_plots   1
#property indicator_width1   2
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDarkViolet
//--- input parameters
input int            GMA_Period=21;         // Period
//--- indicator buffers
double Buffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,Buffer);
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,GMA_Period);
   string short_name="GMA";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name+"("+string(GMA_Period)+")");
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
//----
   int i,limit;
//--- check for rates
   if(rates_total<GMA_Period) return(0);
//--- preliminary calculations
   if(prev_calculated==0)limit=GMA_Period;
   else limit=prev_calculated-1;
//--- the main loop of calculations
   for(i=limit;i<rates_total && !IsStopped();i++)
     {
      double MG = mg (open,high,low,close,i);
      Buffer[i]=MG;
     }
 //----
   return(rates_total);
  }
//+------------------------------------------------------------------+
 double mg (const double &o[],const double &h[],const double &l[],const double &c[],int _i)
  {
   double res =1;
   for(int j=_i;j>_i-GMA_Period && j>0;j--)
   res *= (c[j]+o[j]+h[j]+l[j])/4.0;
   return(MathPow(res,1.0/GMA_Period));  
  }
