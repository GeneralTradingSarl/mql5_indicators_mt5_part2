//+------------------------------------------------------------------+
//|                                Indicator: Equity and Balance.mq5 |
//|                                       Created by Quant Engineer  |
//|                                            https://www.abfs.tech |
//+------------------------------------------------------------------+
#property copyright "ABFS Inc"
#property link      "https://www.abfs.tech"
#property version   "1.00"
#property description ""

//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots 2

#property indicator_type1 DRAW_LINE
#property indicator_style1 STYLE_SOLID
#property indicator_width1 1
#property indicator_color1 0x00FF00
#property indicator_label1 "Equity"

#property indicator_type2 DRAW_LINE
#property indicator_style2 STYLE_SOLID
#property indicator_width2 1
#property indicator_color2 0xFFAA00
#property indicator_label2 "Balance"

//--- indicator buffers
double Buffer1[];
double Buffer2[];


//--- Custom functions ----------------------------------------------- 

double AccountBalance()
{return AccountInfoDouble(ACCOUNT_BALANCE);}
double AccountEquity()
{return AccountInfoDouble(ACCOUNT_EQUITY);}



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {   
   SetIndexBuffer(0, Buffer1);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   SetIndexBuffer(1, Buffer2);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
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
   int limit = rates_total - prev_calculated;
   //--- counting from 0 to rates_total
   ArraySetAsSeries(Buffer1, true);
   ArraySetAsSeries(Buffer2, true);
   //--- initial zero
   if(prev_calculated < 1)
     {
      ArrayInitialize(Buffer1, EMPTY_VALUE);
      ArrayInitialize(Buffer2, EMPTY_VALUE);
     }
   else
      limit++;
   
   //--- main loop
   for(int i = limit-1; i >= 0; i--)
     {
      if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   
      
      //Indicator Buffer 1
      if(true //no conditions!
      )
        {
         Buffer1[i] = AccountEquity(); //Set indicator value at fixed value
        }
      else
        {
         Buffer1[i] = EMPTY_VALUE;
        }
      //Indicator Buffer 2
      if(true //no conditions!
      )
        {
         Buffer2[i] = AccountBalance(); //Set indicator value at fixed value
        }
      else
        {
         Buffer2[i] = EMPTY_VALUE;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+