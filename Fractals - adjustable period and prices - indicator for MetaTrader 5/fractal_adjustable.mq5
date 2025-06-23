//+------------------------------------------------------------------+
//|                                           Fractal_adjustable.mq5 |
//|                                      Rajesh Nait, Copyright 2023 |
//|                  https://www.mql5.com/en/users/rajeshnait/seller |
//+------------------------------------------------------------------+
#property copyright "Rajesh Nait, Copyright 2023"
#property link      "https://www.mql5.com/en/users/rajeshnait/seller"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 2
#property indicator_plots 2
#property indicator_color1  clrRed
#property indicator_color2  clrBlue
#property indicator_width1  2
#property indicator_width2  2

input int                FractalPeriod          = 5;                // Fractal period: 5 for built in fractal
input ENUM_APPLIED_PRICE PriceHigh              = PRICE_HIGH;       // Price high
input ENUM_APPLIED_PRICE PriceLow               = PRICE_LOW;        // Price low
input double             UpperArrowDisplacement = 0.2;              // Upper arrow displacement
input double             LowerArrowDisplacement = 0.2;              // Lower arrow displacement

double v1[],v2[];
int f_pd;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping

   f_pd= FractalPeriod;

   if (MathMod(f_pd,2)==0) f_pd = f_pd+1;
   SetIndexBuffer(0,v1,INDICATOR_DATA);
   SetIndexBuffer(1,v2,INDICATOR_DATA);
   
   PlotIndexSetInteger (0, PLOT_DRAW_TYPE, DRAW_ARROW );
   PlotIndexSetInteger (0, PLOT_ARROW,159);
   PlotIndexSetInteger (1, PLOT_DRAW_TYPE, DRAW_ARROW );
   PlotIndexSetInteger (1, PLOT_ARROW,159);

   IndicatorSetString ( INDICATOR_SHORTNAME, "Fractals - adjustable price");
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
                const int &spread[]) {
//---
   int limit=MathMin(MathMax(rates_total-prev_calculated,f_pd),rates_total-1);



   int half = f_pd/2;
   for(int i=limit; i>=half && !_StopFlag; i--) {
      bool   found     = true;
      double compareTo = iMAMQL4(NULL,0,1,0,MODE_SMA,PriceHigh,i);
      for (int k=1; k<=half; k++) {
         if ((i+k)<rates_total && iMAMQL4(NULL,0,1,0,MODE_SMA,PriceHigh,i+k)> compareTo) {
            found=false;
            break;
         }
         if ((i-k)>=0          && iMAMQL4(NULL,0,1,0,MODE_SMA,PriceHigh,i-k)>=compareTo) {
            found=false;
            break;
         }
      }
      if (found)
         v1[i] = high[i]+iATRMQL4(NULL,0,20,i)*UpperArrowDisplacement;
      else  v1[i] = EMPTY_VALUE;

      //
      //
      //

      found     = true;
      compareTo = iMAMQL4(NULL,0,1,0,MODE_SMA,PriceLow,i);
      for (int k=1; k<=half; k++) {
         if ((i+k)<rates_total && iMAMQL4(NULL,0,1,0,MODE_SMA,PriceLow,i+k)< compareTo) {
            found=false;
            break;
         }
         if ((i-k)>=0          && iMAMQL4(NULL,0,1,0,MODE_SMA,PriceLow,i-k)<=compareTo) {
            found=false;
            break;
         }
      }
      if (found)
         v2[i] = low[i]-iATRMQL4(NULL,0,20,i)*LowerArrowDisplacement;
      else v2[i] = EMPTY_VALUE;

   }
//--- return value of prev_calculated for next call
   return(rates_total);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  iMAMQL4( string  symbol,
                 int  tf,
                 int  period,
                 int  ma_shift,
                 int  method,
                 int  price,
                 int  shift) {
   ENUM_TIMEFRAMES  timeframe=TFMigrate(tf);
   ENUM_MA_METHOD  ma_method=MethodMigrate(method);
   ENUM_APPLIED_PRICE  applied_price=PriceMigrate(price);
   int  handle= iMA (symbol,timeframe,period,ma_shift,
                     ma_method,applied_price);
   if (handle< 0 ) {
      Print ( "The iMA object is not created: Error", GetLastError ());
      return (- 1 );
   } else
      return (CopyBufferMQL4(handle, 0,shift));
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  iATRMQL4( string  symbol,
                  int  tf,
                  int  period,
                  int  shift) {
   ENUM_TIMEFRAMES  timeframe=TFMigrate(tf);
   int  handle= iATR (symbol,timeframe,period);
   if (handle< 0 ) {
      Print ( " The iATR  object is not created: Error ", GetLastError ());
      return (- 1 );
   } else
      return (CopyBufferMQL4(handle, 0,shift));
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_TIMEFRAMES  TFMigrate( int  tf) {
   switch (tf) {
   case  0 :
      return ( PERIOD_CURRENT );
   case  1 :
      return ( PERIOD_M1 );
   case  5 :
      return ( PERIOD_M5 );
   case  15 :
      return ( PERIOD_M15 );
   case  30 :
      return ( PERIOD_M30 );
   case  60 :
      return ( PERIOD_H1 );
   case  240 :
      return ( PERIOD_H4 );
   case  1440 :
      return ( PERIOD_D1 );
   case  10080 :
      return ( PERIOD_W1 );
   case  43200 :
      return ( PERIOD_MN1 );

   case  2 :
      return ( PERIOD_M2 );
   case  3 :
      return ( PERIOD_M3 );
   case  4 :
      return ( PERIOD_M4 );
   case  6 :
      return ( PERIOD_M6 );
   case  10 :
      return ( PERIOD_M10 );
   case  12 :
      return ( PERIOD_M12 );
   case  16385 :
      return ( PERIOD_H1 );
   case  16386 :
      return ( PERIOD_H2 );
   case  16387 :
      return ( PERIOD_H3 );
   case  16388 :
      return ( PERIOD_H4 );
   case  16390 :
      return ( PERIOD_H6 );
   case  16392 :
      return ( PERIOD_H8 );
   case  16396 :
      return ( PERIOD_H12 );
   case  16408 :
      return ( PERIOD_D1 );
   case  32769 :
      return ( PERIOD_W1 );
   case  49153 :
      return ( PERIOD_MN1 );
   default :
      return ( PERIOD_CURRENT );
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_MA_METHOD  MethodMigrate( int  method) {
   switch (method) {
   case  0 :
      return ( MODE_SMA );
   case  1 :
      return ( MODE_EMA );
   case  2 :
      return ( MODE_SMMA );
   case  3 :
      return ( MODE_LWMA );
   default :
      return ( MODE_SMA );
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ENUM_APPLIED_PRICE  PriceMigrate( int  price) {
   switch (price) {
   case  1 :
      return ( PRICE_CLOSE );
   case  2 :
      return ( PRICE_OPEN );
   case  3 :
      return ( PRICE_HIGH );
   case  4 :
      return ( PRICE_LOW );
   case  5 :
      return ( PRICE_MEDIAN );
   case  6 :
      return ( PRICE_TYPICAL );
   case  7 :
      return ( PRICE_WEIGHTED );
   default :
      return ( PRICE_CLOSE );
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double  CopyBufferMQL4( int  handle, int  index, int  shift) {
   double  buf[];
   switch (index) {
   case  0 :
      if ( CopyBuffer (handle, 0,shift, 1,buf)> 0 )
         return (buf[ 0 ]);
      break ;
   case  1 :
      if ( CopyBuffer (handle, 1,shift, 1,buf)> 0 )
         return (buf[ 0 ]);
      break ;
   case  2 :
      if ( CopyBuffer (handle, 2,shift, 1,buf)> 0 )
         return (buf[ 0 ]);
      break ;
   case  3 :
      if ( CopyBuffer (handle, 3,shift, 1,buf)> 0 )
         return (buf[ 0 ]);
      break ;
   case  4 :
      if ( CopyBuffer (handle, 4,shift, 1,buf)> 0 )
         return (buf[ 0 ]);
      break ;
   default :
      break ;
   }
   return ( EMPTY_VALUE );
}
//+------------------------------------------------------------------+
