//+------------------------------------------------------------------+
//|                                                        iVWAD.mq5 |
//|                                                    Arthur Albano |
//|                       https://www.mql5.com/en/users/arthuralbano |
//+------------------------------------------------------------------+
#property copyright "Arthur Albano"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_label1  "iWVAD"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- indicator buffers
double         iWVAD[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexBuffer(0,iWVAD,INDICATOR_DATA);
   IndicatorSetString(INDICATOR_SHORTNAME,"Larry Williams' iWVAD");
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
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
   if(Bars(_Symbol,_Period)<rates_total) return(0);
   double Ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double Bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   for(int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !_StopFlag && Ask>Bid; i++)
     {
      iWVAD[i]=(high[i]>low[i])?((close[i]-open[i])/(high[i]-low[i]))*(volume[i]>0 ? volume[i]:(tick_volume[i]>0 ? tick_volume[i]: 1)) : NULL;
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
