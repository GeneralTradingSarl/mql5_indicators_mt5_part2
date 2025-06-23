//+------------------------------------------------------------------+
//|                              Intraday Currencies Performance.mq5 |
//|                                                  Studio Sofrollo |
//|                                         studiosofrollo@gmail.com |
//+------------------------------------------------------------------+
//---- author of the indicator
#property copyright "Studio Sofrollo"
#property link      "studiosofrollo@gmail.com"
//---- indicator version number
#property version   "1.00"
//---- drawing indicator in a separate window
#property indicator_separate_window
//----two buffers are used for calculation of drawing of the indicator
#property indicator_buffers 22
//---- two plots are used
#property indicator_plots   8
//+----------------------------------------------+
//|  CG indicator drawing parameters             |
//+----------------------------------------------+
input int grandezzacarattere=10;// Font size

input color Color_USD = Lime;            // USD line color
input color Color_EUR = Blue;         // EUR line color
input color Color_GBP = Red;              // GBP line color
input color Color_CHF = Magenta;        // CHF line color
input color Color_JPY = Yellow;           // JPY line color
input color Color_AUD = Aqua;       // AUD line color
input color Color_CAD = White;           // CAD line color
input color Color_NZD = Orange;             // NZD line color
input int                wid_main =         1; // Line width
input ENUM_LINE_STYLE style_slave = STYLE_SOLID; //Line style

int         y_pos = 0; // Y coordinate variable for the informatory objects

//+----------------------------------------------+
//|  Trigger indicator drawing parameters        |
//+----------------------------------------------+
//+----------------------------------------------+
//|  Indicator input parameters                  |
//+----------------------------------------------+
string pair1="EURUSD";//Cross 1
string pair2="GBPUSD";//Cross 2
string pair3="AUDUSD";//Cross 3
string pair4="NZDUSD";//Cross 4
string pair5="USDJPY";//Cross 5
string pair6="USDCAD";//Cross 6
string pair7="USDCHF";//Cross 7

input string tm="00:00";// Time in the format hours:minutes
int Shift=0; // horizontal shift of the indicator in bars
//+----------------------------------------------+
//---- declaration of dynamic arrays that further
//---- will be used as indicator buffers
double USD[];
double EUR[];
double GBP[];
double AUD[];
double CAD[];
double JPY[];
double NZD[];
double CHF[];

double OscBuffer1;
double OscBuffer2;
double OscBuffer3;
double OscBuffer4;
double OscBuffer5;
double OscBuffer6;
double OscBuffer7;

double open1[];
double close1[];
double open2[];
double close2[];
double open3[];
double close3[];
double open4[];
double close4[];
double open5[];
double close5[];
double open6[];
double close6[];
double open7[];
double close7[];

//---- declaration of the integer variables for the start of data calculation
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- Initialization of variables of the start of data calculation
   min_rates_total=2;

//---- set dynamic array as an indicator buffer
   SetIndexBuffer(0,USD,INDICATOR_DATA);
   SetIndexBuffer(1,EUR,INDICATOR_DATA);
   SetIndexBuffer(2,GBP,INDICATOR_DATA);
   SetIndexBuffer(3,AUD,INDICATOR_DATA);
   SetIndexBuffer(4,CAD,INDICATOR_DATA);
   SetIndexBuffer(5,JPY,INDICATOR_DATA);
   SetIndexBuffer(6,NZD,INDICATOR_DATA);
   SetIndexBuffer(7,CHF,INDICATOR_DATA);


//---- shifting the indicator 1 horizontally by Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(4,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(5,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(6,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(7,PLOT_SHIFT,Shift);

