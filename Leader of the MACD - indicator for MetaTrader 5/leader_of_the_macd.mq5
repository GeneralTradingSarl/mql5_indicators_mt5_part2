//------------------------------------------------------------------

   #property copyright "mladen"
   #property link      "www.forex-tsd.com"

//------------------------------------------------------------------

#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   3

#property indicator_label1  "Leader of the MACD"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'216,237,243',MistyRose
#property indicator_label2  "MACD"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  DeepSkyBlue,PaleVioletRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_label3  "MACD signal line"
#property indicator_type3   DRAW_LINE
#property indicator_color3  DarkGray
#property indicator_style3  STYLE_DASHDOTDOT

//
//
//
//
//

input ENUM_TIMEFRAMES    TimeFrame       = PERIOD_CURRENT; // Time frame
input int                FastEMAPeriod   = 12;             // Fast EMA period
input int                SlowEMAPeriod   = 26;             // Slow EMA period
input int                SignalEMAPeriod =  9;             // Signal EMA period
input ENUM_APPLIED_PRICE Price           = PRICE_CLOSE;    // Price to use
input bool               Interpolate     = true;           // Interpolate mtf data

//
//
//
//
//

double leader[];
double leaderz[];
double macd[];
double signal[];
double colorBuffer[];
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
   SetIndexBuffer(0,leader,INDICATOR_DATA);
   SetIndexBuffer(1,leaderz,INDICATOR_DATA);
   SetIndexBuffer(2,macd,INDICATOR_DATA);
   SetIndexBuffer(3,colorBuffer,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(4,signal,INDICATOR_DATA);
   SetIndexBuffer(5,countBuffer,INDICATOR_CALCULATIONS); 

   //
   //
   //
   //
   //
         
      timeFrame   = MathMax(_Period,TimeFrame);
      calculating = (timeFrame==_Period);
      if (!calculating)
            mtfHandle = iCustom(NULL,timeFrame,getIndicatorName(),PERIOD_CURRENT,FastEMAPeriod,SlowEMAPeriod,Price);

   IndicatorSetString(INDICATOR_SHORTNAME,getPeriodToString(timeFrame)+" Leader of the MACD ("+string(FastEMAPeriod)+","+string(SlowEMAPeriod)+","+string(SignalEMAPeriod)+")");
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

double work[][4];
#define _ema10   0
#define _ema11   1
#define _ema20   2
#define _ema21   3

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
      if (ArrayRange(work,0)<rates_total) ArrayResize(work,rates_total);

         double fastAlpha   = 2.0/(1.0+FastEMAPeriod);
         double slowAlpha   = 2.0/(1.0+SlowEMAPeriod);
         double signalAlpha = 2.0/(1.0+SignalEMAPeriod);
      
         //
         //
         //
         //
         //
         
         for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
         {
            double price = getPrice(Price,open,close,high,low,i);
            if (i==0)
            {
               work[i][_ema10] = price;
               work[i][_ema11] = price;
               work[i][_ema20] = price;
               work[i][_ema21] = price;
               macd[i]         = 0;
               signal[i]       = 0;
               continue;
            }
            work[i][_ema10] = work[i-1][_ema10]+fastAlpha*(price                -work[i-1][_ema10]);
            work[i][_ema11] = work[i-1][_ema11]+fastAlpha*(price-work[i][_ema10]-work[i-1][_ema11]);
            work[i][_ema20] = work[i-1][_ema20]+slowAlpha*(price                -work[i-1][_ema20]);
            work[i][_ema21] = work[i-1][_ema21]+slowAlpha*(price-work[i][_ema20]-work[i-1][_ema21]);
            macd[i]    = work[i][_ema10]-work[i][_ema20];
            leader[i]  = work[i][_ema11]-work[i][_ema21]+macd[i];
            signal[i]  = signal[i-1]+signalAlpha*(macd[i]-signal[i-1]);
            leaderz[i] = 0;

            //
            //
            //
            //
            //
            
            colorBuffer[i]=colorBuffer[i-1];
               if (macd[i]>macd[i-1]) colorBuffer[i]=0;
               if (macd[i]<macd[i-1]) colorBuffer[i]=1;
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
               double tlead[]; CopyBuffer(mtfHandle,0,0,bars,tlead);
               double tmacd[]; CopyBuffer(mtfHandle,2,0,bars,tmacd);
               double tcolo[]; CopyBuffer(mtfHandle,3,0,bars,tcolo);
               double tsign[]; CopyBuffer(mtfHandle,4,0,bars,tsign);
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
               macd[i]        = tmacd[d];
               signal[i]      = tsign[d];
               leader[i]      = tlead[d];
               colorBuffer[i] = tcolo[d];
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
                     macd[i-k]   = macd[i]   + (macd[i-n]   - macd[i]  )*(double)k/n;
                     signal[i-k] = signal[i] + (signal[i-n] - signal[i])*(double)k/n;
                     leader[i-k] = leader[i] + (leader[i-n] - leader[i])*(double)k/n;
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

double minValue(double& array[][6],int useValue, int period, int shift)
{
   double minValue = array[shift][useValue];
            for (int i=1; i<period && (shift-i)>=0; i++) minValue = MathMin(minValue,array[shift-i][useValue]);
   return(minValue);
}
double maxValue(double& array[][6],int useValue, int period, int shift)
{
   double maxValue = array[shift][useValue];
            for (int i=1; i<period && (shift-i)>=0; i++) maxValue = MathMax(maxValue,array[shift-i][useValue]);
   return(maxValue);
}


//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double getPrice(ENUM_APPLIED_PRICE price,const double& open[], const double& close[], const double& high[], const double& low[], int i)
{
   switch (price)
   {
      case PRICE_CLOSE:     return(close[i]);
      case PRICE_OPEN:      return(open[i]);
      case PRICE_HIGH:      return(high[i]);
      case PRICE_LOW:       return(low[i]);
      case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
      case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
      case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
   }
   return(0);
}
  
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