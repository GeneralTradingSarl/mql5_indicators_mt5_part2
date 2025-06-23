//------------------------------------------------------------------
#property copyright "mladen"
#property link      "www.forex-tsd.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   2
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDarkGray
#property indicator_width1  2
#property indicator_type2   DRAW_COLOR_ARROW
#property indicator_color2  clrPaleVioletRed,clrLimeGreen

//
//
//
//
//

input int    DrsiPeriod = 14;   // Dynamic rsi calculation period
input double Filter     = 10;   // Filter 
input double SARStep    = 0.02; // Parabolic SAR step
input double SARMaximum = 0.1;  // Parabolic SAR maximum

double drsi[];
double sar[];
double colors[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//

void OnInit()
{
   SetIndexBuffer(0,drsi);
   SetIndexBuffer(1,sar); PlotIndexSetInteger(1,PLOT_ARROW,159);
   SetIndexBuffer(2,colors,INDICATOR_COLOR_INDEX);
   IndicatorSetString(INDICATOR_SHORTNAME,"Directional RSI 2 ("+(string)DrsiPeriod+","+(string)Filter+")");
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

double workDrsi[][4];
#define _dmp   0
#define _dmm   1
#define _thigh 2
#define _tlow  3

int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tickVolume[],
                const long &volume[],
                const int &spread[])
{
   if (ArrayRange(workDrsi,0)!=rates_total) ArrayResize(workDrsi,rates_total);

   //
   //
   //
   //
   //
   
   for (int i=(int)MathMax(prev_calculated-1,1); i<rates_total; i++)
   {
      workDrsi[i][_thigh] = iEma(high[i],Filter,rates_total,i,0);
      workDrsi[i][_tlow]  = iEma(low[i] ,Filter,rates_total,i,1);
      double lm = workDrsi[i-1][_tlow]-workDrsi[i][_tlow];
      double hm = workDrsi[i][_thigh]-workDrsi[i-1][_thigh];
         if (hm>0 && hm>lm)
               workDrsi[i][_dmp] = hm;
         else  workDrsi[i][_dmp] = 0;
         if (lm>0 && lm>hm)
               workDrsi[i][_dmm] = lm;
         else  workDrsi[i][_dmm] = 0;
      
      //
      //
      //
      //
      //
      
      double dmp = 0;
      double dmm = 0;
      for (int k=0; k<DrsiPeriod && (i-k)>=0; k++) { dmp += workDrsi[i-k][_dmp]; dmm += workDrsi[i-k][_dmm]; }
         if (dmm!=0)
               drsi[i] = 100-(100/(1.0+dmp/dmm));
         else  drsi[i] = drsi[i-1];   
      double sarOpen;
      double sarPosition;
      double sarChange;
      sar[i] = iParabolic(drsi[i],drsi[i],SARStep,SARMaximum,sarOpen,sarPosition,sarChange,i,rates_total);
      if (sarPosition==1)
            colors[i] = 1;
      else  colors[i] = 0;
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

double workEma[][2];
double iEma(double price, double period, int totalBars, int r, int instanceNo=0)
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

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

double workSar[][7];
#define _high     0
#define _low      1
#define _ohigh    2
#define _olow     3
#define _open     4
#define _position 5
#define _af       6


double iParabolic(double high, double low, double step, double limit, double& pOpen, double& pPosition, double& pChange, int i, int total)
{
   if (ArrayRange(workSar,0)!=total) ArrayResize(workSar,total);
   
   //
   //
   //
   //
   //
   
   if (high<low) { double temp = high; high = low; low  = temp;}             
   double pClose  = high;
          pChange = 0;
               workSar[i][_ohigh] = high;
               workSar[i][_olow]  = low;
               if (i<1)
               {
                  workSar[i][_high]     = high;
                  workSar[i][_low]      = low;
                  workSar[i][_open]     = high;
                  workSar[i][_position] = -1;
                     return(EMPTY_VALUE);
               }
               workSar[i][_open]     = workSar[i-1][_open];
               workSar[i][_af]       = workSar[i-1][_af];
               workSar[i][_position] = workSar[i-1][_position];
               workSar[i][_high]     = MathMax(workSar[i-1][_high],high);
               workSar[i][_low]      = MathMin(workSar[i-1][_low] ,low );
      
   //
   //
   //
   //
   //
            
   if (workSar[i][_position] == 1)
      if (low<=workSar[i][_open])
         {
            workSar[i][_position] = -1;
               pChange = -1;
               pClose  = workSar[i][_high];
                         workSar[i][_high] = high;
                         workSar[i][_low]  = low;
                         workSar[i][_af]   = step;
                         workSar[i][_open] = pClose + workSar[i][_af]*(workSar[i][_low]-pClose);
                            if (workSar[i][_open]<workSar[i  ][_ohigh]) workSar[i][_open] = workSar[i  ][_ohigh];
                            if (workSar[i][_open]<workSar[i-1][_ohigh]) workSar[i][_open] = workSar[i-1][_ohigh];
         }
      else
         {
               pClose = workSar[i][_open];
                    if (workSar[i][_high]>workSar[i-1][_high] && workSar[i][_af]<limit) workSar[i][_af] = MathMin(workSar[i][_af]+step,limit);
                        workSar[i][_open] = pClose + workSar[i][_af]*(workSar[i][_high]-pClose);
                            if (workSar[i][_open]>workSar[i  ][_olow]) workSar[i][_open] = workSar[i  ][_olow];
                            if (workSar[i][_open]>workSar[i-1][_olow]) workSar[i][_open] = workSar[i-1][_olow];
         }
   else
      if (high>=workSar[i][_open])
         {
            workSar[i][_position] = 1;
               pChange = 1;
               pClose  = workSar[i][_low];
                         workSar[i][_low]  = low;
                         workSar[i][_high] = high;
                         workSar[i][_af]   = step;
                         workSar[i][_open] = pClose + workSar[i][_af]*(workSar[i][_high]-pClose);
                            if (workSar[i][_open]>workSar[i  ][_olow]) workSar[i][_open] = workSar[i  ][_olow];
                            if (workSar[i][_open]>workSar[i-1][_olow]) workSar[i][_open] = workSar[i-1][_olow];
         }
      else
         {
               pClose = workSar[i][_open];
               if (workSar[i][_low]<workSar[i-1][_low] && workSar[i][_af]<limit) workSar[i][_af] = MathMin(workSar[i][_af]+step,limit);
                   workSar[i][_open] = pClose + workSar[i][_af]*(workSar[i][_low]-pClose);
                            if (workSar[i][_open]<workSar[i  ][_ohigh]) workSar[i][_open] = workSar[i  ][_ohigh];
                            if (workSar[i][_open]<workSar[i-1][_ohigh]) workSar[i][_open] = workSar[i-1][_ohigh];
         }

   //
   //
   //
   //
   //
   
   pOpen     = workSar[i][_open];
   pPosition = workSar[i][_position];
   return(pClose);
}