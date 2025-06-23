//------------------------------------------------------------------
#property copyright   "www.forex-tsd.com"
#property link        "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
#property indicator_label1  "MACD"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrGray,clrLimeGreen,clrSandyBrown
#property indicator_label2  "corrected macd"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrGray,clrLimeGreen,clrSandyBrown
#property indicator_width2  2

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
   pr_average,    // Average (high+low+open+close)/4
   pr_medianb,    // Average median body (open+close)/2
   pr_tbiased,    // Trend biased price
   pr_tbiased2,   // Trend biased (extreme) price
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased,  // Heiken ashi trend biased price
   pr_hatbiased2  // Heiken ashi trend biased (extreme) price
};
enum enColorOn
{
   cc_onSlope, // Change color on slope change
   cc_onZero,  // Change color zero cross
   cc_onOrig   // Change color original macd value cross
};

input int       FastEMA          = 12;        // Fast EMA period
input int       SlowEMA          = 26;        // Slow EMA period
input int       CorrectionPeriod =  0;        // Correction period (<0 no correction =0 same as slow EMA)
input enPrices  Price            = pr_close;  // Price
input enColorOn ColorOn          = cc_onOrig; // Color change on :

double  macd[],macdc[],corrm[],corrmc[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void OnInit()
{
   SetIndexBuffer(0,macd  ,INDICATOR_DATA);
   SetIndexBuffer(1,macdc ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,corrm ,INDICATOR_DATA);
   SetIndexBuffer(3,corrmc,INDICATOR_COLOR_INDEX);
      IndicatorSetString(INDICATOR_SHORTNAME,"\"Corrected\" MACD ("+string(FastEMA)+","+string(SlowEMA)+","+string(CorrectionPeriod)+")");
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
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
   if (Bars(_Symbol,_Period)<rates_total) return(-1);
   
   //
   //
   //
   //
   //
   
   int deviationsPeriod = (CorrectionPeriod>0) ? CorrectionPeriod : (CorrectionPeriod<0) ? 0 : (int)SlowEMA ;
   int colorOn          = (deviationsPeriod>0) ? ColorOn : (ColorOn!=cc_onOrig) ? ColorOn : cc_onSlope;
   int i=(int)MathMax(prev_calculated-1,0); for (; i<rates_total && !_StopFlag; i++)
   {
         double price = getPrice(Price,open,close,high,low,i,rates_total);
            macd[i]   = iEma(price,FastEMA,i,rates_total,0)-iEma(price,SlowEMA,i,rates_total,1);
               double v1 =         MathPow(iDeviation(macd[i],deviationsPeriod,false,i,rates_total),2);
               double v2 = (i>0) ? MathPow(corrm[i-1]-macd[i],2) : 0;
               double c  = (v2<v1 || v2==0) ? 0 : 1-v1/v2;
            corrm[i]  = (i>0) ? corrm[i-1]+c*(macd[i]-corrm[i-1]) : macd[i];
            macdc[i]  = (i>0) ? (macd[i]>macd[i-1]) ? 1 : (macd[i]<macd[i-1]) ? 2 : macdc[i-1]: 0;
            switch (colorOn)
            {
               case cc_onOrig : corrmc[i] = (corrm[i]<macd[i]) ? 1 : (corrm[i]>macd[i]) ? 2 : (i>0) ? corrmc[i-1]: 0; break;
               case cc_onZero : corrmc[i] = (corrm[i]>0)       ? 1 : (corrm[i]<0)       ? 2 : (i>0) ? corrmc[i-1]: 0; break;
               default :        corrmc[i] = (i>0) ? (corrm[i]>corrm[i-1]) ? 1 : (corrm[i]<corrm[i-1]) ? 2 : corrmc[i-1]: 0;
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

double workDev[];
double iDeviation(double value, int length, bool isSample, int i, int bars)
{
   if (ArraySize(workDev)!=bars) ArrayResize(workDev,bars); workDev[i] = value;
                 
   //
   //
   //
   //
   //
   
      double oldMean   = value;
      double newMean   = value;
      double squares   = 0; int k;
      for (k=1; k<length && (i-k)>=0; k++)
      {
         newMean  = (workDev[i-k]-oldMean)/(k+1)+oldMean;
         squares += (workDev[i-k]-oldMean)*(workDev[i-k]-newMean);
         oldMean  = newMean;
      }
      return(MathSqrt(squares/MathMax(k-isSample,1)));
}

//
//
//
//
//

#define _emaInstances 2
double workEma[][_emaInstances];
double iEma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= _bars) ArrayResize(workEma,_bars);

   workEma[r][instanceNo] = price;
   if (r>0 && period>1)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//
//

#define _pricesInstances 1
#define _pricesSize      4
double workHa[][_pricesInstances*_pricesSize];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i,int _bars, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= _bars) ArrayResize(workHa,_bars); instanceNo*=_pricesSize;
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (i>0)
                haOpen  = (workHa[i-1][instanceNo+2] + workHa[i-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[i][instanceNo+0] = haLow;  workHa[i][instanceNo+1] = haHigh; } 
         else                 { workHa[i][instanceNo+0] = haHigh; workHa[i][instanceNo+1] = haLow;  } 
                                workHa[i][instanceNo+2] = haOpen;
                                workHa[i][instanceNo+3] = haClose;
         //
         //
         //
         //
         //
         
         switch (tprice)
         {
            case pr_haclose:     return(haClose);
            case pr_haopen:      return(haOpen);
            case pr_hahigh:      return(haHigh);
            case pr_halow:       return(haLow);
            case pr_hamedian:    return((haHigh+haLow)/2.0);
            case pr_hamedianb:   return((haOpen+haClose)/2.0);
            case pr_hatypical:   return((haHigh+haLow+haClose)/3.0);
            case pr_haweighted:  return((haHigh+haLow+haClose+haClose)/4.0);
            case pr_haaverage:   return((haHigh+haLow+haClose+haOpen)/4.0);
            case pr_hatbiased:
               if (haClose>haOpen)
                     return((haHigh+haClose)/2.0);
               else  return((haLow+haClose)/2.0);        
            case pr_hatbiased2:
               if (haClose>haOpen)  return(haHigh);
               if (haClose<haOpen)  return(haLow);
                                    return(haClose);        
         }
   }
   
   //
   //
   //
   //
   //
   
   switch (tprice)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_medianb:   return((open[i]+close[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
      case pr_tbiased:   
               if (close[i]>open[i])
                     return((high[i]+close[i])/2.0);
               else  return((low[i]+close[i])/2.0);        
      case pr_tbiased2:   
               if (close[i]>open[i]) return(high[i]);
               if (close[i]<open[i]) return(low[i]);
                                     return(close[i]);        
   }
   return(0);
}