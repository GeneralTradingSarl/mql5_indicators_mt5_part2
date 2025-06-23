//+------------------------------------------------------------------+
//|                                                    Guppy MMA.mq5 |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "wwww.forex-tsd.com"


#property indicator_chart_window
#property indicator_buffers 12
#property indicator_plots   12

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
   pr_average     // Average (high+low+oprn+close)/4
};

input enPrices Price     = pr_close;     // Price to use
input color    ColorFrom = clrLimeGreen; // Starting color for MAs
input color    ColorTo   = clrRed;       // Ending color for MAs

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//

struct simpleMa { double buffer[]; };
       simpleMa aBuffers[12];
int steps;
int periods[] = {3,5,8,10,12,15,30,35,40,45,50,60};

//
//
//
//
//

int OnInit()
{
       steps     = ArraySize(periods);

       for (int i=0;i<steps; i++)
       {
            SetIndexBuffer(i,aBuffers[i].buffer,INDICATOR_DATA);
            PlotIndexSetInteger(i,PLOT_DRAW_TYPE ,DRAW_LINE);
            PlotIndexSetInteger(i,PLOT_COLOR_INDEXES,1);
            PlotIndexSetInteger(i,PLOT_LINE_COLOR,gradientColor(i,steps,ColorFrom,ColorTo));
            PlotIndexSetString(i,PLOT_LABEL,"Guppy MA "+IntegerToString(periods[i]));
       }

   IndicatorSetString(INDICATOR_SHORTNAME,"Guppy MMA");
   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
   for (int i=(int)MathMax(prev_calculated-1,1); i<rates_total; i++)
   {  
      double price = getPrice(Price,open,close,high,low,i,rates_total);
            for (int k=0; k<steps; k++) 
                     aBuffers[k].buffer[i] = iDsema(price,periods[k],i, rates_total,k);
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

double getPrice(enPrices price, const double& open[], const double& close[], const double& high[], const double& low[], int i, int bars)
{
   switch (price)
   {
      case pr_close:     return(close[i]);
      case pr_open:      return(open[i]);
      case pr_high:      return(high[i]);
      case pr_low:       return(low[i]);
      case pr_median:    return((high[i]+low[i])/2.0);
      case pr_typical:   return((high[i]+low[i]+close[i])/3.0);
      case pr_weighted:  return((high[i]+low[i]+close[i]+close[i])/4.0);
      case pr_average:   return((high[i]+low[i]+close[i]+open[i])/4.0);
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


double workDsema[][24];
#define _ema1 0
#define _ema2 1
double iDsema(double price, double period, int r,int bars, int instanceNo=0)
{
   if (ArrayRange(workDsema,0)!= bars) ArrayResize(workDsema,bars); instanceNo*=2;

   //
   //
   //
   //
   //
      
   double alpha = 2.0 /(1.0+MathSqrt(period));
          workDsema[r][_ema1+instanceNo] = workDsema[r-1][_ema1+instanceNo]+alpha*(price                         -workDsema[r-1][_ema1+instanceNo]);
          workDsema[r][_ema2+instanceNo] = workDsema[r-1][_ema2+instanceNo]+alpha*(workDsema[r][_ema1+instanceNo]-workDsema[r-1][_ema2+instanceNo]);
   return(workDsema[r][_ema2+instanceNo]);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

color gradientColor(int step, int totalSteps, color from, color to)
{
   color newBlue  = getColor(step,totalSteps,(from & 0XFF0000)>>16,(to & 0XFF0000)>>16)<<16;
   color newGreen = getColor(step,totalSteps,(from & 0X00FF00)>> 8,(to & 0X00FF00)>> 8) <<8;
   color newRed   = getColor(step,totalSteps,(from & 0X0000FF)    ,(to & 0X0000FF)    )    ;
   return(newBlue+newGreen+newRed);
}
color getColor(int stepNo, int totalSteps, color from, color to)
{
   double step = (from-to)/(totalSteps-1.0);
   return((color)round(from-step*stepNo));
}