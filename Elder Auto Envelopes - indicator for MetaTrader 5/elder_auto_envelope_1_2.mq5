//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"

#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   5

#property indicator_label1  "Envelope fill"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrDeepSkyBlue,clrSandyBrown
#property indicator_label2  "Ema"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrDeepSkyBlue,clrSandyBrown
#property indicator_width2  2
#property indicator_label3  "Fast ema"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGray
#property indicator_label4  "Upper band"
#property indicator_type4   DRAW_LINE
#property indicator_style4  STYLE_DASHDOTDOT
#property indicator_color5  clrDimGray
#property indicator_label5  "Lower band"
#property indicator_type5   DRAW_LINE
#property indicator_style5  STYLE_DASHDOTDOT
#property indicator_color5  clrDimGray

//
//
//
//
//

enum enPrices
{
   pr_close,      // Close
   pr_open,       // Open
   pr_high,       // High
   pr_low,        // Low
   pr_median,     // Median
   pr_typical,    // Typical
   pr_weighted,   // Weighted
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage   // Heiken ashi average
};
input int      EmaPeriod        = 21;
input int      FastEmaPeriod    = 13;
input enPrices Price            = pr_close;
input double   DeviationsFactor = 2.7;   // Original was 2.7 best for stock markets
input int      DeviationsPeriod = 100;

//
//
//
//
//

double slowEma[];
double slowEmaColor[];
double fastEma[];
double envelopeUp[];
double envelopeDn[],fillup[],filldn[];

//+------------------------------------------------------------------+
//|                                                                  |
//|------------------------------------------------------------------|
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,fillup      ,INDICATOR_DATA);
   SetIndexBuffer(1,filldn      ,INDICATOR_DATA);
   SetIndexBuffer(2,slowEma     ,INDICATOR_DATA);
   SetIndexBuffer(3,slowEmaColor,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,fastEma     ,INDICATOR_DATA);
   SetIndexBuffer(5,envelopeUp  ,INDICATOR_DATA);
   SetIndexBuffer(6,envelopeDn  ,INDICATOR_DATA);
   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

double work[][2];
#define _percp 0
#define _devs  1

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
   if (ArrayRange(work,0) != rates_total) ArrayResize(work,rates_total); 

   //
   //
   //
   //
   //

   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
   {
      double price = getPrice(Price,open,close,high,low,i,rates_total);
      double ema   = iEma(price,EmaPeriod,i,rates_total,0); 
      double bullp = MathAbs(high[i]-ema);
      double bearp = MathAbs(low[i] -ema);
      double maxp  = MathMax(bullp,bearp);
      work[i][_percp] = maxp/ema;
      work[i][_devs]  = work[(int)MathMax(i-1,0)][_devs];
         
         //
         //
         //
         //
         //

            MqlDateTime curTime,prevTime; TimeToStruct(time[i],curTime); TimeToStruct((int)MathMax(i-1,0),prevTime); 
            if (curTime.day_of_week<prevTime.day_of_week || _Period>PERIOD_W1)
            {
               double avg = 0;
               double sum = 0;
               for (int k=0; k<DeviationsPeriod && (i-k-1)>=0; k++) avg += work[i-k-1][_percp];
                                                                    avg /= DeviationsPeriod;
               for (int k=0; k<DeviationsPeriod && (i-k-1)>=0; k++) sum += (work[i-k-1][_percp]-avg)*(work[i-k-1][_percp]-avg);
            
               //
               //
               //
               //
               //
               
               work[i][_devs] = MathSqrt(sum/DeviationsPeriod);
            }
    
         //
         //
         //
         //
         //
      
         slowEma[i]    = ema;
         envelopeUp[i] = ema*(1+(DeviationsFactor*work[i][_devs]));
         envelopeDn[i] = ema*(1-(DeviationsFactor*work[i][_devs]));
            if (FastEmaPeriod>0)
            {
               fastEma[i] = iEma(price,FastEmaPeriod,i,rates_total,1);
               if (fastEma[i]>slowEma[i]) slowEmaColor[i] = 0;
               if (fastEma[i]<slowEma[i]) slowEmaColor[i] = 1;
                  fillup[i] = fastEma[i];
                  filldn[i] = slowEma[i];
            }               
   }
   return(rates_total);         
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//


double workHa[][4];
double getPrice(enPrices price, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars)
{

   //
   //
   //
   //
   //
   
   if (price>=pr_haclose && price<=pr_haaverage)
   {
      if (ArrayRange(workHa,0)!= bars) ArrayResize(workHa,bars);

         //
         //
         //
         //
         //
         
         double haOpen;
         if (i>0)
                haOpen  = (workHa[i-1][2] + workHa[i-1][3])/2.0;
         else   haOpen  = open[i]+close[i];
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[i][0] = haLow;  workHa[i][1] = haHigh; } 
         else                 { workHa[i][0] = haHigh; workHa[i][1] = haLow;  } 
                                workHa[i][2] = haOpen;
                                workHa[i][3] = haClose;
         //
         //
         //
         //
         //
         
         switch (price)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (price)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
   }
   return(0);
}

//
//
//
//
//

double workEma[][2];
double iEma(double price, double period, int r, int totalBars, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= totalBars) ArrayResize(workEma,totalBars);
   
   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
   if (r<1)
          workEma[r][instanceNo] = price;
   else   workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}
