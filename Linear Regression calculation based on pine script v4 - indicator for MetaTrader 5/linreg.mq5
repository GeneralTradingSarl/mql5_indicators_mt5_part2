//+------------------------------------------------------------------+
//|                                                       linreg.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//|                                          Author: Yashar Seyyedin |
//|       Web Address: https://www.mql5.com/en/users/yashar.seyyedin |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.10"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot MA
#property indicator_label1  "MA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- input parameters
input ENUM_APPLIED_PRICE src = PRICE_CLOSE; 
input int      len=10;
input int      offset=0;
//--- indicator buffers
double         MABuffer[];

int OnInit()
  {
   SetIndexBuffer(0,MABuffer,INDICATOR_DATA);
   ArraySetAsSeries(MABuffer,true);
   return(INIT_SUCCEEDED);
  }

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
   int BARS=MathMax(Bars(_Symbol, PERIOD_CURRENT)-len-prev_calculated,1); 
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   switch(src)
   {
      case PRICE_CLOSE:
         linreg(close, MABuffer, 0, BARS, len, offset);
         break;
      case PRICE_OPEN:
         linreg(open, MABuffer, 0, BARS, len, offset);
         break;
      case PRICE_HIGH:
         linreg(high, MABuffer, 0, BARS, len, offset);
         break;
      case PRICE_LOW:
         linreg(low, MABuffer, 0, BARS, len, offset);
         break;
      default:
         linreg(close, MABuffer, 0, BARS, len, offset);
         break;
   }
   return(rates_total);
  }

void linreg(const double &input_src[], double &output[], int start_pos, int count, int _len, int _offset)
{
   for(int index=start_pos;index<start_pos+count;index++)
   {
      double sum_y=0;
      double sum_x=0;
      double sum_y2=0;
      double sum_x2=0;
      double sum_xy=0;
      for(int i=index;i<index+_len;i++)
      {
         sum_y += input_src[i];
         sum_x += i;
         sum_y2 += input_src[i]*input_src[i];
         sum_x2 += i*i;
         sum_xy += i*input_src[i];
      }
      double a = (sum_y*sum_x2-sum_x*sum_xy)/(_len*sum_x2-sum_x*sum_x);
      double b = (_len*sum_xy-sum_x*sum_y)/(_len*sum_x2-sum_x*sum_x);
      output[index]=a+b*(index+_offset);
   }
}
