//------------------------------------------------------------------
#property copyright "www.tradecode.com"
#property link      "www.tradecode.com"
//------------------------------------------------------------------
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "Inverse fishert transform"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  clrLimeGreen,clrPaleVioletRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//
//
//
//
//

enum rsiMethods
{
   _rsi, // rsi
   _wil, // Wilder's rsi
   _rsx, // rsx
   _cut  // Cuttler's rsi
};
enum enumAveragesType
{
   avgSma,    // Simple moving average
   avgEma,    // Exponential moving average
   avgSmma,   // Smoothed MA
   avgLwma    // Linear weighted MA
};
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

//
//
//
//
//

input int              RsiPeriod    = 10;       // RSI period
input enPrices         RsiPrice     = pr_close; // Price
input rsiMethods       RsiMethod    = _rsx;     // Rsi method 
input int              Smooth       = 9;        // Smoothing period
input enumAveragesType SmoothMethod = avgLwma;  // Smoothing method

double ift[];
double colorInd[];
int    totalBars;

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
   SetIndexBuffer(0,ift     ,INDICATOR_DATA); 
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
   totalBars = rates_total;
   for (int i=(int)MathMax(prev_calculated-1,1); i<rates_total; i++)
   {
      double rsi = 0.1*(iRsi(getPrice(RsiPrice,open,close,high,low,rates_total,i),RsiPeriod,RsiMethod,rates_total,i)-50.0);
      double rss = iCustomMa(SmoothMethod,rsi,Smooth,i);         
             ift[i] = (MathExp(2.0*rss)-1.0)/(MathExp(2.0*rss)+1.0);
             colorInd[i] = 0;
               if (ift[i]>ift[i-1]) colorInd[i]=0;
               if (ift[i]<ift[i-1]) colorInd[i]=1;
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

#define _maWorkBufferx1 1
#define _maWorkBufferx2 2
#define _maWorkBufferx3 3

double iCustomMa(int mode, double price, double length, int r, int instanceNo=0)
{
   switch (mode)
   {
      case avgSma   : return(iSma(price,(int)length,r,instanceNo));
      case avgEma   : return(iEma(price,length,r,instanceNo));
      case avgSmma  : return(iSmma(price,(int)length,r,instanceNo));
      case avgLwma  : return(iLwma(price,(int)length,r,instanceNo));
      default       : return(price);
   }
}

//------------------------------------------------------------------
//                                                                  
//------------------------------------------------------------------
//
//
//
//
//

double workSma[][_maWorkBufferx2];
double iSma(double price, int period, int r, int instanceNo=0)
{
   if (ArrayRange(workSma,0)!= totalBars) ArrayResize(workSma,totalBars); instanceNo *= 2;

   //
   //
   //
   //
   //

   int k;      
   workSma[r][instanceNo] = price;
   if (r>=period)
          workSma[r][instanceNo+1] = workSma[r-1][instanceNo+1]+(workSma[r][instanceNo]-workSma[r-period][instanceNo])/period;
   else { workSma[r][instanceNo+1] = 0; for(k=0; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo];  
          workSma[r][instanceNo+1] /= k; }
   return(workSma[r][instanceNo+1]);
}

//
//
//
//
//

double workEma[][_maWorkBufferx1];
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

//
//
//
//
//

double workSmma[][_maWorkBufferx1];
double iSmma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workSmma,0)!= totalBars) ArrayResize(workSmma,totalBars);

   //
   //
   //
   //
   //

   if (r<period)
         workSmma[r][instanceNo] = price;
   else  workSmma[r][instanceNo] = workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
}

//
//
//
//
//

