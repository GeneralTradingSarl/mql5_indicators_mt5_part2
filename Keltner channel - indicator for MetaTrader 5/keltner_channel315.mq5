//------------------------------------------------------------------

   #property copyright "mladen"
   #property link      "www.forex-tsd.com"

//------------------------------------------------------------------

#property indicator_chart_window
#property indicator_buffers 10
#property indicator_plots   4

#property indicator_label1  "Average"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrDeepSkyBlue,clrPaleVioletRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label2  "Upper band"
#property indicator_type2   DRAW_LINE
#property indicator_color2  C'216,237,243'
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2
#property indicator_label3  "Lower band"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrMistyRose
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2
#property indicator_label4  "Keltner MA trend"
#property indicator_type4   DRAW_COLOR_BARS
#property indicator_color4  clrDeepSkyBlue,clrPaleVioletRed
#property indicator_style4  STYLE_SOLID

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
enum enMaVisble
{
   mv_Visible,    // Middle line visible
   mv_NotVisible  // Middle line not visible
};

//
//
//
//
//

enum enCandleMode
{
   cm_None,   // Do not draw candles nor bars
   cm_Bars,   // Draw as bars
   cm_Candles // Draw as candles
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
input enMaVisble         MAVisible       = mv_Visible;     // Midlle line visible ?
input enPrices           Price           = pr_typical;     // Moving average price 
input color              MaColorUp       = clrDeepSkyBlue; // Color for slope up
input color              MaColorDown     = clrPaleVioletRed; // Color for slope down
input int                AtrPeriod       = 20;             // Range period
input double             AtrMultiplier   = 2.0;            // Range multiplier
input enAtrMode          AtrMode         = atr_Rng;        // Range calculating mode 
input enCandleMode       ViewBars        = cm_None;        // View bars as :
input bool               Interpolate     = true;           // Interpolate mtf data

//
//
//
//
//

double channelBo[];
double channelBh[];
double channelBl[];
double channelBc[];
double channelUp[];
double channelDn[];
double ma[];
double colorBuffer[];
double colorBufferb[];
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
   SetIndexBuffer(0,ma,INDICATOR_DATA);
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(2,channelUp,INDICATOR_DATA);
   SetIndexBuffer(3,channelDn,INDICATOR_DATA);
   SetIndexBuffer(4,channelBo,INDICATOR_DATA); 
   SetIndexBuffer(5,channelBh,INDICATOR_DATA);
   SetIndexBuffer(6,channelBl,INDICATOR_DATA);
   SetIndexBuffer(7,channelBc,INDICATOR_DATA);
   SetIndexBuffer(8,colorBufferb,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(9,countBuffer,INDICATOR_CALCULATIONS); 

   int type = DRAW_NONE;
         if (ViewBars== cm_Bars)    type = DRAW_COLOR_BARS;
         if (ViewBars== cm_Candles) type = DRAW_COLOR_CANDLES;
               PlotIndexSetInteger(3,PLOT_DRAW_TYPE,type);

         if (MAVisible==mv_NotVisible)
         {
            PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,clrNONE);
            PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,clrNONE);
         }               
         else
         {
            PlotIndexSetInteger(0,PLOT_LINE_COLOR,0,MaColorUp);
            PlotIndexSetInteger(0,PLOT_LINE_COLOR,1,MaColorDown);
         }               
         

   //
   //
   //
   //
   //
         
   timeFrame   = MathMax(_Period,TimeFrame);
   calculating = (timeFrame==_Period);
   if (!calculating)
         mtfHandle = iCustom(NULL,timeFrame,getIndicatorName(),PERIOD_CURRENT,MAPeriod,MAMethod,MAVisible,Price,MaColorUp,MaColorDown,AtrPeriod,AtrMultiplier,AtrMode);

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

                  double price = getPrice(Price,open,close,high,low,i,rates_total);
                  switch(MAMethod)
                  {
                     case ma_Simple: ma[i] = iSma(price,MAPeriod,i,rates_total); break;
                     case ma_Expo:   ma[i] = iEma(price,MAPeriod,i,rates_total); break;
                  }

               //
               //
               //
               //
               //
               
               colorBuffer[i] = colorBuffer[i-1];
                  if (ma[i]>ma[i-1]) colorBuffer[i]=0;
                  if (ma[i]<ma[i-1]) colorBuffer[i]=1;
               colorBufferb[i] = colorBuffer[i];
               channelUp[i] = ma[i]+atr*AtrMultiplier;
               channelDn[i] = ma[i]-atr*AtrMultiplier;
               channelBo[i] = open[i];
               channelBh[i] = high[i];
               channelBl[i] = low[i];
               channelBc[i] = close[i];
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
               double tma[];   CopyBuffer(mtfHandle,0,0,bars,tma);
               double tcolo[]; CopyBuffer(mtfHandle,1,0,bars,tcolo);
               double tchnu[]; CopyBuffer(mtfHandle,2,0,bars,tchnu);
               double tchnd[]; CopyBuffer(mtfHandle,3,0,bars,tchnd);
               double count[]; CopyBuffer(mtfHandle,9,0,bars,count);
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
               ma[i]           = tma[d];
               channelUp[i]    = tchnu[d];
               channelDn[i]    = tchnd[d];
               colorBuffer[i]  = tcolo[d];
               colorBufferb[i] = tcolo[d];
                  channelBo[i] = open[i];
                  channelBh[i] = high[i];
                  channelBl[i] = low[i];
                  channelBc[i] = close[i];
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
                     ma[i-k]        = ma[i]        + (ma[i-n]        - ma[i]       )*(double)k/n;
                     channelUp[i-k] = channelUp[i] + (channelUp[i-n] - channelUp[i])*(double)k/n;
                     channelDn[i-k] = channelDn[i] + (channelDn[i-n] - channelDn[i])*(double)k/n;
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


//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double workSma[][2];
double iSma(double price, int period, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= bars) ArrayResize(workSma,bars); instanceNo *= 2;

   //
   //
   //
   //
   //
      
   workSma[r][instanceNo] = price;
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
double iEma(double price, double period, int r, int bars, int instanceNo=0)
{
   if (ArraySize(workEma)!= bars) ArrayResize(workEma,bars);

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
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