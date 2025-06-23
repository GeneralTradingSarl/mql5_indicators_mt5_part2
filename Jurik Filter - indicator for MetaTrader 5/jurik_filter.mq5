//+------------------------------------------------------------------+
//|                                                 Jurik filter.mq5 |
//|                                                           mladen |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"

#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_label1  "Jurik filter"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  DeepSkyBlue,Red,Gold
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//
//
//
//
//

input int    Length = 50;
input double Phase  =  0;

//
//
//
//
//

double jurikFilter[];
double colorBuffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   SetIndexBuffer(0,jurikFilter,INDICATOR_DATA); PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,3);
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
   IndicatorSetString(INDICATOR_SHORTNAME,"Jurik filter("+string(Length)+","+DoubleToString(Phase,2)+")");
   return(0);
}

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
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      jurikFilter[i] = iSmooth(price[i],Length,Phase,i,rates_total);
      if (i>0)
      {
         colorBuffer[i] = 2;
            if (jurikFilter[i]>jurikFilter[i-1]) colorBuffer[i]=0;
            if (jurikFilter[i]<jurikFilter[i-1]) colorBuffer[i]=1;
      }
   }      
   return(rates_total);
}


  
//+------------------------------------------------------------------
//|                                                                 
//+------------------------------------------------------------------
//
//
//
//
//

double wrk[][10];

#define bsmax  5
#define bsmin  6
#define volty  7
#define vsum   8
#define avolty 9

//
//
//
//
//

double iSmooth(double price, double length, double phase, int r, int bars)
{
   if (ArrayRange(wrk,0)!=bars) ArrayResize(wrk,bars);
   if (price==EMPTY_VALUE) price=0;

   int k = 0;
      if (r==0) { for(; k<7; k++) wrk[0][k]=price; for(; k<10; k++) wrk[0][k]=0; return(price); }

   //
   //
   //
   //
   //
   
      double len1   = MathMax(MathLog(MathSqrt(0.5*(length-1)))/MathLog(2.0)+2.0,0);
      double pow1   = MathMax(len1-2.0,0.5);
      double del1   = price - wrk[r-1][bsmax];
      double del2   = price - wrk[r-1][bsmin];
      double div    = 1.0/(10.0+10.0*(MathMin(MathMax(length-10,0),100))/100);
      int    forBar = (int)MathMin(r,10);
	
         wrk[r][volty] = 0;
               if(MathAbs(del1) > MathAbs(del2)) wrk[r][volty] = MathAbs(del1); 
               if(MathAbs(del1) < MathAbs(del2)) wrk[r][volty] = MathAbs(del2); 
         wrk[r][vsum] =	wrk[r-1][vsum] + (wrk[r][volty]-wrk[r-forBar][volty])*div;
         
         //
         //
         //
         //
         //
               
         double dVolty;
         wrk[r][avolty] = wrk[r-1][avolty]+(2.0/(MathMax(4.0*length,30)+1.0))*(wrk[r][vsum]-wrk[r-1][avolty]);
            if (wrk[r][avolty] > 0)
                      dVolty = wrk[r][volty]/wrk[r][avolty]; else dVolty = 0;   
	               if (dVolty > MathPow(len1,1.0/pow1)) dVolty = MathPow(len1,1.0/pow1);
                  if (dVolty < 1)                      dVolty = 1.0;

      //
      //
      //
      //
      //
	        
   	double pow2 = MathPow(dVolty, pow1);
      double len2 = MathSqrt(0.5*(length-1))*len1;
      double Kv   = MathPow(len2/(len2+1), MathSqrt(pow2));

         if (del1 > 0) wrk[r][bsmax] = price; else wrk[r][bsmax] = price - Kv*del1;
         if (del2 < 0) wrk[r][bsmin] = price; else wrk[r][bsmin] = price - Kv*del2;
	
   //
   //
   //
   //
   //
      
      double R     = MathMax(MathMin(phase,100),-100)/100.0 + 1.5;
      double beta  = 0.45*(length-1)/(0.45*(length-1)+2);
      double alpha = MathPow(beta,pow2);

         wrk[r][0] = price + alpha*(wrk[r-1][0]-price);
         wrk[r][1] = (price - wrk[r][0])*(1-beta) + beta*wrk[r-1][1];
         wrk[r][2] = (wrk[r][0] + R*wrk[r][1]);
         wrk[r][3] = (wrk[r][2] - wrk[r-1][4])*MathPow((1-alpha),2) + MathPow(alpha,2)*wrk[r-1][3];
         wrk[r][4] = (wrk[r-1][4] + wrk[r][3]); 

   //
   //
   //
   //
   //

   return(wrk[r][4]);
}