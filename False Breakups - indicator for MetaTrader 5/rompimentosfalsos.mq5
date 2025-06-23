//+------------------------------------------------------------------+
//|                                            RompimentosFalsos.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 6
#property indicator_plots   6

#property indicator_label1 "Buy"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_width1  5

#property indicator_label2 "Sell"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  5

#property indicator_label3 "Support"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrBlue

#property indicator_label4 "Resitance"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrRed

#property indicator_label5 "Bottom"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrRed

#property indicator_label6 "Top"
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrBlue
//+------------------------------------------------------------------+
//| Globas                                                           |
//+------------------------------------------------------------------+
double ExtResistancesBuffer[];
double ExtSupportsBuffer[];
double ExtTopsBuffer[];
double ExtBottomsBuffer[];
double ExtSellBuffer[];
double ExtBuyBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtBuyBuffer);
   SetIndexBuffer(1,ExtSellBuffer);
   SetIndexBuffer(2,ExtSupportsBuffer);
   SetIndexBuffer(3,ExtResistancesBuffer);
   SetIndexBuffer(4,ExtBottomsBuffer);
   SetIndexBuffer(5,ExtTopsBuffer);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);

   PlotIndexSetInteger(0,PLOT_ARROW,233);
   PlotIndexSetInteger(1,PLOT_ARROW,234);

   PlotIndexSetInteger(0,PLOT_ARROW_SHIFT,+10);
   PlotIndexSetInteger(1,PLOT_ARROW_SHIFT,-10);
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
//---
   if(prev_calculated == rates_total)
      return rates_total;

   if(prev_calculated == 0)
     {
      ArrayInitialize(ExtResistancesBuffer,0);
      ArrayInitialize(ExtSupportsBuffer,0);
      ArrayInitialize(ExtTopsBuffer,0);
      ArrayInitialize(ExtBottomsBuffer,0);
      ArrayInitialize(ExtSellBuffer,0);
      ArrayInitialize(ExtBuyBuffer,0);
     }
   if(prev_calculated == rates_total -1)
     {
      const int currentIndex = rates_total -1;
      ExtResistancesBuffer[currentIndex] = 0;
      ExtSupportsBuffer   [currentIndex] = 0;
      ExtTopsBuffer       [currentIndex] = 0;
      ExtBottomsBuffer    [currentIndex] = 0;
      ExtSellBuffer       [currentIndex] = 0;
      ExtBuyBuffer        [currentIndex] = 0;
     }

   int limit = prev_calculated -1;
   if(limit < 2)
      limit = 2;

   int i0, i1, i2;
   static double lastTop = 0, lastBottom = 0;

   for(int i=limit;i<rates_total-1;i++)
     {
      i0 = i;
      i1 = i -1;
      i2 = i -2;

      ExtTopsBuffer[i1] = 0;
      ExtBottomsBuffer[i1] = 0;
      ExtTopsBuffer[i0] = 0;
      ExtBottomsBuffer[i0] = 0;


#define IS_TOP (high[i2] < high[i1] && high[i1] > high[i0])
      if(IS_TOP)
        {
         lastTop = high[i1];
         ExtTopsBuffer[i1] = lastTop;
         ExtResistancesBuffer[i1] = lastTop;
        }

#define IS_BOTTOM (low[i2] > low[i1] && low[i1] < low[i0])
      if(IS_BOTTOM)
        {
         lastBottom = low[i1];
         ExtBottomsBuffer[i1] = lastBottom;
         ExtSupportsBuffer[i1] = lastBottom;
        }

      ExtResistancesBuffer[i0] = lastTop;
      ExtSupportsBuffer[i0] = lastBottom;

      //show arrows
      if(IsSell(ExtTopsBuffer,close,i0,rates_total))
        {
         ExtSellBuffer[i0] = high[i0];
        }
      if(IsBuy(ExtBottomsBuffer,close,i0,rates_total))
        {
         ExtBuyBuffer[i0] = low[i0];
        }
     }

   const int currentIndex = rates_total -1;
   ExtResistancesBuffer[currentIndex] = lastTop;
   ExtSupportsBuffer   [currentIndex] = lastBottom;

   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int IndexNextPoint(const double &buffer[], const int initial_index, const int rates_total)
  {
   for(int i=initial_index-1; i >= 0; i--)
     {
      if(buffer[i] != 0)
         return i;
     }
   return 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBuy(const double &points[], const double &close[], const int i, const int rates_total)
  {
   if(i < 2)
      return false;
   int iPoint;
   iPoint = IndexNextPoint(points,i,rates_total);
   if(iPoint == 0)
      return false;
   const double point = points[iPoint];

   int step = 0;

   for(int x=i; x>iPoint; x--)
     {
      const double c = close[x];

      if(x == i)
         if(c > point)
           {
            step = 1;
            continue;
           }
         else
            return false;

      if(step == 1)
         if(c < point)
           {
            step = 2;
            continue;
           }
         else
            if(c > point)
               return false;

      if(step == 2 && c > point)
        {
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSell(const double &points[], const double &close[], const int i, const int rates_total)
  {
   if(i < 2)
      return false;
   int iPoint;
   iPoint = IndexNextPoint(points,i,rates_total);
   if(iPoint == 0)
      return false;
   const double point = points[iPoint];

   int step = 0;

   for(int x=i; x>iPoint; x--)
     {
      const double c = close[x];

      if(x == i)
         if(c < point)
           {
            step = 1;
            continue;
           }
         else
            return false;

      if(step == 1)
         if(c > point)
           {
            step = 2;
            continue;
           }
         else
            if(c < point)
               return false;

      if(step == 2 && c < point)
        {
         return true;
        }
     }
   return false;
  }
//+------------------------------------------------------------------+