//---- shifting the start of drawing of the indicator 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- setting the indicator values that won't be visible on a chart
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   SetIndexBuffer(8,open1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(9,close1,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,open2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,close2,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,open3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,close3,INDICATOR_CALCULATIONS);
   SetIndexBuffer(14,open4,INDICATOR_CALCULATIONS);
   SetIndexBuffer(15,close4,INDICATOR_CALCULATIONS);
   SetIndexBuffer(16,open5,INDICATOR_CALCULATIONS);
   SetIndexBuffer(17,close5,INDICATOR_CALCULATIONS);
   SetIndexBuffer(18,open6,INDICATOR_CALCULATIONS);
   SetIndexBuffer(19,close6,INDICATOR_CALCULATIONS);
   SetIndexBuffer(20,open7,INDICATOR_CALCULATIONS);
   SetIndexBuffer(21,close7,INDICATOR_CALCULATIONS);

//---- initializations of variable for indicator short name
   string shortname;
   StringConcatenate(shortname,"Intr.Curr.%"+" ("+tm+")","");
//--- creation of the name to be displayed in a separate sub-window and in a pop up help
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- determination of accuracy of displaying the indicator values
   IndicatorSetInteger(INDICATOR_DIGITS,2);
   PlotIndexSetString(0,PLOT_LABEL,"% USD");
   PlotIndexSetString(1,PLOT_LABEL,"% EUR");
   PlotIndexSetString(2,PLOT_LABEL,"% GBP");
   PlotIndexSetString(3,PLOT_LABEL,"% AUD");
   PlotIndexSetString(4,PLOT_LABEL,"% CAD");
   PlotIndexSetString(5,PLOT_LABEL,"% JPY");
   PlotIndexSetString(6,PLOT_LABEL,"% NZD");
   PlotIndexSetString(7,PLOT_LABEL,"% CHF");

   PlotIndexSetInteger(0,PLOT_LINE_COLOR,Color_USD);        // color of line rendering
   PlotIndexSetInteger(1,PLOT_LINE_COLOR,Color_EUR);        // color of line rendering
   PlotIndexSetInteger(2,PLOT_LINE_COLOR,Color_GBP);        // color of line rendering
   PlotIndexSetInteger(3,PLOT_LINE_COLOR,Color_AUD);        // color of line rendering
   PlotIndexSetInteger(4,PLOT_LINE_COLOR,Color_CAD);        // color of line rendering
   PlotIndexSetInteger(5,PLOT_LINE_COLOR,Color_JPY);        // color of line rendering
   PlotIndexSetInteger(6,PLOT_LINE_COLOR,Color_NZD);        // color of line rendering
   PlotIndexSetInteger(7,PLOT_LINE_COLOR,Color_CHF);        // color of line rendering

   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(5,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(6,PLOT_DRAW_TYPE,DRAW_LINE);
   PlotIndexSetInteger(7,PLOT_DRAW_TYPE,DRAW_LINE);


   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,wid_main);
   PlotIndexSetInteger(1,PLOT_LINE_WIDTH,wid_main);
   PlotIndexSetInteger(2,PLOT_LINE_WIDTH,wid_main);
   PlotIndexSetInteger(3,PLOT_LINE_WIDTH,wid_main);
   PlotIndexSetInteger(4,PLOT_LINE_WIDTH,wid_main);
   PlotIndexSetInteger(5,PLOT_LINE_WIDTH,wid_main);
   PlotIndexSetInteger(6,PLOT_LINE_WIDTH,wid_main);
   PlotIndexSetInteger(7,PLOT_LINE_WIDTH,wid_main);

   perfscrivi(" USD",Color_USD);   // rendering in the indicator information window
   perfscrivi(" EUR",Color_EUR);   // rendering in the indicator information window
   perfscrivi(" GBP",Color_GBP);   // rendering in the indicator information window
   perfscrivi(" AUD",Color_AUD);   // rendering in the indicator information window
   perfscrivi(" CAD",Color_CAD);   // rendering in the indicator information window
   perfscrivi(" JPY",Color_JPY);   // rendering in the indicator information window
   perfscrivi(" NZD",Color_NZD);   // rendering in the indicator information window
   perfscrivi(" CHF",Color_CHF);   // rendering in the indicator information window

//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(
   const int rates_total,    // amount of history in bars at the current tick
   const int prev_calculated,// amount of history in bars at the previous tick
   const datetime &time[],
   const double &open[],
   const double& high[],     // price array of maximums of price for the calculation of indicator
   const double& low[],      // price array of price lows for the indicator calculation
   const double &close[],
   const long &tick_volume[],
   const long &volume[],
   const int &spread[]
)
  {
//---- checking the number of bars to be enough for calculation
   if(rates_total<min_rates_total)
      return(0);

//---- declaration of local variables
   int first,bar;
   static double Open1=0.0;
   static double Open2=0.0;
   static double Open3=0.0;
   static double Open4=0.0;
   static double Open5=0.0;
   static double Open6=0.0;
   static double Open7=0.0;

//---- calculation of the starting number 'first' for the cycle of recalculation of bars
   if(prev_calculated>rates_total || prev_calculated<=0) // checking for the first start of calculation of an indicator
     {
      first=min_rates_total; // starting index for calculation of all bars
     }
   else
      first=prev_calculated-1; // starting number for calculation of new bars

   CopyOpen(pair1,PERIOD_CURRENT,0,rates_total,open1);

   CopyClose(pair1,PERIOD_CURRENT,0,rates_total,close1);

   CopyOpen(pair2,PERIOD_CURRENT,0,rates_total,open2);

   CopyClose(pair2,PERIOD_CURRENT,0,rates_total,close2);

   CopyOpen(pair3,PERIOD_CURRENT,0,rates_total,open3);

   CopyClose(pair3,PERIOD_CURRENT,0,rates_total,close3);

   CopyOpen(pair4,PERIOD_CURRENT,0,rates_total,open4);

   CopyClose(pair4,PERIOD_CURRENT,0,rates_total,close4);

   CopyOpen(pair5,PERIOD_CURRENT,0,rates_total,open5);

   CopyClose(pair5,PERIOD_CURRENT,0,rates_total,close5);

   CopyOpen(pair6,PERIOD_CURRENT,0,rates_total,open6);

   CopyClose(pair6,PERIOD_CURRENT,0,rates_total,close6);

   CopyOpen(pair7,PERIOD_CURRENT,0,rates_total,open7);

   CopyClose(pair7,PERIOD_CURRENT,0,rates_total,close7);


//---- main cycle of calculation of the indicator
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {

      if(TimeToString(time[bar],TIME_MINUTES)==tm)
        {
         Open1=open1[bar];
         Open2=open2[bar];
         Open3=open3[bar];
         Open4=open4[bar];
         Open5=open5[bar];
         Open6=open6[bar];
         Open7=open7[bar];

        }

      if(Open1==0)
         OscBuffer1=1;
      else
         OscBuffer1=(close1[bar]-Open1)/Open1*100;

      if(Open2==0)
         OscBuffer2=1;
      else
         OscBuffer2=(close2[bar]-Open2)/Open2*100;

      if(Open3==0)
         OscBuffer3=1;
      else
         OscBuffer3=(close3[bar]-Open3)/Open3*100;

      if(Open4==0)
         OscBuffer4=1;
      else
         OscBuffer4=(close4[bar]-Open4)/Open4*100;

      if(Open5==0)
         OscBuffer5=1;
      else
         OscBuffer5=(close5[bar]-Open5)/Open5*100;

      if(Open6==0)
         OscBuffer6=1;
      else
         OscBuffer6=(close6[bar]-Open6)/Open6*100;

      if(Open7==0)
         OscBuffer7=1;
      else
         OscBuffer7=(close7[bar]-Open7)/Open7*100;

      USD[bar]=(OscBuffer5+OscBuffer6+OscBuffer7-OscBuffer1-OscBuffer2-OscBuffer3-OscBuffer4)/8;
      EUR[bar]=(7*OscBuffer1-OscBuffer2-OscBuffer3-OscBuffer4+OscBuffer5+OscBuffer6+OscBuffer7)/8;
      GBP[bar]=(7*OscBuffer2+OscBuffer6+OscBuffer7+OscBuffer5-OscBuffer1-OscBuffer3-OscBuffer4)/8;
      AUD[bar]=(7*OscBuffer3-OscBuffer2-OscBuffer1-OscBuffer4+OscBuffer5+OscBuffer6+OscBuffer7)/8;
      CAD[bar]=(-7*OscBuffer6+OscBuffer7+OscBuffer5-OscBuffer1-OscBuffer2-OscBuffer3-OscBuffer4)/8;
      JPY[bar]=(-7*OscBuffer5-OscBuffer1-OscBuffer2-OscBuffer3-OscBuffer4+OscBuffer6+OscBuffer7)/8;
      NZD[bar]=(7*OscBuffer4-OscBuffer1-OscBuffer2-OscBuffer3+OscBuffer5+OscBuffer6+OscBuffer7)/8;
      CHF[bar]=(-7*OscBuffer7+OscBuffer6+OscBuffer5-OscBuffer1-OscBuffer2-OscBuffer3-OscBuffer4)/8;

     }
//----
   return(rates_total);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
///        Drawing objects
//+------------------------------------------------------------------+
int perfscrivi(string name,color _color)
  {
   ObjectCreate(0,name,OBJ_LABEL,ChartWindowFind(),0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,0);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y_pos);
   ObjectSetString(0,name,OBJPROP_TEXT,name);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,grandezzacarattere);
   ObjectSetInteger(0,name,OBJPROP_COLOR,_color);
   y_pos+=(int)MathRound(grandezzacarattere*1.5);
   return(0);
  }
//+------------------------------------------------------------------+
