//------------------------------------------------------------------

   #property copyright "mladen"
   #property link      "www.forex-tsd.com"

//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   4

#property indicator_label1  "Break values"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'221,247,221',clrMistyRose
#property indicator_label2  "Upper band"
#property indicator_type2   DRAW_LINE
#property indicator_color2  C'221,247,221'
#property indicator_width2  2
#property indicator_label3  "Lower band"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMistyRose
#property indicator_width3  2
#property indicator_label4  "Price"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrDimGray
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

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
enum enMaModes
{
   ma_Simple,  // Simple moving average
   ma_Expo     // Exponential moving average
};
enum enAtrMode
{
   atr_Rng,   // Calculate using range
   atr_Atr    // Calculate using ATR
};

//
//
//
//
//

input ENUM_TIMEFRAMES    TimeFrame       = PERIOD_CURRENT; // Time frame
input int                MAPeriod        = 20;             // Moving average period
input enMaModes          MAMethod        = ma_Simple;      // Moving average type
input enPrices           Price           = pr_typical;     // Moving average price 
input int                AtrPeriod       = 20;             // Range period
input double             AtrMultiplier   = 2.0;            // Range multiplier
input enAtrMode          AtrMode         = atr_Rng;        // Range calculating mode 
input bool               Interpolate     = true;           // Interpolate mtf data

//
//
//
//
//

