//------------------------------------------------------------------
#property copyright "mladen"
#property link      "mladen"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "hull"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen,clrOrange
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

input double   HmaLength =   14;     // Hull period
input double   HmaPower  =    1;     // Hull power
input enPrices Price     = pr_close; // Price

double hull[];
double colorInd[];

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
   SetIndexBuffer(0,hull    ,INDICATOR_DATA); 
   SetIndexBuffer(1,colorInd,INDICATOR_COLOR_INDEX); 
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
   
   int HalfPeriod = (int)MathFloor(HmaLength/2);
   int HullPeriod = (int)MathFloor(MathSqrt(HmaLength));
   for (int i=(int)MathMax(prev_calculated-1,1); i<rates_total; i++)
   {
      double price       = getPrice(Price,open,close,high,low,rates_total,i);
             hull[i]     = iLwmp(2.0*iLwmp(price,HalfPeriod,HmaPower,rates_total,i,0)-iLwmp(price,HmaLength,HmaPower,rates_total,i,1),HullPeriod,HmaPower,rates_total,i,2);
             colorInd[i] = colorInd[i-1];
               if (hull[i]>hull[i-1]) colorInd[i] = 0;
               if (hull[i]<hull[i-1]) colorInd[i] = 1;
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

double getPrice(enPrices price, const double& open[], const double& close[], const double& high[], const double& low[], int bars, int i)
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

double workLwmp[][3];
double iLwmp(double price, double period, double power, int bars, int r, int instanceNo=0)
{
   if (ArrayRange(workLwmp,0)!= bars) ArrayResize(workLwmp,bars);
   
   //
   //
   //
   //
   //
   
   workLwmp[r][instanceNo] = price;
      double sumw = MathPow(period,power);
      double sum  = sumw*price;
      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k;
                sumw  += MathPow(weight,power);
                sum   += MathPow(weight,power)*workLwmp[r-k][instanceNo];  
      }             
   return(sum/sumw);
}