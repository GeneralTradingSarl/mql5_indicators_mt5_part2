//+------------------------------------------------------------------+
//|                                                       FastZZ.mq5 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Yurich"
#property link      "https://login.mql5.com/ru/users/Yurich"
#property version   "1.00"
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 1
#property indicator_label1  "Fast ZZ"
#property indicator_type1   DRAW_ZIGZAG
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//+------------------------------------------------------------------+
input int Depth=1000; // Minimum points in a ray
//+------------------------------------------------------------------+
double zzH[],zzL[];
double depth;//, deviation;
int last,direction;
//+------------------------------------------------------------------+
void OnInit()
  {
   SetIndexBuffer(0,zzH,INDICATOR_DATA);
   SetIndexBuffer(1,zzL,INDICATOR_DATA);
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   depth=Depth*_Point;
//deviation=10*_Point;
   direction=1;
   last=0;
  }
//+------------------------------------------------------------------+
int OnCalculate(const int total,
                const int calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick[],
                const long &real[],
                const int &spread[])
  {
   if(calculated==0) last=0;
   for(int i=calculated>0?calculated-1:0; i<total-1; i++)
     {
      bool set=false;
      zzL[i]=0;
      zzH[i]=0;
      //---
      if(direction>0)
        {
         if(high[i]>zzH[last])//-deviation)
           {
            zzH[last]=0;
            zzH[i]=high[i];
            if(low[i]<high[last]-depth)
              {
               if(open[i]<close[i]) zzH[last]=high[last]; else direction=-1;
               zzL[i]=low[i];
              }
            last=i;
            set=true;
           }
         if(low[i]<zzH[last]-depth && (!set || open[i]>close[i]))
           {
            zzL[i]=low[i];
            if(high[i]>zzL[i]+depth && open[i]<close[i]) zzH[i]=high[i]; else direction=-1;
            last=i;
           }
        }
      else
        {
         if(low[i]<zzL[last])//+deviation)
           {
            zzL[last]=0;
            zzL[i]=low[i];
            if(high[i]>low[last]+depth)
              {
               if(open[i]>close[i]) zzL[last]=low[last]; else direction=1;
               zzH[i]=high[i];
              }
            last=i;
            set=true;
           }
         if(high[i]>zzL[last]+depth && (!set || open[i]<close[i]))
           {
            zzH[i]=high[i];
            if(low[i]<zzH[i]-depth && open[i]>close[i]) zzL[i]=low[i]; else direction=1;
            last=i;
           }
        }
     }
//----
   zzH[total-1]=0;
   zzL[total-1]=0;
   return(total);
  }
//+------------------------------------------------------------------+