double oscu[];
double oscd[];
double channelUp[];
double channelDn[];
double price[];
double countBuffer[];
ENUM_TIMEFRAMES timeFrame;
int             mtfHandle;
int             atrHandle;
bool            calculating;

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
   SetIndexBuffer(0,oscu,INDICATOR_DATA);
   SetIndexBuffer(1,oscd,INDICATOR_DATA);
   SetIndexBuffer(2,channelUp,INDICATOR_DATA);
   SetIndexBuffer(3,channelDn,INDICATOR_DATA);
   SetIndexBuffer(4,price,INDICATOR_DATA);
   SetIndexBuffer(5,countBuffer,INDICATOR_CALCULATIONS); 

   //
   //
   //
   //
   //
         
   timeFrame   = MathMax(_Period,TimeFrame);
   calculating = (timeFrame==_Period);
   if (!calculating)
         mtfHandle = iCustom(NULL,timeFrame,getIndicatorName(),PERIOD_CURRENT,MAPeriod,MAMethod,Price,AtrPeriod,AtrMultiplier,AtrMode);

   IndicatorSetString(INDICATOR_SHORTNAME,getPeriodToString(timeFrame)+" Keltner channel ("+string(MAPeriod)+","+string(AtrPeriod)+")");
   return(0);
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

   //
   //
   //
   //
   //
   
   if (calculating)
   {
         for (int i=(int)MathMax(prev_calculated-1,1); i<rates_total; i++)
         {
            double atr=0;
            for (int k=0; k<AtrPeriod && (i-k-1)>=0; k++)
               if (AtrMode==atr_Atr)
                     atr += MathMax(high[i-k],close[i-k-1])-MathMin(low[i-k],close[i-k-1]);
               else  atr += high[i-k]-low[i-k];
                     atr /= AtrPeriod;
            
               //
               //
               //
               //
               //

                  double tprice = getPrice(Price,open,close,high,low,i,rates_total);
                  double ma;
                  switch(MAMethod)
                  {
                     case ma_Simple: ma = iSma(tprice,MAPeriod,i,rates_total); break;
                     case ma_Expo:   ma = iEma(tprice,MAPeriod,i,rates_total); break;
                  }

               //
               //
               //
               //
               //
               
               price[i]     = tprice-ma;
               channelUp[i] = +atr*AtrMultiplier;
               channelDn[i] = -atr*AtrMultiplier;
                  oscu[i] = 0;
                  oscd[i] = 0;
                  if (price[i]>channelUp[i]) oscu[i] = channelUp[i];
                  if (price[i]<channelDn[i]) oscu[i] = channelDn[i];
         }      
         countBuffer[rates_total-1] = MathMax(rates_total-prev_calculated+1,1);
         return(rates_total);
   }
   
   //
   //
   //
   //
   //
   
   if (BarsCalculated(mtfHandle)<=0) return(0);
      datetime times[]; 
      datetime startTime = time[0]-PeriodSeconds(timeFrame);
      datetime endTime   = time[rates_total-1];
         int bars = CopyTime(NULL,timeFrame,startTime,endTime,times);
        
         if (times[0]>time[0] || bars<1 || bars>rates_total) return(rates_total);
               double toscu[]; CopyBuffer(mtfHandle,0,0,bars,toscu);
               double tchnu[]; CopyBuffer(mtfHandle,2,0,bars,tchnu);
               double tchnd[]; CopyBuffer(mtfHandle,3,0,bars,tchnd);
               double tpric[]; CopyBuffer(mtfHandle,4,0,bars,tpric);
               double count[]; CopyBuffer(mtfHandle,5,0,bars,count);
         int maxb = (int)MathMax(MathMin(count[bars-1]*PeriodSeconds(timeFrame)/PeriodSeconds(_Period),rates_total-1),1);

         //
         //
         //
         //
         //
         
         for(int i=(int)MathMax(prev_calculated-maxb,0); i<rates_total; i++)
         {
            int d = dateArrayBsearch(times,time[i],bars);
            if (d > -1 && d < bars)
            {
               oscd[i]      = 0;
               oscu[i]      = toscu[d];
               price[i]     = tpric[d];
               channelUp[i] = tchnu[d];
               channelDn[i] = tchnd[d];
            }
            if (!Interpolate) continue;
        
            //
            //
            //
            //
            //
         
            int j=MathMin(i+1,rates_total-1);

            if (d!=dateArrayBsearch(times,time[j],bars) || i==j)
            {
               int n,k;
                  for(n = 1; (i-n)> 0 && time[i-n] >= times[d] && n<(PeriodSeconds(timeFrame)/PeriodSeconds(_Period)); n++) continue;	
                  for(k = 1; (i-k)>=0 && k<n; k++)
                  {
                     price[i-k]     = price[i]     + (price[i-n]     - price[i]    )*(double)k/n;
                     channelUp[i-k] = channelUp[i] + (channelUp[i-n] - channelUp[i])*(double)k/n;
                     channelDn[i-k] = channelDn[i] + (channelDn[i-n] - channelDn[i])*(double)k/n;
                     if (oscu[i-k]!=0)
                     {
                        if (oscu[i-k]>0) oscu[i-k] = channelUp[i-k];
                        if (oscu[i-k]<0) oscu[i-k] = channelDn[i-k];
                     }
                  }                  
            }
            
         }

   //
   //
   //
   //
   //
   
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
double getPrice(enPrices pricet, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars)
{

   //
   //
   //
   //
   //
   
   if (pricet>=pr_haclose && pricet<=pr_haaverage)
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
         
         switch (pricet)
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
   
   switch (pricet)
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


//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double workSma[][2];
double iSma(double tprice, int period, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= bars) ArrayResize(workSma,bars); instanceNo *= 2;

   //
   //
   //
   //
   //
      
   workSma[r][instanceNo] = tprice;
   if (r>=period)
          workSma[r][instanceNo+1] = workSma[r-1][instanceNo+1]+(workSma[r][instanceNo]-workSma[r-period][instanceNo])/period;
   else { workSma[r][instanceNo+1] = 0; for(int k=0; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo];  
          workSma[r][instanceNo+1] /= (double)period; }
   return(workSma[r][instanceNo+1]);
}

//
//
//
//
//

double workEma[][1];
double iEma(double tprice, double period, int r, int bars, int instanceNo=0)
{
   if (ArraySize(workEma)!= bars) ArrayResize(workEma,bars);

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(tprice-workEma[r-1][instanceNo]);
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

string getIndicatorName()
{
   string progPath    = MQL5InfoString(MQL5_PROGRAM_PATH);
   string toFind      = "MQL5\\Indicators\\";
   int    startLength = StringFind(progPath,toFind)+StringLen(toFind);
         
         string indicatorName = StringSubstr(progPath,startLength);
                indicatorName = StringSubstr(indicatorName,0,StringLen(indicatorName)-4);
   return(indicatorName);
}

//
//
//
//
//
 
string getPeriodToString(int period)
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


//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

int dateArrayBsearch(datetime& times[], datetime toFind, int total)
{
   int mid   = 0;
   int first = 0;
   int last  = total-1;
   
   while (last >= first)
   {
      mid = (first + last) >> 1;
      if (toFind == times[mid] || (mid < (total-1) && (toFind > times[mid]) && (toFind < times[mid+1]))) break;
      if (toFind <  times[mid])
            last  = mid - 1;
      else  first = mid + 1;
   }
   return (mid);
}