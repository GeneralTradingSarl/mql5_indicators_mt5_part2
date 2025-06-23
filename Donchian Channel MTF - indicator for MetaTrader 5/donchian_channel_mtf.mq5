//+------------------------------------------------------------------+
//|                                             Daily Highs-Lows.mq5 |
//|                                                 Copyright mladen |
//|                                               mladenfx@gmail.com |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

//
//
//
//
//

#property indicator_label1  "High"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLimeGreen
#property indicator_style1  STYLE_DOT
#property indicator_width1  1

#property indicator_label2  "Low"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrOrange
#property indicator_style2  STYLE_DOT
#property indicator_width2  1


//
//
//
//
//

input ENUM_TIMEFRAMES inpPeriod      = PERIOD_CURRENT; // Time frame for highs/lows
input int             inpPeriodsBack = 20;             // Look back period

//
//
//
//
//

double HiBuffer[];
double LoBuffer[];

ENUM_TIMEFRAMES iPeriod;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,HiBuffer,INDICATOR_DATA); ArraySetAsSeries(HiBuffer,true);
   SetIndexBuffer(1,LoBuffer,INDICATOR_DATA); ArraySetAsSeries(LoBuffer,true);

   //
   //
   //
   //
   //
   
   iPeriod = (inpPeriod>=Period()) ? inpPeriod : Period();
      string timeFrameName = periodToString(iPeriod);
         IndicatorSetString(INDICATOR_SHORTNAME,timeFrameName+" highs/lows");
         PlotIndexSetString(0,PLOT_LABEL,timeFrameName+" high");
         PlotIndexSetString(1,PLOT_LABEL,timeFrameName+" low");
   return(0);
}

//
//
//
//
//

#define numRetries 5

//
//
//
//
//

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{

   //
   //
   //
   //
   //

   if (!ArrayGetAsSeries(time)) ArraySetAsSeries(time,true);
         MqlRates ratesArray[]; ArraySetAsSeries(ratesArray,true);
         
         int copiedRates=0;
         for (int i=0; i<numRetries;i++)
            if((copiedRates = CopyRates(Symbol(),iPeriod,time[rates_total-1],time[0],ratesArray))>0) break;
            if (copiedRates <= 0)
            {
               Print("not all rates copied. Will try on next tick");
               return(prev_calculated);
            }

      //
      //
      //
      //
      //

         int limit = rates_total-prev_calculated;
            if (prev_calculated > 0) limit++;
            if (prev_calculated ==0) limit--;

            int minutesPeriod = periodToMinutes(Period());
            int minutesChosen = periodToMinutes(iPeriod);

         limit = (limit>(3*minutesChosen/minutesPeriod)) ? limit : (3*minutesChosen/minutesPeriod);

      //
      //
      //
      //
      //
            
      for (int i=MathMin(limit,rates_total-2); i>=0 && !IsStopped(); i--)
      {
         int d = dateArrayBsearch(ratesArray,time[i]-minutesChosen*60,copiedRates);
         if (d >= 0)
            {
               HiBuffer[i] = ratesArray[d].high;
               LoBuffer[i] = ratesArray[d].low;
               for (int k=1; k <inpPeriodsBack && (d+k)<copiedRates; k++)
               {
                  HiBuffer[i] = MathMax(HiBuffer[i],ratesArray[d+k].high);
                  LoBuffer[i] = MathMin(LoBuffer[i],ratesArray[d+k].low);
               }
            }
         else
            {
               HiBuffer[i] = EMPTY_VALUE;
               LoBuffer[i] = EMPTY_VALUE;
            }
      }
   
   //
   //
   //
   //
   //

   return(rates_total);
}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int dateArrayBsearch(MqlRates& rates[], datetime toFind, int total)
{
   int mid   = 0;
   int first = 0;
   int last  = total-1;
   
   while (last >= first)
   {
      mid = (first + last) >> 1;
      if (toFind == rates[mid].time || (mid > 0 && (toFind > rates[mid].time) && (toFind < rates[mid-1].time))) break;
      if (toFind >  rates[mid].time)
            last  = mid - 1;
      else  first = mid + 1;
   }
   return (mid);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int periodToMinutes(int period)
{
   int i;
   static int _per[]={1,2,3,4,5,6,10,12,15,20,30,0x4001,0x4002,0x4003,0x4004,0x4006,0x4008,0x400c,0x4018,0x8001,0xc001};
   static int _min[]={1,2,3,4,5,6,10,12,15,20,30,60,120,180,240,360,480,720,1440,10080,43200};

   if (period==PERIOD_CURRENT) 
       period = Period();   
            for(i=0;i<20;i++) if(period==_per[i]) break;
   return(_min[i]);   
}

//
//
//
//
//

string periodToString(int period)
{
   int i;
   static int    _per[]={1,2,3,4,5,6,10,12,15,20,30,0x4001,0x4002,0x4003,0x4004,0x4006,0x4008,0x400c,0x4018,0x8001,0xc001};
   static string _tfs[]={"1 minute","2 minutes","3 minutes","4 minutes","5 minutes","6 minutes","10 minutes","12 minutes",
                         "15 minutes","20 minutes","30 minutes","1 hour","2 hours","3 hours","4 hours","6 hours","8 hours",
                         "12 hours","daily","weekly","monthly"};
   
   if (period==PERIOD_CURRENT) 
       period = Period();   
            for(i=0;i<20;i++) if(period==_per[i]) break;
   return(_tfs[i]);   
}
