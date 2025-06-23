//+------------------------------------------------------------------+
//|                                      Harmonic Moving Average.mq5 |
//|                                     Copyright 2024, Rosh Jardine |
//|                        https://www.mql5.com/en/users/roshjardine |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Rosh Jardine"
#property link      "https://www.mql5.com/en/users/roshjardine"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot HMALine
#property indicator_label1  "HMALine"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

input int      				InputHMAPeriod                = 7; 
input int                  InputHMAShift                 = 0;           
input ENUM_APPLIED_PRICE   InputAppliedPriceEnum			= PRICE_CLOSE;
//--- indicator buffers
double         HMALineBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
   {
      //--- indicator buffers mapping
      SetIndexBuffer(0,HMALineBuffer,INDICATOR_DATA);
      IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
      /*** setting values of the indicator that won't be visible on a chart ***/
      PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InputHMAShift); 
      //--- line shifts when drawing
      PlotIndexSetInteger(0,PLOT_SHIFT,InputHMAShift);
      string short_name = "HMA-"+EnumToString(InputAppliedPriceEnum)+"("+IntegerToString(InputHMAPeriod)+")";
      IndicatorSetString(INDICATOR_SHORTNAME,short_name);
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
      if (rates_total<=0) {  return(0);  }
      
      if (prev_calculated<=0)
         {  
            double rsd = 0.0;
            for (int i=0; i<InputHMAPeriod; i++)
               {
                  rsd += double(1/GET_APPLIED_PRICE(open[i],low[i],high[i],close[i]));
                  HMALineBuffer[i] = 0.0;
               }
            HMALineBuffer[InputHMAPeriod-1] = InputHMAPeriod/rsd;
            
            for (int i=InputHMAPeriod; i<rates_total; i++)
               {
                  double lrs = InputHMAPeriod/HMALineBuffer[i-1];
                  double vlfr = 1/GET_APPLIED_PRICE(open[i-InputHMAPeriod],low[i-InputHMAPeriod],high[i-InputHMAPeriod],close[i-InputHMAPeriod]);
                  HMALineBuffer[i] = InputHMAPeriod/(lrs-vlfr+(1/GET_APPLIED_PRICE(open[i],low[i],high[i],close[i])));
               }
            return(rates_total);   

         }
      else 
         {
            for (int i=prev_calculated; i<=rates_total-1; i++)
               {
                  double lrs = double(InputHMAPeriod)/HMALineBuffer[i-1];
                  double vlfr = 1/GET_APPLIED_PRICE(open[i-InputHMAPeriod],low[i-InputHMAPeriod],high[i-InputHMAPeriod],close[i-InputHMAPeriod]);
                  HMALineBuffer[i] = InputHMAPeriod/(lrs-vlfr+(1/GET_APPLIED_PRICE(open[i],low[i],high[i],close[i])));
               }
            return(rates_total);   
         }   
   }
//+------------------------------------------------------------------+
double GET_APPLIED_PRICE(const double ParamOpenPriceDouble,const double ParamLowPriceDouble,
                         const double ParamHighPriceDouble,const double ParamClosePriceDouble)
   {
      //+----------------------------------------------------------------------------------------------------------------------------------------+
      /*** close price as the default ***/
      double   PriceResultDouble    = ParamClosePriceDouble;
      int      AppliedPriceInt      = int(InputAppliedPriceEnum);
      //+----------------------------------------------------------------------------------------------------------------------------------------+
      switch(AppliedPriceInt)
         {
            case 1   : PriceResultDouble = ParamOpenPriceDouble; break;
            case 2   : PriceResultDouble = ParamLowPriceDouble; break;
            case 3   : PriceResultDouble = ParamHighPriceDouble; break;
            case 4   : PriceResultDouble = ParamClosePriceDouble; break;
            /*** Median price ***/
            case 5   : PriceResultDouble = (ParamHighPriceDouble + ParamLowPriceDouble)/2; break; 
            /*** Typical price ***/
            case 6   : PriceResultDouble = (ParamHighPriceDouble + ParamLowPriceDouble + ParamClosePriceDouble)/3; break;
            /*** Weighted price ***/
            default  : PriceResultDouble = (ParamHighPriceDouble + ParamLowPriceDouble + ParamClosePriceDouble + ParamClosePriceDouble)/4; break;
			}
		return(PriceResultDouble); 
   }