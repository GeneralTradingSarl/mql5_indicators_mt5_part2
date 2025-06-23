//+------------------------------------------------------------------+
//|                                            Double stochastic.mq5 |
//|                                                 Copyright mladen |
//|                                               mladenfx@gmail.com |
//+------------------------------------------------------------------+
#property copyright "mladen"
#property link      "mladenfx@gmail.com"
#property version   "1.00"


#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1
#property indicator_minimum -1
#property indicator_maximum 101
#property indicator_level1  20
#property indicator_level2  50
#property indicator_level3  80
#property indicator_levelcolor DarkSlateGray

//
//
//
//
//

#property indicator_label1  "Stochastic"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  Red
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//
//
//
//
//

input int    StochasticPeriod = 55;              // Stochastic period
input int    EMAPeriod        = 15;              // Smoothing period
input color  ColorFrom        = Lime;            // Oversold color
input color  ColorTo          = MediumVioletRed; // Overbought color
input int    ColorSteps       = 20;              // Color steps for drawing

//
//
//
//
//

double StochasticBuffer[];
double Colors[];
double calcBuffer1[];

//
//
//
//
//

int cSteps;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//

int OnInit()
{
   SetIndexBuffer(0,StochasticBuffer,INDICATOR_DATA);         ArraySetAsSeries(StochasticBuffer,true);
   SetIndexBuffer(1,Colors          ,INDICATOR_COLOR_INDEX);  ArraySetAsSeries(Colors          ,true);
   SetIndexBuffer(2,calcBuffer1     ,INDICATOR_CALCULATIONS); ArraySetAsSeries(calcBuffer1     ,true);

   cSteps = (ColorSteps>1) ? ColorSteps : 2;
   PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,cSteps);
   for (int i=0;i<cSteps;i++) 
            PlotIndexSetInteger(0,PLOT_LINE_COLOR,i,gradientColor(i,cSteps,ColorFrom,ColorTo));
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

   //
   //
   //
   //
   //
   
      if (!ArrayGetAsSeries(close)) ArraySetAsSeries(close,true);
      if (!ArrayGetAsSeries(high))  ArraySetAsSeries(high ,true);
      if (!ArrayGetAsSeries(low))   ArraySetAsSeries(low  ,true);

   //
   //
   //
   //
   //
   
      double max;
      double min;
      double sto;
      double alpha = 2.0/(1.0+EMAPeriod);
      int    limit = rates_total-prev_calculated;;
         
            if (prev_calculated > 0) limit++;
            if (prev_calculated ==0)
            {
               limit -= StochasticPeriod;
                  for (int i=1; i<=StochasticPeriod; i++) StochasticBuffer[rates_total-i] = 0;
            }
   //
   //
   //
   //
   //
   
   for (int i=limit; i>=0; i--)
   {
         max = high[i]; for(int k=1; k<StochasticPeriod; k++) max = MathMax(max,high[i+k]);
         min =  low[i]; for(int k=1; k<StochasticPeriod; k++) min = MathMin(min, low[i+k]);
         if (max!=min)
               sto = (close[i]-min)/(max-min)*100.00;
         else  sto = 0;            
         calcBuffer1[i] = calcBuffer1[i+1]+alpha*(sto-calcBuffer1[i+1]);
      
         //
         //
         //
         //
         //
      
         max = calcBuffer1[i]; for(int k=1; k<StochasticPeriod; k++) max = MathMax(max,calcBuffer1[i+k]);
         min = calcBuffer1[i]; for(int k=1; k<StochasticPeriod; k++) min = MathMin(min,calcBuffer1[i+k]);
         if (max!=min)
               sto = (calcBuffer1[i]-min)/(max-min)*100.00;
         else  sto = 0;            
         StochasticBuffer[i] = StochasticBuffer[i+1]+alpha*(sto-StochasticBuffer[i+1]);
         Colors[i] = MathFloor(StochasticBuffer[i]*cSteps/100.0);
   }
   
   //
   //
   //
   //
   //
   
   return(rates_total);
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

