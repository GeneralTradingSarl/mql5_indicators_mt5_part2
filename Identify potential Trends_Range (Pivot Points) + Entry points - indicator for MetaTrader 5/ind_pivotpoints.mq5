//+------------------------------------------------------------------+
//|                                              IND_PivotPoints.mq5 |
//|                                    Copyright 2020, Mario Gharib. |
//|                                         mario.gharib@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Mario Gharib. mario.gharib@hotmail.com"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

#include <Candlestick.mqh>             // Candlesticks OHLC, charateristics & type
#include <OnNewBarCalculate.mqh>

string sArrowBuy1 = "";
string sArrowSell1 = "";

datetime dtBarTimeZ = 0;
cCandlestick cCS1, cCS2, cCS3, cCS4, cCS5, cCS6, cCS7, cCS8, cCS9;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnNewBarCalculate(const int rates_total,
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

      sArrowBuy1 = "";
      sArrowSell1 = "";

      // OHLC, Characteristics and type of Candles

      cCS5.mvGetCandleStickCharateristics(_Symbol,5);
      cCS4.mvGetCandleStickCharateristics(_Symbol,4);
      cCS3.mvGetCandleStickCharateristics(_Symbol,3);
      cCS2.mvGetCandleStickCharateristics(_Symbol,2);
      cCS1.mvGetCandleStickCharateristics(_Symbol,1);
      cCS6.mvGetCandleStickCharateristics(_Symbol,6);
      cCS7.mvGetCandleStickCharateristics(_Symbol,7);
      cCS8.mvGetCandleStickCharateristics(_Symbol,8);
      cCS9.mvGetCandleStickCharateristics(_Symbol,9);
            
      dtBarTimeZ = iTimeMQL4(NULL,PERIOD_CURRENT,5);  // Return the datetime of the z bar of the current symbol on the current timeframe

      if (cCS5.dHighPrice>cCS4.dHighPrice && cCS5.dHighPrice>cCS6.dHighPrice &&
          cCS5.dHighPrice>cCS3.dHighPrice && cCS5.dHighPrice>cCS7.dHighPrice &&
          cCS5.dHighPrice>cCS2.dHighPrice && cCS5.dHighPrice>cCS8.dHighPrice &&
          cCS5.dHighPrice>cCS1.dHighPrice && cCS5.dHighPrice>cCS9.dHighPrice) {
      
         StringConcatenate(sArrowSell1,"sArrowSell1",string(dtBarTimeZ));
         ObjectCreate(0,sArrowSell1,OBJ_ARROW_SELL,0,dtBarTimeZ,cCS5.dHighPrice);
         
      } else if (cCS5.dLowPrice<cCS4.dLowPrice && cCS5.dLowPrice<cCS6.dLowPrice &&
                 cCS5.dLowPrice<cCS3.dLowPrice && cCS5.dLowPrice<cCS7.dLowPrice &&
                 cCS5.dLowPrice<cCS2.dLowPrice && cCS5.dLowPrice<cCS8.dLowPrice &&
                 cCS5.dLowPrice<cCS1.dLowPrice && cCS5.dLowPrice<cCS9.dLowPrice) {
      
         StringConcatenate(sArrowBuy1,"sArrowBuy1",string(dtBarTimeZ));
         ObjectCreate(0,sArrowBuy1,OBJ_ARROW_BUY,0,dtBarTimeZ,cCS5.dLowPrice);
      }

   return(rates_total);
  }
//+------------------------------------------------------------------+
