//+------------------------------------------------------------------+
//|                                     Geometric Moving Average.mq5 |
//|                                     Copyright 2024, Rosh Jardine |
//|                        https://www.mql5.com/en/users/roshjardine |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Lyn Astara"
#property link      "https://www.mql5.com/en/users/roshjardine"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot GeoMALine
#property indicator_label1  "GeoMALine"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

input int      				InputGeoMAPeriod              = 7; 
input int                  InputGeoMAShift               = 0;           
input ENUM_APPLIED_PRICE   InputAppliedPriceEnum			= PRICE_CLOSE;
//--- indicator buffers
double         GeoMALineBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
   {
      //--- indicator buffers mapping
      SetIndexBuffer(0,GeoMALineBuffer,INDICATOR_DATA);
      IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
      /*** setting values of the indicator that won't be visible on a chart ***/
      PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InputGeoMAPeriod); 
      //--- line shifts when drawing
      PlotIndexSetInteger(0,PLOT_SHIFT,InputGeoMAShift);
      string short_name = "GeoMA-"+EnumToString(InputAppliedPriceEnum)+"("+IntegerToString(InputGeoMAPeriod)+")";
      IndicatorSetString(INDICATOR_SHORTNAME,short_name);
      /*const double x = double(1)/double(4);
      double t = MathPow(90,x);
      Print("t=",DoubleToString(t,4));*/
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
      double p_t = 0.0; double p_0 = 0.0; static const double x = double(1)/double(InputGeoMAPeriod);
      if (rates_total<=0) {  return(0);  }
      
      if (prev_calculated<=0)
         { 
            p_t = GET_APPLIED_PRICE(open[0],low[0],high[0],close[0]);
            GeoMALineBuffer[0] = EMPTY_VALUE;
            for (int i=1; i<InputGeoMAPeriod; i++)
               {
                  p_t   *= GET_APPLIED_PRICE(open[i],low[i],high[i],close[i]);            
               }
            GeoMALineBuffer[InputGeoMAPeriod-1] = MathPow(p_t,x); 
            for (int i=InputGeoMAPeriod; i<rates_total; i++)
               {   
                  p_0 = p_t/GET_APPLIED_PRICE(open[i-InputGeoMAPeriod],low[i-InputGeoMAPeriod],high[i-InputGeoMAPeriod],close[i-InputGeoMAPeriod]);
                  p_t   = p_0*GET_APPLIED_PRICE(open[i],low[i],high[i],close[i]);
                  GeoMALineBuffer[i] = MathPow(p_t,x); 
               }
            return(rates_total);   
         }      
      for (int i=prev_calculated; i<=rates_total-1; i++)
         {
            p_0 = p_t/GET_APPLIED_PRICE(open[i-InputGeoMAPeriod],low[i-InputGeoMAPeriod],high[i-InputGeoMAPeriod],close[i-InputGeoMAPeriod]);
            p_t   = p_0*GET_APPLIED_PRICE(open[i],low[i],high[i],close[i]);
            GeoMALineBuffer[i] = MathPow(p_t,x); 
         }
      //--- return value of prev_calculated for next call
      return(rates_total);
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
