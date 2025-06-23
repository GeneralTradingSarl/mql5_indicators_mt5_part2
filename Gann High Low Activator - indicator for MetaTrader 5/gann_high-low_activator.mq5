//------------------------------------------------------------------
#property copyright   "mladen"
#property link        "www.forex-tsd.com"
#property version     "1.00"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   3
#property indicator_label1  "Gann zone"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  clrGainsboro
#property indicator_label2  "Gann middle"
#property indicator_type2   DRAW_LINE
#property indicator_style2  STYLE_DOT
#property indicator_color2  clrGray
#property indicator_label3  "Gann high/low"
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  clrDarkGray,clrLimeGreen,clrOrangeRed
#property indicator_width3  2

//
//
//
//
//

enum enMaTypes
{
   ma_Sma,    // Simple moving average
   ma_Ema,    // Exponential moving average
   ma_Smma,   // Smoothed MA
   ma_Lwma    // Linear weighted MA
};

input int       AvgPeriod       = 10;          // Average period
input enMaTypes AvgType         = ma_Sma;      // Average method
input bool      alertsOn        = false;       // Turn alerts on?
input bool      alertsOnCurrent = true;        // Alert on current bar?
input bool      alertsMessage   = true;        // Display messageas on alerts?
input bool      alertsSound     = false;       // Play sound on alerts?
input bool      alertsEmail     = false;       // Send email on alerts?
input bool      alertsNotify    = false;       // Send push notification on alerts?

double avg[],avgc[],mid[],fup[],fdn[];

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
   SetIndexBuffer(0,fup,INDICATOR_DATA);
   SetIndexBuffer(1,fdn,INDICATOR_DATA);
   SetIndexBuffer(2,mid,INDICATOR_DATA);
   SetIndexBuffer(3,avg,INDICATOR_DATA);
   SetIndexBuffer(4,avgc,INDICATOR_COLOR_INDEX);
   IndicatorSetString(INDICATOR_SHORTNAME,"Gann high/low activator ("+(string)AvgPeriod+")");
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
   if (Bars(_Symbol,_Period)<rates_total) return(-1);
   
   //
   //
   //
   //
   //
   
   for (int i=(int)MathMax(prev_calculated-1,1); i<rates_total && !IsStopped(); i++)
   {
      fup[i]  = iCustomMa(AvgType,high[i-1],AvgPeriod,i,rates_total,0);
      fdn[i]  = iCustomMa(AvgType,low[i-1] ,AvgPeriod,i,rates_total,1);
      mid[i]  = (fup[i]+fdn[i])/2.0;
      avgc[i] = (close[i]>fup[i]) ? 1 : (close[i]<fdn[i]) ? 2 : avgc[i-1];
      avg[i]  = (avgc[i]==1) ? fdn[i] : (avgc[i]==2) ? fup[i] : close[i];
   }
   manageAlerts(time,avgc,rates_total);
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

void manageAlerts(const datetime& time[], double& trend[], int bars)
{
   if (alertsOn)
   {
      int whichBar = bars-1; if (!alertsOnCurrent) whichBar = bars-2; datetime time1 = time[whichBar];
         
      //
      //
      //
      //
      //
         
      if (trend[whichBar] != trend[whichBar-1])
      {
         if (trend[whichBar] == 1) doAlert(time1,"up");
         if (trend[whichBar] == 2) doAlert(time1,"down");
      }         
   }
}   

//
//
//
//
//

void doAlert(datetime forTime, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   if (previousAlert != doWhat || previousTime != forTime) 
   {
      previousAlert  = doWhat;
      previousTime   = forTime;

      //
      //
      //
      //
      //

      message = TimeToString(TimeLocal(),TIME_SECONDS)+" "+_Symbol+" Gann high/low activator state changed to "+doWhat;
         if (alertsMessage) Alert(message);
         if (alertsEmail)   SendMail(_Symbol+" Gann high/low activator",message);
         if (alertsNotify)  SendNotification(message);
         if (alertsSound)   PlaySound("alert2.wav");
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

#define _maInstances 6
#define _maWorkBufferx1 1*_maInstances
#define _maWorkBufferx2 2*_maInstances

double iCustomMa(int mode, double price, double length, int r, int bars, int instanceNo=0)
{
   switch (mode)
   {
      case ma_Sma   : return(iSma(price,(int)length,r,bars,instanceNo));
      case ma_Ema   : return(iEma(price,length,r,bars,instanceNo));
      case ma_Smma  : return(iSmma(price,(int)length,r,bars,instanceNo));
      case ma_Lwma  : return(iLwma(price,(int)length,r,bars,instanceNo));
      default       : return(price);
   }
}

//
//
//
//
//

double workSma[][_maWorkBufferx2];
double iSma(double price, int period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workSma,0)!= _bars) ArrayResize(workSma,_bars); instanceNo *= 2; int k;

   //
   //
   //
   //
   //
      
   workSma[r][instanceNo+0] = price;
   workSma[r][instanceNo+1] = price; for(k=1; k<period && (r-k)>=0; k++) workSma[r][instanceNo+1] += workSma[r-k][instanceNo+0];  
   workSma[r][instanceNo+1] /= 1.0*k;
   return(workSma[r][instanceNo+1]);
}

//
//
//
//
//

double workEma[][_maWorkBufferx1];
double iEma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workEma,0)!= _bars) ArrayResize(workEma,_bars);

   //
   //
   //
   //
   //
      
   workEma[r][instanceNo] = price;
   double alpha = 2.0 / (1.0+period);
   if (r>0)
          workEma[r][instanceNo] = workEma[r-1][instanceNo]+alpha*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
}

//
//
//
//
//

double workSmma[][_maWorkBufferx1];
double iSmma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workSmma,0)!= _bars) ArrayResize(workSmma,_bars);

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
double iLwma(double price, double period, int r, int _bars, int instanceNo=0)
{
   if (period<=1) return(price);
   if (ArrayRange(workLwma,0)!= _bars) ArrayResize(workLwma,_bars);
   
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