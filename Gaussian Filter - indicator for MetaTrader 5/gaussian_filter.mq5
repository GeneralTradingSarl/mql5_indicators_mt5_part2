//------------------------------------------------------------------
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Gaussian filter"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen,clrPaleVioletRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//
//
//
//
//

input int GPeriod = 14;   // Calculation period
input int GOrder  = 2;    // Order

//
//
//
//
//
//

double gf[];
double colorBuffer[];

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
   SetIndexBuffer(0,gf,INDICATOR_DATA); 
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
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

int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const int begin,
                 const double& price[] )
{

   //
   //
   //
   //
   //

   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      gf[i] = iGFilter(price[i],GPeriod,GOrder,rates_total,i);
             if (i>0)
             {
                colorBuffer[i] = colorBuffer[i-1];
                    if (gf[i] > gf[i-1]) colorBuffer[i]= 0;
                    if (gf[i] < gf[i-1]) colorBuffer[i]= 1;
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

#define Pi 3.141592653589793238462643

int    periods[1];
double coeffs[][3];
double filters[][1];
double iGFilter(double price, int period, int order, int bars, int i, int instanceNo=0)
{
   if (ArrayRange(filters,0)!=bars)  ArrayResize(filters,bars);
   if (ArrayRange(coeffs,0)<order+1) ArrayResize(coeffs,order+1);
   if (periods[instanceNo]!=period)
   {
      periods[instanceNo]=period;
         double b = (1.0 - MathCos(2.0*Pi/period))/(MathPow(MathSqrt(2.0),2.0/order) - 1.0);
         double a = -b + MathSqrt(b*b + 2.0*b);
         for(int r=0; r<=order; r++)
         {
             coeffs[r][instanceNo*3+0] = fact(order)/(fact(order-r)*fact(r));
             coeffs[r][instanceNo*3+1] = MathPow(    a,r);
             coeffs[r][instanceNo*3+2] = MathPow(1.0-a,r);
         }
   }

   //
   //
   //
   //
   //
   
   if (price==EMPTY_VALUE) price=0;
   filters[i][instanceNo] = price*coeffs[order][instanceNo*3+1];
      double sign = 1;
         for (int r=1; r <= order && (i-r)>=0; r++, sign *= -1.0)
                  filters[i][instanceNo] += sign*coeffs[r][instanceNo*3+0]*coeffs[r][instanceNo*3+2]*filters[i-r][instanceNo];
   return(filters[i][instanceNo]);
}

//
//
//
//
//

double fact(int n)
{
   double a=1;
         for(int i=1; i<=n; i++) a*=i;
   return(a);
}