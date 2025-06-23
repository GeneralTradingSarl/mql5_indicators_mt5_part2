//+------------------------------------------------------------------+
//|                                                   ZigZagFibo.mq5 |
//|                       							  Сергей Семёнов |
//|                          https://www.mql5.com/ru/users/namespace |
//+------------------------------------------------------------------+
#property copyright "Сергей Семёнов"
#property link      "https://www.mql5.com/ru/users/namespace"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   9

//---- plot Zigzag
#property indicator_label1 "ZigzagFibo"
#property indicator_type1  DRAW_SECTION
#property indicator_type2  DRAW_ARROW
#property indicator_type3  DRAW_ARROW
#property indicator_type4  DRAW_ARROW
#property indicator_type5  DRAW_ARROW
#property indicator_type6  DRAW_ARROW
#property indicator_type7  DRAW_ARROW
#property indicator_color1 clrIndigo
#property indicator_color2 Green
#property indicator_color3 Tomato
#property indicator_color4 clrOliveDrab
#property indicator_color5 clrForestGreen
#property indicator_color6 clrLightSeaGreen
#property indicator_color7 clrTeal
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- input parameters
input int ExtDepth=12;
input int ExtDeviation = 5;
input int ExtBackstep  = 3;

//--- indicator buffers
double ZigzagBuffer[];      // main buffer
double HighMapBuffer[];     // highs
double LowMapBuffer[];      // lows
double Level236[],Level382[],Level500[],Level618[],
SignalLongBuffer[],SignalShortBuffer[];

int    level=3;             // recounting depth
double deviation;           // deviation in points
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() 
  {

//--- indicator buffers mapping
   SetIndexBuffer(0,ZigzagBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SignalLongBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,SignalShortBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,Level236,INDICATOR_DATA);
   SetIndexBuffer(4,Level382,INDICATOR_DATA);
   SetIndexBuffer(5,Level500,INDICATOR_DATA);
   SetIndexBuffer(6,Level618,INDICATOR_DATA);
   SetIndexBuffer(7,HighMapBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(8,LowMapBuffer,INDICATOR_CALCULATIONS);

//--- set short name and digits   
   PlotIndexSetString(0,PLOT_LABEL,"ZigZagFibo("+(string)ExtDepth+","+(string)ExtDeviation+","+(string)ExtBackstep+")");

   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);

//--- set empty value
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(5, PLOT_EMPTY_VALUE, 0.0);
   PlotIndexSetDouble(6, PLOT_EMPTY_VALUE, 0.0);

//--- arrow
   PlotIndexSetInteger(1,PLOT_ARROW,108);
   PlotIndexSetInteger(2,PLOT_ARROW,108);
   PlotIndexSetInteger(3,PLOT_ARROW,140);
   PlotIndexSetInteger(4,PLOT_ARROW,141);
   PlotIndexSetInteger(5,PLOT_ARROW,142);
   PlotIndexSetInteger(6,PLOT_ARROW,143);

//--- width
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,2);
   PlotIndexSetInteger(2,PLOT_LINE_WIDTH,2);
   PlotIndexSetInteger(3,PLOT_LINE_WIDTH,2);
   PlotIndexSetInteger(4,PLOT_LINE_WIDTH,2);
   PlotIndexSetInteger(5,PLOT_LINE_WIDTH,2);
   PlotIndexSetInteger(6,PLOT_LINE_WIDTH,2);

//--- to use in cycle
   deviation=ExtDeviation*_Point;
//---
   return(0);
  }
//+------------------------------------------------------------------+
//|  searching index of the highest bar                              |
//+------------------------------------------------------------------+
int iHighest(const double &array[],int depth,int startPos) 
  {

   int index=startPos;

//--- start index validation
   if(startPos<0) 
     {
      Print("Invalid parameter in the function iHighest, startPos =",startPos);
      return 0;
     }

   int size=ArraySize(array);

//--- depth correction if need
   if(startPos-depth<0) depth=startPos;
   double max=array[startPos];

//--- start searching
   for(int i=startPos; i>startPos-depth; i--) 
     {
      if(array[i]>max) 
        {
         index=i;
         max=array[i];
        }
     }
//--- return index of the highest bar
   return(index);
  }
