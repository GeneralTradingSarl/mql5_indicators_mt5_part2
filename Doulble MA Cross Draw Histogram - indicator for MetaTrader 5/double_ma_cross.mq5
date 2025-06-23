//+------------------------------------------------------------------+
//|                                              Double MA Cross.mq5 |
//|                                                        Submarine |
//|                         https://www.mql5.com/zh/users/carllin000 |
//+------------------------------------------------------------------+
#property copyright "Submarine"
#property link      "https://www.mql5.com/zh/users/carllin000"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 10
#property indicator_plots   4
//--- plot FastLine
#property indicator_label1  "FastLine"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot SloeLine
#property indicator_label2  "SlowLine"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrGreen
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot Long

#property indicator_label3  "Linear"
#property indicator_type3   DRAW_HISTOGRAM2
#property indicator_color3  clrRed
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot Short

#property indicator_label4  "XLinear1"
#property indicator_type4   DRAW_HISTOGRAM2
#property indicator_color4  clrGreen
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

//--- input Fast iMA parameters
input string             CommandFM            = "=====Fast_MA Paramater=====";
input ENUM_TIMEFRAMES    FastMA_timeframe     = 0;
input int                FastMA_period        = 9;
input int                FastMA_shift         = 0;
input ENUM_MA_METHOD     FastMA_method        = 0;
input ENUM_APPLIED_PRICE FastMA_applied_price = PRICE_CLOSE;

//--- input Slow iMA parameters
input string             CommandSM            = "=====Slow_MA Paramater=====";
input ENUM_TIMEFRAMES    SlowMA_timeframe     = 0;
input int                SlowMA_period        = 36;
input int                SlowMA_shift         = 0;
input ENUM_MA_METHOD     SlowMA_method        = 0;
input ENUM_APPLIED_PRICE SlowMA_applied_price = PRICE_CLOSE;

//--- indicator buffers
double         FastLineBuffer[];
double         SlowLineBuffer[];
double         LinearBuffer1[];
double         LinearBuffer2[];
double         LinearXBuffer1[];
double         LinearXBuffer2[];
int FastShift;
int SlowShift;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,FastLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SlowLineBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,LinearBuffer1 ,INDICATOR_DATA);
   SetIndexBuffer(3,LinearBuffer2 ,INDICATOR_DATA);
   SetIndexBuffer(4,LinearXBuffer1,INDICATOR_DATA);
   SetIndexBuffer(5,LinearXBuffer2,INDICATOR_DATA);
   
   FastShift=iMA(NULL,FastMA_timeframe,FastMA_period,FastMA_shift,FastMA_method,FastMA_applied_price);
   SlowShift=iMA(NULL,SlowMA_timeframe,SlowMA_period,SlowMA_shift,SlowMA_method,SlowMA_applied_price);
   
   
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
                const int &spread[])
  {
//---
   double Fast[];
   if(CopyBuffer(FastShift,0,0,rates_total,Fast)<=0)
      return(0);

   double Slow[];
   if(CopyBuffer(SlowShift,0,0,rates_total,Slow)<=0)
      return(0);

   
   int start=100;
   if(prev_calculated>0)
      start=prev_calculated-1;
   for(int i=start; i<rates_total; i++)
      {
        
       FastLineBuffer[i]=Fast[i];
       SlowLineBuffer[i]=Slow[i];
       
       if(FastLineBuffer[i]>=SlowLineBuffer[i])
         {
          LinearBuffer1[i]=Fast[i];
          LinearBuffer2[i]=Slow[i];
         }
       else 
         {
       
          LinearXBuffer1[i]=Slow[i];
          LinearXBuffer2[i]=Fast[i];
         }
       }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
