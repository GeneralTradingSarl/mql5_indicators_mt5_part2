//------------------------------------------------------------------
#property link      "mladen"
#property copyright "mladenfx@gmail.com"
//------------------------------------------------------------------
#property indicator_chart_window
#property indicator_buffers 12
#property indicator_plots   5
#property indicator_label1  "upper filling"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'207,243,207'
#property indicator_label2  "lower filling"
#property indicator_type2   DRAW_FILLING
#property indicator_color2  C'252,225,205'
#property indicator_label3  "Upper band"
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  clrLimeGreen,clrSandyBrown
#property indicator_label4  "Lower band"
#property indicator_type4   DRAW_COLOR_LINE
#property indicator_color4  clrLimeGreen,clrSandyBrown
#property indicator_label5  "Middle value"
#property indicator_type5   DRAW_LINE
#property indicator_color5  clrDarkGray
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum enOrder
  {
   ord_1, // First order (EMA)
   ord_2, // Second order
   ord_3, // Third order
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum enMaTypes
  {
   ma_sma,    // Simple moving average
   ma_ema,    // Exponential moving average
   ma_smma,   // Smoothed MA
   ma_lwma    // Linear weighted MA
  };

input ENUM_APPLIED_PRICE Price          =  PRICE_CLOSE;  // Price
input enOrder            Order          =  ord_3;        // Filter Order
input int                Length         = 14;            // Fast Filter Period 
input int                PreSmooth      =  3;            // Pre-smoothing period
input enMaTypes          PreSmoothMode  =  ma_lwma;      // Pre-smoothing MA Mode
input double             K_Sigma        =  2;            // Multiplier of Sigma(Standard Deviation)

double bufferUp[],bufferUpc[],bufferDn[],bufferDnc[],bufferMe[],fupu[],fupd[],fdnd[],fdnu[],lowpass[],delta[],smoother[];
//------------------------------------------------------------------
//
//------------------------------------------------------------------
int OnInit()
  {
   SetIndexBuffer(0,fupu,INDICATOR_DATA); SetIndexBuffer(1,fupd,INDICATOR_DATA);
   SetIndexBuffer(2,fdnu,INDICATOR_DATA); SetIndexBuffer(3,fdnd,INDICATOR_DATA);
   SetIndexBuffer(4,bufferUp,INDICATOR_DATA); SetIndexBuffer(5,bufferUpc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(6,bufferDn,INDICATOR_DATA); SetIndexBuffer(7,bufferDnc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(8,bufferMe,INDICATOR_DATA);
   SetIndexBuffer(9,lowpass,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,delta,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,smoother,INDICATOR_CALCULATIONS);
   return(0);
  }
void OnDeinit(const int reason) { return; }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(Bars(_Symbol,_Period)<rates_total) return(prev_calculated);

//
//
//
//
//

   double a=0,b=0,c=0;
   switch(Order)
     {
      case ord_1 : a=2.0/(1+Length);
      break;
      case ord_2 : a=MathExp(-MathSqrt(2)*M_PI/Length);
      b=2*a*MathCos(MathSqrt(2)*M_PI/Length);
      break;
      default :    a=MathExp(-M_PI/Length);
      b = 2*a*MathCos(MathSqrt(3)*M_PI/Length);
      c = MathExp(-2*M_PI/Length);
     }
   int i=(int)MathMax(prev_calculated-1,0); for(; i<rates_total && !_StopFlag; i++)
     {
      double _price=getPrice(Price,open,close,high,low,i,rates_total),detrend=0;
      smoother[i]=iCustomMa(PreSmoothMode,_price,PreSmooth,i,rates_total,0);
      switch(Order)
        {
         case ord_1 :
            lowpass[i] = (i>0) ? (1-a)*lowpass[i-1] + a*smoother[i] : smoother[i];
            detrend    = smoother[i] - lowpass[i];
            delta[i]   = (i>0) ? (1-a)*delta[i-1] + a*detrend : 0;
            break;
         case ord_2 :
            lowpass[i] = (i>1) ? b*lowpass[i-1] - a*a*lowpass[i-2] + (1-b+a*a)*smoother[i] : smoother[i];
            detrend    = smoother[i] - lowpass[i];
            delta[i]   = (i>1) ? b*delta[i-1] - a*a*delta[i-2] + (1-b+a*a)*detrend : 0;
            break;
         default :
            lowpass[i] = (i>2) ? (b+c)*lowpass[i-1] - (c+b*c)*lowpass[i-2] + c*c*lowpass[i-3] + (1-b+c)*(1-c)*smoother[i] : smoother[i];
            detrend    = smoother[i] - lowpass[i];
            delta[i]   = (i>2) ? (b+c)*delta[i-1] - (c+b*c)*delta[i-2] + c*c*delta[i-3] + (1-b+c)*(1-c)*detrend : 0;
        }
      bufferMe[i]=lowpass[i]+delta[i];
      //----------------
      double Sum=0;
      for(int j=0; j<Length && (i-j)>=0; j++)
        {
         double del=smoother[i-j]-bufferMe[i-j];
         Sum+=del*del;
        }

      double _dev = MathSqrt(Sum/Length);
      bufferUp[i] = bufferMe[i] + K_Sigma*_dev;
      bufferDn[i] = bufferMe[i] - K_Sigma*_dev;
      fupd[i]     = bufferMe[i]; fupu[i] = bufferUp[i];
      fdnu[i]     = bufferMe[i]; fdnd[i] = bufferDn[i];
      if(i>0)
        {
         bufferUpc[i] = bufferUpc[i-1];
         bufferDnc[i] = bufferDnc[i-1];

         //
         //
         //
         //
         //

         if(bufferUp[i]>bufferUp[i-1]) bufferUpc[i] = 0;
         if(bufferUp[i]<bufferUp[i-1]) bufferUpc[i] = 1;
         if(bufferDn[i]>bufferDn[i-1]) bufferDnc[i] = 0;
         if(bufferDn[i]<bufferDn[i-1]) bufferDnc[i] = 1;
        }
     }
   return(i);
  }

//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
#define _maInstances 1
#define _maWorkBufferx1 1*_maInstances
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iCustomMa(int mode,double price,double length,int r,int bars,int instanceNo=0)
  {
   switch(mode)
     {
      case ma_sma   : return(iSma(price,(int)length,r,bars,instanceNo));
      case ma_ema   : return(iEma(price,length,r,bars,instanceNo));
      case ma_smma  : return(iSmma(price,(int)length,r,bars,instanceNo));
      case ma_lwma  : return(iLwma(price,(int)length,r,bars,instanceNo));
      default       : return(price);
     }
  }

//
//
//
//
//
double workSma[][_maWorkBufferx1];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iSma(double price,int period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workSma,0)!=_bars) ArrayResize(workSma,_bars);

   workSma[r][instanceNo]=price;
   double avg=price; int k=1; for(; k<period && (r-k)>=0; k++) avg+=workSma[r-k][instanceNo];
   return(avg/(double)k);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double workEma[][_maWorkBufferx1];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iEma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workEma,0)!=_bars) ArrayResize(workEma,_bars);

   workEma[r][instanceNo]=price;
   if(r>0 && period>1)
      workEma[r][instanceNo]=workEma[r-1][instanceNo]+(2.0/(1.0+period))*(price-workEma[r-1][instanceNo]);
   return(workEma[r][instanceNo]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double workSmma[][_maWorkBufferx1];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iSmma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workSmma,0)!=_bars) ArrayResize(workSmma,_bars);

   workSmma[r][instanceNo]=price;
   if(r>1 && period>1)
      workSmma[r][instanceNo]=workSmma[r-1][instanceNo]+(price-workSmma[r-1][instanceNo])/period;
   return(workSmma[r][instanceNo]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double workLwma[][_maWorkBufferx1];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iLwma(double price,double period,int r,int _bars,int instanceNo=0)
  {
   if(ArrayRange(workLwma,0)!=_bars) ArrayResize(workLwma,_bars);

   workLwma[r][instanceNo] = price; if(period<1) return(price);
   double sumw = period;
   double sum  = period*price;

   for(int k=1; k<period && (r-k)>=0; k++)
     {
      double weight=period-k;
      sumw  += weight;
      sum   += weight*workLwma[r-k][instanceNo];
     }
   return(sum/sumw);
  }
//
//
//
double getPrice(ENUM_APPLIED_PRICE tprice,const double &open[],const double &close[],const double &high[],const double &low[],int i,int _bars)
  {
   switch(tprice)
     {
      case PRICE_CLOSE:     return(close[i]);
      case PRICE_OPEN:      return(open[i]);
      case PRICE_HIGH:      return(high[i]);
      case PRICE_LOW:       return(low[i]);
      case PRICE_MEDIAN:    return((high[i]+low[i])/2.0);
      case PRICE_TYPICAL:   return((high[i]+low[i]+close[i])/3.0);
      case PRICE_WEIGHTED:  return((high[i]+low[i]+close[i]+close[i])/4.0);
     }
   return(0);
  }
//+------------------------------------------------------------------+