double workLwma[][_maWorkBufferx1];
double iLwma(double price, double period, int r, int instanceNo=0)
{
   if (ArrayRange(workLwma,0)!= totalBars) ArrayResize(workLwma,totalBars);
   
   //
   //
   //
   //
   //
   
   workLwma[r][instanceNo] = price;
      double sumw = period;
      double sum  = period*price;

      for(int k=1; k<period && (r-k)>=0; k++)
      {
         double weight = period-k;
                sumw  += weight;
                sum   += weight*workLwma[r-k][instanceNo];  
      }             
      return(sum/sumw);
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
//

double workRsi[][13];
#define _price  0
#define _change 1
#define _changa 2

double iRsi(double price, double period, rsiMethods rsiMode, int bars, int r, int instanceNo=0)
{
   if (ArrayRange(workRsi,0)!=bars) ArrayResize(workRsi,bars);
      int z = instanceNo*13; 
   
   //
   //
   //
   //
   //
   
   workRsi[r][z+_price] = price;
   switch (rsiMode)
   {
      case _rsi:
         if (r<period)
            {
               int k; double sum = 0; for (k=0; k<period && (r-k-1)>=0; k++) sum += MathAbs(workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price]);
                  workRsi[r][z+_change] = (workRsi[r][z+_price]-workRsi[0][z+_price])/MathMax(k,1);
                  workRsi[r][z+_changa] =                                         sum/MathMax(k,1);
            }
         else
            {
               double alpha = 1.0/period; 
               double change = workRsi[r][z+_price]-workRsi[r-1][z+_price];
                               workRsi[r][z+_change] = workRsi[r-1][z+_change] + alpha*(        change  - workRsi[r-1][z+_change]);
                               workRsi[r][z+_changa] = workRsi[r-1][z+_changa] + alpha*(MathAbs(change) - workRsi[r-1][z+_changa]);
            }
         if (workRsi[r][z+_changa] != 0)
               return(50.0*(workRsi[r][z+_change]/workRsi[r][z+_changa]+1));
         else  return(50.0);
         
      //
      //
      //
      //
      //
      
      case _wil :
         if (r>0)
         {
            workRsi[r][z+1] = irSmma(0.5*(MathAbs(workRsi[r][z+_price]-workRsi[r-1][z+_price])+(workRsi[r][z+_price]-workRsi[r-1][z+_price])),0.5*(period-1),r,bars,instanceNo*2+0);
            workRsi[r][z+2] = irSmma(0.5*(MathAbs(workRsi[r][z+_price]-workRsi[r-1][z+_price])-(workRsi[r][z+_price]-workRsi[r-1][z+_price])),0.5*(period-1),r,bars,instanceNo*2+1);
            if((workRsi[r][z+1] + workRsi[r][z+2]) != 0) 
                  return(100.0 * workRsi[r][z+1]/(workRsi[r][z+1] + workRsi[r][z+2]));
            else  return(50);
         }            
         else return(50);

      //
      //
      //
      //
      //

      case _rsx :     
         if (r<period) { for (int k=1; k<13; k++) workRsi[r][k+z] = 0; return(50); }  
         //
         //
         //
         //
         //
         
         {
            double Kg  = (3.0)/(2.0+period), Hg = 1.0-Kg; 
            double mom = workRsi[r][_price+z]-workRsi[r-1][_price+z];
            double moa = MathAbs(mom);
            for (int k=0; k<3; k++)
            {
               int kk = k*2;
               workRsi[r][z+kk+1] = Kg*mom                + Hg*workRsi[r-1][z+kk+1];
               workRsi[r][z+kk+2] = Kg*workRsi[r][z+kk+1] + Hg*workRsi[r-1][z+kk+2]; mom = 1.5*workRsi[r][z+kk+1] - 0.5 * workRsi[r][z+kk+2];
               workRsi[r][z+kk+7] = Kg*moa                + Hg*workRsi[r-1][z+kk+7];
               workRsi[r][z+kk+8] = Kg*workRsi[r][z+kk+7] + Hg*workRsi[r-1][z+kk+8]; moa = 1.5*workRsi[r][z+kk+7] - 0.5 * workRsi[r][z+kk+8];
            }
            if (moa != 0)
                 return(MathMax(MathMin((mom/moa+1.0)*50.0,100.00),0.00)); 
            else return(50);
         }            
            
      //
      //
      //
      //
      //
      
      case _cut :
         {
            double sump = 0;
            double sumn = 0;
            for (int k=0; k<period && (r-k-1)>=0; k++)
            {
               double diff = workRsi[r-k][z+_price]-workRsi[r-k-1][z+_price];
                  if (diff > 0) sump += diff;
                  if (diff < 0) sumn -= diff;
            }
            if (sumn > 0)
                  return(100.0-100.0/(1.0+sump/sumn));
            else  return(50);
         }            
   } 
   return(price);
}

//
//
//
//
//
//

double workrSmma[][2];
double irSmma(double price, double period, int r, int bars, int instanceNo=0)
{
   if (ArrayRange(workrSmma,0)!= bars) ArrayResize(workrSmma,bars);

   //
   //
   //
   //
   //

   if (r<period)
         workrSmma[r][instanceNo] = price;
   else  workrSmma[r][instanceNo] = workrSmma[r-1][instanceNo]+(price-workrSmma[r-1][instanceNo])/period;
   return(workrSmma[r][instanceNo]);
}
