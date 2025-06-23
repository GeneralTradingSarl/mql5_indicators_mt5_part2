//+------------------------------------------------------------------+
//|                                               Stochastic RSI.mq5 |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "www.forex-station.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers   8
#property indicator_plots     5
#property indicator_label1  "Stochastic"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrSandyBrown,clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label2  "Stochastic level up"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_DOT
#property indicator_label3  "Stochastic middle level"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrSilver
#property indicator_style3  STYLE_DOT
#property indicator_label4  "Stochastic level down"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrSandyBrown
#property indicator_style4  STYLE_DOT
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrSilver
#property indicator_width5  2
#property indicator_minimum  -1
#property indicator_maximum 101

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

input int      RSIPeriod   = 14;        // RSI period
input enPrices Price       = pr_close;  // RSI applied to price
input int      StoPeriod1  = 55;        // Stochastic period 1 (less than 2 - no stochastic)
input int      StoPeriod2  = 55;        // Stochastic period 2 (less than 2 - no stochastic)
input int      EMAPeriod   = 15;        // Smoothing period (less than 2 - no smoothing)
input int      flLookBack  = 25;        // Floating levels look back period
input double   flLevelUp   = 90;        // Floating levels up level %
input double   flLevelDown = 10;        // Floating levels down level %

//
//
//
//
//

double RsiBuffer[],StoBuffer[],StcBuffer[],StlBuffer[],LevBuffer[],levelup[],levelmi[],leveldn[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,LevBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,StlBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,levelup  ,INDICATOR_DATA);
   SetIndexBuffer(3,levelmi  ,INDICATOR_DATA);
   SetIndexBuffer(4,leveldn  ,INDICATOR_DATA);
   SetIndexBuffer(5,StoBuffer,INDICATOR_DATA);
   SetIndexBuffer(6,RsiBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(7,StcBuffer,INDICATOR_CALCULATIONS);

      string strSmooth = (EMAPeriod>1) ? "smoothed " : "";
      string strStoch  = (StoPeriod1>1 || StoPeriod2>1) ? "stochastic " : "";
             strStoch  = (StoPeriod1>1 && StoPeriod2>1) ? "double stochastic " : strStoch;
   IndicatorSetString(INDICATOR_SHORTNAME,strSmooth+strStoch+"RSI("+(string)RSIPeriod+","+(string)StoPeriod1+","+(string)StoPeriod2+","+(string)EMAPeriod+")");
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
         
   double alpha = 2.0/(1.0+EMAPeriod);
   int i=(int)MathMax(prev_calculated-1,0); for (; i<rates_total && !_StopFlag; i++)
   {
      RsiBuffer[i] = iRsi(getPrice(Price,open,close,high,low,i,rates_total),RSIPeriod,i,rates_total);
            double max = RsiBuffer[i]; for(int k=1; k<StoPeriod1 && i-k>=0; k++) max = MathMax(max,RsiBuffer[i-k]);
            double min = RsiBuffer[i]; for(int k=1; k<StoPeriod1 && i-k>=0; k++) min = MathMin(min,RsiBuffer[i-k]);
                         StcBuffer[i] = (max!=min) ? (RsiBuffer[i]-min)/(max-min)*100.00 : RsiBuffer[i];
         
            //
            //
            //
            //
            //
            
            max = StcBuffer[i]; for(int k=1; k<StoPeriod2 && i-k>=0; k++) max = MathMax(max,StcBuffer[i-k]);
            min = StcBuffer[i]; for(int k=1; k<StoPeriod2 && i-k>=0; k++) min = MathMin(min,StcBuffer[i-k]);
            double sto = (max!=min) ? (StcBuffer[i]-min)/(max-min)*100.00 : StcBuffer[i] ;

            StoBuffer[i] = (i>0) ? StoBuffer[i-1]+alpha*(sto-StoBuffer[i-1]) : sto;
               int start = MathMax(i-flLookBack+1,0);
                   min   = StoBuffer[ArrayMinimum(StoBuffer,start,flLookBack)];
                   max   = StoBuffer[ArrayMaximum(StoBuffer,start,flLookBack)];
                   double range = max-min;
               levelup[i] = min+flLevelUp  *range/100.0;
               leveldn[i] = min+flLevelDown*range/100.0;
               levelmi[i] = min+0.5*range;
               StlBuffer[i] = StoBuffer[i];
               LevBuffer[i] = StoBuffer[i];
                  if (StoBuffer[i]>levelup[i]) LevBuffer[i] = levelup[i];
                  if (StoBuffer[i]<leveldn[i]) LevBuffer[i] = leveldn[i];
   }
   return(i);
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

#define _rsiInstances     1
#define _rsiInstancesSize 3
double workRsi[][_rsiInstances*_rsiInstancesSize];
#define _price  0
#define _change 1
#define _changa 2

double iRsi(double price, double period, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(workRsi,0)!=bars) ArrayResize(workRsi,bars); int z = instanceNo*_rsiInstancesSize; 
   
   //
   //
   //
   //
   //
   
   if (period<=1) return(price);
   workRsi[r][z+_price] = price;
         double alpha = 1.0/period; 
         if (r<period)
            {
               int k; double sum = 0; for (k=0; k<period && (r-k-1)>=0; k++) sum += MathAbs(workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price]);
                  workRsi[r][z+_change] = (workRsi[r][z+_price]-workRsi[0][z+_price])/MathMax(k,1);
                  workRsi[r][z+_changa] =                                         sum/MathMax(k,1);
            }
         else
            {
               double change = workRsi[r][z+_price]-workRsi[r-1][z+_price];
                               workRsi[r][z+_change] = workRsi[r-1][z+_change] + alpha*(        change  - workRsi[r-1][z+_change]);
                               workRsi[r][z+_changa] = workRsi[r-1][z+_changa] + alpha*(MathAbs(change) - workRsi[r-1][z+_changa]);
            }
            return(50.0*(workRsi[r][z+_change]/MathMax(workRsi[r][z+_changa],DBL_MIN)+1));
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