//------------------------------------------------------------------
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Double smoothed EMA"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrOrange
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

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

input enPrices Price           = pr_close;       // Price to use
input int      EmaPeriod       = 20;             // EMA period
input color    ColorFrom       = clrDarkOrange;  // Color down
input color    ColorTo         = clrLimeGreen;   // Color Up
input int      ColorSteps      = 50;             // Color steps for drawing
double ssm[];
double colorBuffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int cSteps;
int OnInit()
{
   SetIndexBuffer(0,ssm,INDICATOR_DATA); 
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
       cSteps = (ColorSteps>1) ? ColorSteps : 2;
       PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,cSteps+1);
       for (int i=0;i<cSteps+1;i++) 
          PlotIndexSetInteger(0,PLOT_LINE_COLOR,i,gradientColor(i,cSteps+1,ColorFrom,ColorTo));
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

int totalBars;
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
   totalBars = rates_total;
   for (int i=(int)MathMax(prev_calculated-1,1); i<rates_total; i++)
   {
      ssm[i] = iEma(iEma(getPrice(Price,open,close,high,low,i,rates_total),MathSqrt(EmaPeriod),i,0),MathSqrt(EmaPeriod),i,1);
      double min = ssm[i];
      double max = ssm[i];
      double col = 0;
      for(int k=1;  k<ColorSteps && (i-k)>=0; k++)
      {
         min = (ssm[i-k]<min) ? ssm[i-k] : min;
         max = (ssm[i-k]>max) ? ssm[i-k] : max;
      }
      if((max-min) == 0)
            col = 50;
      else  col = 100 * (ssm[i]-min)/(max-min);         
      colorBuffer[i] = MathFloor(col*cSteps/100.0);                                  
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

color getColor(int stepNo, int totalSteps, color from, color to)
{
   double stes = (double)totalSteps-1.0;
   double step = (from-to)/(stes);
   return((color)round(from-step*stepNo));
}
color gradientColor(int step, int totalSteps, color from, color to)
{
   color newBlue  = getColor(step,totalSteps,(from & 0XFF0000)>>16,(to & 0XFF0000)>>16)<<16;
   color newGreen = getColor(step,totalSteps,(from & 0X00FF00)>> 8,(to & 0X00FF00)>> 8) <<8;
   color newRed   = getColor(step,totalSteps,(from & 0X0000FF)    ,(to & 0X0000FF)    )    ;
   return(newBlue+newGreen+newRed);
}

//
//
//
//
//

double workEma[][2];
double iEma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workEma,0)!= totalBars) ArrayResize(workEma,totalBars);

   //
   //
   //
   //
   //
      
   double alpha = 2.0 / (1.0+period);
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}