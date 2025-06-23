//+------------------------------------------------------------------+
//|                                                VolatilityBox.mq5 |
//|                                    Copyright 2018, Mario Gharib. |
//|                                         mario.gharib@hotmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, Mario Gharib. mario.gharib@hotmail.com"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

#include <Candlestick.mqh>             // Candlesticks OHLC, charateristics & type
#include <OnNewBarCalculate.mqh>

// INPUT TYPE TREND
enum iTrend{
   A1 = 1, //Bullish Trend
   A2 = 2, //Bearish Trend
};
input iTrend PA_TYPE = A1;

string sArrowBuy1 = "";
string sArrowBuy2 = "";
string sArrowSell1 = "";
string sArrowSell2 = "";

string sTradeIdentification = "";

int OnInit()
  {
//--- create a timer with a 60 second period
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
                      const int &spread[]){

      cCandlestick cCS1, cCS2;
      
      // OHLC, Characteristics and type of Candle 1
      cCS1.mvGetCandleStickCharateristics(_Symbol,1);
      
      // OHLC, Characteristics and type of Candle 2
      cCS2.mvGetCandleStickCharateristics(_Symbol,2);

         // =====================================
         // BULLISH REVERSAL CANDLESTICK PATTERNS 
         // =====================================         

       if (PA_TYPE==1) {            
            // TRADE IDENTIFICATION 1: BULLISH HAMMER
            if (cCS1.bBullCandle && cCS2.bBearCandle && 2*cCS1.dBodyCandle<cCS1.dLowerWickCandle && cCS1.dLowerWickCandle>3*cCS1.dUpperWickCandle) {
               StringConcatenate(sTradeIdentification, "sTradeIdentification: ",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreateMQL4(sTradeIdentification,OBJ_TEXT,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dLowPrice);
               ObjectSetTextMQL4(sTradeIdentification,"HAM",10,"");
               ObjectSetMQL4(sTradeIdentification,OBJPROP_COLOR, clrGreen);  
            }      
   
            // TRADE IDENTIFICATION 2: BULLISH INVERTED HAMMER
            else if (cCS1.bBullCandle && cCS2.bBearCandle && 2*cCS1.dBodyCandle<cCS1.dUpperWickCandle && 3*cCS1.dLowerWickCandle<cCS1.dUpperWickCandle) {
               StringConcatenate(sTradeIdentification, "sTradeIdentification: ",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreateMQL4(sTradeIdentification,OBJ_TEXT,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dLowPrice);
               ObjectSetTextMQL4(sTradeIdentification,"IVH",10,"");
               ObjectSetMQL4(sTradeIdentification,OBJPROP_COLOR, clrGreen);
            }       
            
            // TRADE IDENTIFICATION 3: BULLISH ENGULFING
            else if (cCS1.bBullCandle && cCS2.bBearCandle && cCS1.dRangeCandle>cCS2.dRangeCandle && cCS1.dBodyCandle>cCS2.dBodyCandle && cCS1.dHighPrice>cCS2.dHighPrice && cCS1.dLowPrice<cCS2.dLowPrice) {
               StringConcatenate(sTradeIdentification, "sTradeIdentification: ",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreateMQL4(sTradeIdentification,OBJ_TEXT,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dLowPrice);
               ObjectSetTextMQL4(sTradeIdentification,"ENG",10,"");
               ObjectSetMQL4(sTradeIdentification,OBJPROP_COLOR, clrGreen);           
            }       
   
            // TRADE IDENTIFICATION 4: BULLISH HARAMI
            else  if (cCS1.bBullCandle && cCS2.bBearCandle && cCS1.dRangeCandle<cCS2.dRangeCandle && cCS1.dBodyCandle<cCS2.dBodyCandle && cCS1.dHighPrice<cCS2.dHighPrice && cCS1.dLowPrice>cCS2.dLowPrice) {
               StringConcatenate(sTradeIdentification, "sTradeIdentification: ",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreateMQL4(sTradeIdentification,OBJ_TEXT,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dLowPrice);
               ObjectSetTextMQL4(sTradeIdentification,"HAR",10,"");
               ObjectSetMQL4(sTradeIdentification,OBJPROP_COLOR, clrGreen);
            }      
   
            // TRADE IDENTIFICATION 5: MORNING STAR
            else if (cCS1.bBullCandle && cCS2.bBearCandle && cCS1.dBodyCandle < cCS1.dLowerWickCandle && cCS1.dBodyCandle < cCS1.dUpperWickCandle && cCS1.dLowerWickCandle ==cCS1.dUpperWickCandle) {
               StringConcatenate(sTradeIdentification, "sTradeIdentification: ",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreateMQL4(sTradeIdentification,OBJ_TEXT,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dLowPrice);
               ObjectSetTextMQL4(sTradeIdentification,"MOS",10,"");
               ObjectSetMQL4(sTradeIdentification,OBJPROP_COLOR, clrGreen);
            }       

            // TRADE IDENTIFICATION 6: BUILDING MOMEMTUM:
            if (cCS1.bBullCandle && cCS2.bBullCandle && cCS1.dRangeCandle>cCS2.dRangeCandle && cCS1.dBodyCandle>=2*cCS2.dBodyCandle) {
               StringConcatenate(sArrowBuy1,"sArrowBuy1",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreate(0,sArrowBuy1,OBJ_ARROW_BUY,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dOpenPrice);
               StringConcatenate(sArrowBuy2,"sArrowBuy2",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,2)));
               ObjectCreate(0,sArrowBuy2,OBJ_ARROW_BUY,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,2),cCS2.dOpenPrice);
            }        
         }

      // =====================================
      // BEARISH REVERSAL CANDLESTICK PATTERNS 
      // =====================================
       
       if (PA_TYPE==2) {     
            // TRADE IDENTIFICAITON 1: SHOOTING STAR
            if (cCS1.bBearCandle && cCS2.bBullCandle && 2*cCS1.dBodyCandle<cCS1.dUpperWickCandle && 3*cCS1.dLowerWickCandle<cCS1.dUpperWickCandle) {
               StringConcatenate(sTradeIdentification, "sTradeIdentification: ",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreateMQL4(sTradeIdentification,OBJ_TEXT,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dHighPrice);
               ObjectSetTextMQL4(sTradeIdentification,"SHS",10,"");
               ObjectSetMQL4(sTradeIdentification,OBJPROP_COLOR, clrRed);
            }
   
            // TRADE IDENTIFICAITON 2: HANGING MAN
            else if (cCS1.bBearCandle && cCS2.bBullCandle && 2*cCS1.dBodyCandle<cCS1.dLowerWickCandle && cCS1.dLowerWickCandle>3*cCS1.dUpperWickCandle) {
               StringConcatenate(sTradeIdentification, "sTradeIdentification: ",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreateMQL4(sTradeIdentification,OBJ_TEXT,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dHighPrice);
               ObjectSetTextMQL4(sTradeIdentification,"HGM",10,"");
               ObjectSetMQL4(sTradeIdentification,OBJPROP_COLOR, clrRed);
            }
            
            // TRADE IDENTIFICAITON 3: BEARISH ENGULFING
            else if (cCS1.bBearCandle && cCS2.bBullCandle && cCS1.dRangeCandle>cCS2.dRangeCandle && cCS1.dBodyCandle>cCS2.dBodyCandle && cCS1.dHighPrice>cCS2.dHighPrice && cCS1.dLowPrice<cCS2.dLowPrice) {
               StringConcatenate(sTradeIdentification, "sTradeIdentification: ",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreateMQL4(sTradeIdentification,OBJ_TEXT,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dHighPrice);
               ObjectSetTextMQL4(sTradeIdentification,"ENG",10,"");
               ObjectSetMQL4(sTradeIdentification,OBJPROP_COLOR, clrRed);    
            }
   
            // TRADE IDENTIFICAITON 4: BEARISH HARAMI
            else if (cCS1.bBearCandle && cCS2.bBullCandle && cCS1.dRangeCandle<cCS2.dRangeCandle && cCS1.dBodyCandle<cCS2.dBodyCandle && cCS1.dHighPrice<cCS2.dHighPrice && cCS1.dLowPrice>cCS2.dLowPrice) {
               StringConcatenate(sTradeIdentification, "sTradeIdentification: ",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreateMQL4(sTradeIdentification,OBJ_TEXT,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dHighPrice);
               ObjectSetTextMQL4(sTradeIdentification,"HAR",10,"");
               ObjectSetMQL4(sTradeIdentification,OBJPROP_COLOR, clrRed);
            }
               
            // TRADE IDENTIFICAITON 5: EVENING STAR
            else if (cCS1.bBearCandle && cCS2.bBullCandle && cCS1.dBodyCandle < cCS1.dLowerWickCandle && cCS1.dBodyCandle < cCS1.dUpperWickCandle && cCS1.dLowerWickCandle ==cCS1.dUpperWickCandle) {
               StringConcatenate(sTradeIdentification, "sTradeIdentification: ",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreateMQL4(sTradeIdentification,OBJ_TEXT,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dHighPrice);
               ObjectSetTextMQL4(sTradeIdentification,"EVS",10,"");
               ObjectSetMQL4(sTradeIdentification,OBJPROP_COLOR, clrRed);
            }
            
            // TRADE IDENTIFICATION 6: BUILDING MOMEMTUM
            else if (cCS1.bBearCandle && cCS2.bBearCandle && cCS1.dBodyCandle>cCS2.dBodyCandle && cCS1.dRangeCandle>=2*cCS2.dRangeCandle) {
               StringConcatenate(sArrowSell1,"sArrowSell1",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,1)));
               ObjectCreate(0,sArrowSell1,OBJ_ARROW_SELL,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,1),cCS1.dOpenPrice);
               StringConcatenate(sArrowSell2,"sArrowSell2",string(iTimeMQL4(_Symbol,PERIOD_CURRENT,2)));
               ObjectCreate(0,sArrowSell2,OBJ_ARROW_SELL,0,iTimeMQL4(_Symbol,PERIOD_CURRENT,2),cCS2.dOpenPrice);
            }
         }
   return(rates_total);
  }
//+------------------------------------------------------------------+