//+------------------------------------------------------------------+
//|  searching index of the lowest bar                               |
//+------------------------------------------------------------------+
int iLowest(const double &array[],int depth,int startPos) 
  {

   int index=startPos;

//--- start index validation
   if(startPos<0) 
     {
      Print("Invalid parameter in the function iLowest, startPos =",startPos);
      return 0;
     }
   int size=ArraySize(array);

//--- depth correction if need
   if(startPos-depth<0) depth=startPos;
   double min=array[startPos];

//--- start searching
   for(int i=startPos; i>startPos-depth; i--) 
     {
      if(array[i]<min) 
        {
         index=i;
         min=array[i];
        }
     }

//--- return index of the lowest bar
   return(index);
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
   int i=0;
   int limit = 0, counterZ = 0, whatlookfor = 0;
   int shift = 0, back = 0, lasthighpos = 0, lastlowpos = 0;
   double val= 0,res = 0;
   double curlow=0,curhigh=0,lasthigh=0,lastlow=0;
   static double lastSignalHigh,lastSignalLow;

//--- auxiliary enumeration
   enum looling_for 
     {
      Pike = 1,  // searching for next high
      Sill = -1  // searching for next low
     };

//--- initializing
   if(prev_calculated==0) 
     {
      ArrayInitialize(ZigzagBuffer,0.0);
      ArrayInitialize(SignalLongBuffer,0.0);
      ArrayInitialize(SignalShortBuffer,0.0);
      ArrayInitialize(Level236, 0.0);
      ArrayInitialize(Level382, 0.0);
      ArrayInitialize(Level500, 0.0);
      ArrayInitialize(Level618, 0.0);
      ArrayInitialize(HighMapBuffer,0.0);
      ArrayInitialize(LowMapBuffer, 0.0);
     }

//--- 
   if(rates_total < 100) return(0);
//--- set start position for calculations
   if(prev_calculated==0) limit=ExtDepth;

//--- ZigZag was already counted before
   if(prev_calculated>0) 
     {
      i=rates_total-1;

      //--- searching third extremum from the last uncompleted bar
      while(counterZ<level && i>rates_total-100) 
        {
         res=ZigzagBuffer[i];
         if(res!=0) counterZ++;
         i--;
        }

      i++;
      limit=i;

      //--- what type of exremum we are going to find
      if(LowMapBuffer[i]!=0) 
        {
         curlow=LowMapBuffer[i];
         whatlookfor=Pike;
           } else {
         curhigh=HighMapBuffer[i];
         whatlookfor=Sill;
        }

      //--- chipping
      for(i=limit+1; i<rates_total && !IsStopped(); i++) 
        {
         ZigzagBuffer[i] = 0.0;
         LowMapBuffer[i] = 0.0;
         HighMapBuffer[i]= 0.0;
        }
     }

//--- searching High and Low
   for(shift=limit; shift<rates_total && !IsStopped(); shift++) 
     {
      val=low[iLowest(low,ExtDepth,shift)];
      if(val==lastlow) val=0.0;
      else 
        {
         lastlow=val;

         if((low[shift]-val)>deviation) val=0.0;
         else 
           {
            for(back=1; back<=ExtBackstep; back++) 
              {
               res=LowMapBuffer[shift-back];
               if((res!=0) && (res>val)) LowMapBuffer[shift-back]=0.0;
              }
           }
        }

      if(low[shift]==val) LowMapBuffer[shift]=val; else LowMapBuffer[shift]=0.0;

      //--- high
      val=high[iHighest(high,ExtDepth,shift)];
      if(val==lasthigh) val=0.0;

      else 
        {
         lasthigh=val;
         if((val-high[shift])>deviation) val=0.0;
         else 
           {
            for(back=1; back<=ExtBackstep; back++) 
              {
               res=HighMapBuffer[shift-back];
               if((res!=0) && (res<val)) HighMapBuffer[shift-back]=0.0;
              }
           }
        }

      if(high[shift]==val) HighMapBuffer[shift]=val; else HighMapBuffer[shift]=0.0;
     }

//--- last preparation
   if(whatlookfor==0) 
     { // uncertain quantity
      lastlow=0;
      lasthigh=0;
        } else {
      lastlow=curlow;
      lasthigh=curhigh;
     }

//--- final rejection
   for(shift=limit;shift<rates_total && !IsStopped(); shift++) 
     {
      res=0.0;
      switch(whatlookfor) 
        {
         case 0: // search for peak or lawn
            if(lastlow==0 && lasthigh==0) 
              {

               if(HighMapBuffer[shift]!=0) 
                 {
                  lasthigh=high[shift];
                  lasthighpos = shift;
                  whatlookfor = Sill;
                  ZigzagBuffer[shift]=lasthigh;
                  res=1;
                 }

               if(LowMapBuffer[shift]!=0) 
                 {
                  lastlow=low[shift];
                  lastlowpos=shift;
                  whatlookfor=Pike;
                  ZigzagBuffer[shift]=lastlow;
                  res=1;
                 }
              }
            break;

         case Pike: // search for peak

            if(LowMapBuffer[shift]!=0.0 && LowMapBuffer[shift]<lastlow && HighMapBuffer[shift]==0.0) 
              {
               ZigzagBuffer[lastlowpos]=0.0;
               lastlowpos=shift;
               lastlow=LowMapBuffer[shift];
               ZigzagBuffer[shift]=lastlow;
               res=1;
              }

            if(HighMapBuffer[shift]!=0.0 && LowMapBuffer[shift]==0.0) 
              {
               lasthigh=HighMapBuffer[shift];
               lasthighpos=shift;
               ZigzagBuffer[shift]=lasthigh;
               whatlookfor=Sill;
               res=1;

               //--- Fibo levels build low
               if(lastlow!=lastSignalLow) 
                 {
                  if(lasthigh) 
                    {
                     Level236[shift] = lastlow - getFiboLevel(lastSignalHigh, lastlow, 0.236);
                     Level382[shift] = lastlow - getFiboLevel(lastSignalHigh, lastlow, 0.382);
                     Level500[shift] = lastlow - getFiboLevel(lastSignalHigh, lastlow, 0.500);
                     Level618[shift] = lastlow - getFiboLevel(lastSignalHigh, lastlow, 0.618);
                    }
                  lastSignalLow=SignalShortBuffer[shift]=lastlow;
                 }
              }
            break;

         case Sill: // search for lawn
            if(HighMapBuffer[shift]!=0.0 && HighMapBuffer[shift]>lasthigh && LowMapBuffer[shift]==0.0) 
              {
               ZigzagBuffer[lasthighpos]=0.0;
               lasthighpos=shift;
               lasthigh=HighMapBuffer[shift];
               ZigzagBuffer[shift]=lasthigh;
              }

            if(LowMapBuffer[shift]!=0.0 && HighMapBuffer[shift]==0.0) 
              {

               lastlow=LowMapBuffer[shift];
               lastlowpos=shift;
               ZigzagBuffer[shift]=lastlow;
               whatlookfor=Pike;

               //--- Fibo levels build high
               if(lastlow && lasthigh!=lastSignalHigh) 
                 {
                  if(lastlow) 
                    {
                     Level236[shift] = lasthigh + getFiboLevel(lasthigh, lastSignalLow, 0.236);
                     Level382[shift] = lasthigh + getFiboLevel(lasthigh, lastSignalLow, 0.382);
                     Level500[shift] = lasthigh + getFiboLevel(lasthigh, lastSignalLow, 0.500);
                     Level618[shift] = lasthigh + getFiboLevel(lasthigh, lastSignalLow, 0.618);
                    }

                  lastSignalHigh=SignalLongBuffer[shift]=lasthigh;
                 }
              }

            break;

         default: return(rates_total);
        }
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate fibo-levels                                            |
//+------------------------------------------------------------------+
double getFiboLevel(double high,double low,double fibo) 
  {
   double range=(high-low)*fibo;
   return NormalizeDouble(range, Digits());

  }
//+------------------------------------------------------------------+
