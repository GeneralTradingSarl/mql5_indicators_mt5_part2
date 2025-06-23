//+------------------------------------------------------------------+
//|                                               Stochastic RSI.mq5 |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "ww.forex-tsd.com"
#property version   "1.00"

#property indicator_separate_window
#property indicator_buffers   5
#property indicator_plots     2
#property indicator_label1  "Stochastic"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrDodgerBlue,clrSandyBrown
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_type2   DRAW_LINE
#property indicator_color2  DimGray
#property indicator_width2  2
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
   pr_haclose,    // Heiken ashi close
   pr_haopen ,    // Heiken ashi open
   pr_hahigh,     // Heiken ashi high
   pr_halow,      // Heiken ashi low
   pr_hamedian,   // Heiken ashi median
   pr_hatypical,  // Heiken ashi typical
   pr_haweighted, // Heiken ashi weighted
   pr_haaverage,  // Heiken ashi average
   pr_hamedianb,  // Heiken ashi median body
   pr_hatbiased   // Heiken ashi trend biased price
};

input int      inpRSIPeriod   = 14;               // RSI period
input enPrices inpPrice       = pr_close;         // RSI applied to price
input int      inpStoPeriod1  = 55;               // Stochastic period 1 (less than 2 - no stochastic)
input int      inpStoPeriod2  = 55;               // Stochastic period 2 (less than 2 - no stochastic)
input int      inpEMAPeriod   = 15;               // Smoothing period (less than 2 - no smoothing)
input double   inpUpLevel     = 80.0;             // Overbought level
input double   inpDnLevel     = 20.0;             // Oversold level
input color    inpLevelsColor = clrDarkSlateGray; // Levels color

//
//
//
//
//

double RsiBuffer[];
double StoBuffer[];
double StcBuffer[];
double StlBuffer[];
double LevBuffer[];
int    iRSIPeriod;
int    iStoPeriod1;
int    iStoPeriod2;
int    iEMAPeriod;
double iUpLevel;
double iDnLevel;

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
   SetIndexBuffer(0,StoBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,LevBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,StlBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,RsiBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,StcBuffer,INDICATOR_CALCULATIONS);

   //
   //
   //
   //
   //
   
      iRSIPeriod  = (inpRSIPeriod>0)  ? inpRSIPeriod  : 1;
      iEMAPeriod  = (inpEMAPeriod>0)  ? inpEMAPeriod  : 1;
      iStoPeriod1 = (inpStoPeriod1>0) ? inpStoPeriod1 : 1;
      iStoPeriod2 = (inpStoPeriod2>0) ? inpStoPeriod2 : 1;
      iUpLevel    = (inpUpLevel>inpDnLevel) ? inpUpLevel : inpDnLevel;
      iDnLevel    = (inpUpLevel<inpDnLevel) ? inpUpLevel : inpDnLevel;
     
      //
      //
      //
      //
      //

      IndicatorSetInteger(INDICATOR_LEVELS,2);
      IndicatorSetDouble(INDICATOR_LEVELVALUE,0,iUpLevel);
      IndicatorSetDouble(INDICATOR_LEVELVALUE,1,iDnLevel);
      IndicatorSetInteger(INDICATOR_LEVELCOLOR,inpLevelsColor);
   
   //
   //
   //
   //
   //
   
   string strSmooth = (iEMAPeriod>1) ? "smoothed " : "";
   string strStoch  = (iStoPeriod1>1 || iStoPeriod2>1) ? "stochastic " : "";
          strStoch  = (iStoPeriod1>1 && iStoPeriod2>1) ? "double stochastic " : strStoch;
   IndicatorSetString(INDICATOR_SHORTNAME,strSmooth+strStoch+"RSI("+(string)iRSIPeriod+","+(string)iStoPeriod1+","+(string)iStoPeriod2+","+(string)iEMAPeriod+")");
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

