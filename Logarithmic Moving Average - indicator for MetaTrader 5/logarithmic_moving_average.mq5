//+------------------------------------------------------------------+
//|                                   Logarithmic Moving Average.mq5 |
//|                                     Copyright 2024, Rosh Jardine |
//|                        https://www.mql5.com/en/users/roshjardine |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Rosh Jardine"
#property link      "https://www.mql5.com/en/users/roshjardine"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot LogMALine
#property indicator_label1  "LogMALine"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

input int      				InputLogMAPeriod              = 7; 
input int                  InputLogMAShift               = 0;           
input ENUM_APPLIED_PRICE   InputAppliedPriceEnum			= PRICE_CLOSE;
//--- indicator buffers
double         LogMALineBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
   {
      //--- indicator buffers mapping
      SetIndexBuffer(0,LogMALineBuffer,INDICATOR_DATA);
      IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
      /*** setting values of the indicator that won't be visible on a chart ***/
      PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
      PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InputLogMAPeriod); 
      //--- line shifts when drawing
      PlotIndexSetInteger(0,PLOT_SHIFT,InputLogMAShift);
      string short_name = "LogMA-"+EnumToString(InputAppliedPriceEnum)+"("+IntegerToString(InputLogMAPeriod)+")";
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
      double hp = DBL_MIN, lp = DBL_MAX;
      //---
      if (rates_total<=0) {  return(0);  }
      
      if (prev_calculated<=0)
         { 
            
             for (int i=0; i<InputLogMAPeriod; i++)
               {
                  double p = GET_APPLIED_PRICE(open[i],low[i],high[i],close[i]);
                  hp = (p>hp) ? p : hp;
                  lp = (p<lp) ? p : lp;              
               }
            Print("hp = ",DoubleToString(hp,_Digits));
            Print("lp = ",DoubleToString(lp,_Digits));
            
            LogMALineBuffer[InputLogMAPeriod-1] = (hp-lp)/(MathLog(hp)-MathLog(lp));
            hp = DBL_MIN; lp = DBL_MAX;
            for (int i=InputLogMAPeriod; i<rates_total; i++)
               {
                  for (int j=i; j>(i-InputLogMAPeriod); j--)
                     {
                        double p = GET_APPLIED_PRICE(open[j],low[j],high[j],close[j]);
                        hp = (p>hp) ? p : hp;
                        lp = (p<lp) ? p : lp;  
                     }
                  LogMALineBuffer[i] = (hp-lp)/(MathLog(hp)-MathLog(lp));
                  hp = DBL_MIN; lp = DBL_MAX;
               }
            return(rates_total);   
         }   
      else 
         {
            for (int i=prev_calculated; i<=rates_total-1; i++)
               {
                  for (int j=i; j>(i-InputLogMAPeriod); j--)
                     {
                        double p = GET_APPLIED_PRICE(open[j],low[j],high[j],close[j]);
                        hp = (p>hp) ? p : hp;
                        lp = (p<lp) ? p : lp;  
                     }
                  LogMALineBuffer[i] = (hp-lp)/(MathLog(hp)-MathLog(lp));
                  hp = DBL_MIN; lp = DBL_MAX;
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