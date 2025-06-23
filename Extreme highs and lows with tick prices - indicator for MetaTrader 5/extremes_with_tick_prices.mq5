//+------------------------------------------------------------------+
//|                             Higher High Lower Low with ticks.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_label1  "Extreme highs"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrChartreuse
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "Extreme lows"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrChartreuse
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

//--- input parameters
input int length = 10; // Length
input bool show_BoS = false; // Lines should keep drawing on BoS
input int start = 200; // Lookback bars


//--- indicator buffers
double HighBuffer[];
double LowBuffer[];

double TickPriceAsk[], TickPriceBid[];


MqlTick ticks[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,HighBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,LowBuffer,INDICATOR_DATA);

   ArraySetAsSeries(HighBuffer, true);
   ArraySetAsSeries(LowBuffer, true);
   
   ChartNavigate(0, CHART_END);

   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
  }
  
  
int ticksReceived = 0;
   
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
  
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(TickPriceAsk, true);
   ArraySetAsSeries(TickPriceBid, true);
   

   for(int i = start; i >= 0; i--)
     {
      double highestAsk = -DBL_MAX, lowestBid = DBL_MAX;

      datetime fromTime = iTime(Symbol(), Period(), MathMin(start - i, length));

      int range = CopyTicksRange(Symbol(), ticks, COPY_TICKS_INFO, fromTime * 1000, TimeCurrent() * 1000);

      ticksReceived = range;
      
      if(range > 0)
        {
         ArrayResize(TickPriceAsk, range);
         ArrayResize(TickPriceBid, range);

         for(int i = 0; i < range; i++)
           {

            TickPriceAsk[i] = ticks[i].ask;
            TickPriceBid[i] = ticks[i].bid;
           }    
        }
        
      double highestHigh = high[i];
      double lowestLow = low[i];

      for(int j = 1; j < length; j++)
        {
         if(high[i + j] > highestHigh)
            highestHigh = high[i + j]; // update highest high

         if(low[i + j] < lowestLow)
            lowestLow = low[i + j]; // update lowest low
        }

      for(int i = 0; i < range; i++)
        {
         if(highestAsk < TickPriceAsk[i])
            highestAsk = TickPriceAsk[i];
         if(lowestBid > TickPriceBid[i])
            lowestBid = TickPriceBid[i];
        }
      
      // Assign the highest and lowest values to the buffers
      HighBuffer[i] = MathMax(highestHigh, highestAsk);
      LowBuffer[i] = MathMin(lowestLow, lowestBid);

      // Stop drawing extremum lines when there's a break of market structure
      if(!show_BoS)
        {
         if(HighBuffer[i] != HighBuffer[i + 1])
            HighBuffer[i + 1] = EMPTY_VALUE;
         if(LowBuffer[i] != LowBuffer[i + 1])
            LowBuffer[i + 1] = EMPTY_VALUE;
        }

      ArrayRemove(TickPriceAsk, 0, WHOLE_ARRAY);
      ArrayRemove(TickPriceBid, 0, WHOLE_ARRAY);
     }

   for(int i = rates_total - 1; i >= start; i--)
     {
      HighBuffer[i] = EMPTY_VALUE;
      LowBuffer[i] = EMPTY_VALUE;
     }
       
     Comment("Ticks received: ", ticksReceived);


   return (rates_total);
}