int _bars;
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
   double alpha = 2.0/(1.0+iEMAPeriod); _bars = rates_total;
      
   //
   //
   //
   //
   //
         
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      RsiBuffer[i] = iRsi(getPrice(inpPrice,open,close,high,low,i),iRSIPeriod,i,rates_total);
         if (iStoPeriod1>1)
         {
            double max = RsiBuffer[i]; for(int k=1; k<iStoPeriod1 && i-k>=0; k++) max = MathMax(max,RsiBuffer[i-k]);
            double min = RsiBuffer[i]; for(int k=1; k<iStoPeriod1 && i-k>=0; k++) min = MathMin(min,RsiBuffer[i-k]);
            StcBuffer[i] = 0;
            if (max!=min)
                  StcBuffer[i] = (RsiBuffer[i]-min)/(max-min)*100.00;
            else  StcBuffer[i] = 0;
         }
         else StcBuffer[i] = RsiBuffer[i];
         
         //
         //
         //
         //
         //
            
         double sto=StcBuffer[i];
         if (iStoPeriod2>1)
         {
            double max = StcBuffer[i]; for(int k=1; k<iStoPeriod2 && i-k>=0; k++) max = MathMax(max,StcBuffer[i-k]);
            double min = StcBuffer[i]; for(int k=1; k<iStoPeriod2 && i-k>=0; k++) min = MathMin(min,StcBuffer[i-k]);
            if (max!=min)
                  sto = (StcBuffer[i]-min)/(max-min)*100.00;
            else  sto = 0;                     
         }
         if (i>0)
         {
            StoBuffer[i] = StoBuffer[i-1]+alpha*(sto-StoBuffer[i-1]);
            StlBuffer[i] = StoBuffer[i];
            LevBuffer[i] = StoBuffer[i];
               if (StoBuffer[i]>iUpLevel) LevBuffer[i] = iUpLevel;
               if (StoBuffer[i]<iDnLevel) LevBuffer[i] = iDnLevel;
         }
         else StoBuffer[i]=sto;     
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
//

double workRsi[][3];
#define _price  0
#define _change 1
#define _changa 2

//
//
//
//

double iRsi(double price, double period, int i, int bars, int forInstance=0)
{
   if (ArrayRange(workRsi,0)!=bars) ArrayResize(workRsi,bars);
   int z    = forInstance*3; double alpha = 1.0 /(double)period; 

   //
   //
   //
   //
   //
   
      workRsi[i][_price+z] = price;
      if (i<period)
      {
         int k; double sum = 0; for (k=0; k<period && (i-k-1)>=0; k++) sum += MathAbs(workRsi[i-k][_price+z]-workRsi[i-k-1][_price+z]);
            workRsi[i][_change+z] = (workRsi[i][_price+z]-workRsi[0][_price+z])/MathMax(k,1);
            workRsi[i][_changa+z] =                                         sum/MathMax(k,1);
      }
      else
      {
         double change = workRsi[i][_price+z]-workRsi[i-1][_price+z];
            workRsi[i][_change+z] = workRsi[i-1][_change+z] + alpha*(        change  - workRsi[i-1][_change+z]);
            workRsi[i][_changa+z] = workRsi[i-1][_changa+z] + alpha*(MathAbs(change) - workRsi[i-1][_changa+z]);
      }
      if (workRsi[i][_changa+z] != 0)
            return(50.0*(workRsi[i][_change+z]/workRsi[i][_changa+z]+1));
      else  return(0);
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

double workHa[][4];
double getPrice(int tprice, const double& open[], const double& close[], const double& high[], const double& low[], int i, int instanceNo=0)
{
  if (tprice>=pr_haclose)
   {
      if (ArrayRange(workHa,0)!= _bars) ArrayResize(workHa,_bars); int r=i;
         
         //
         //
         //
         //
         //
         
         double haOpen;
         if (r>0)
                haOpen  = (workHa[r-1][instanceNo+2] + workHa[r-1][instanceNo+3])/2.0;
         else   haOpen  = (open[i]+close[i])/2;
         double haClose = (open[i] + high[i] + low[i] + close[i]) / 4.0;
         double haHigh  = MathMax(high[i], MathMax(haOpen,haClose));
         double haLow   = MathMin(low[i] , MathMin(haOpen,haClose));

         if(haOpen  <haClose) { workHa[r][instanceNo+0] = haLow;  workHa[r][instanceNo+1] = haHigh; } 
         else                 { workHa[r][instanceNo+0] = haHigh; workHa[r][instanceNo+1] = haLow;  } 
                                workHa[r][instanceNo+2] = haOpen;
                                workHa[r][instanceNo+3] = haClose;
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
   }
   return(0);
}   