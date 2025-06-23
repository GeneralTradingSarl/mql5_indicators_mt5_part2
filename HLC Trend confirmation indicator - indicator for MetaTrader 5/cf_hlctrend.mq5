//+------------------------------------------------------------------+
//|                                                  CF_HLCTrend.mq5 |
//|                                       Copyright 2022, mr_schmidt |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "mr_schmidt"
#property version   "1.00"
#property strict

#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   2

//--- Long signal line
#property indicator_label1  "Long signal line"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- Short signal line
#property indicator_label2  "Short signal line"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

input ENUM_MA_METHOD    InpMAMode         =MODE_SMA;  //Moving average method
input int               InpHighPeriod     =34;  //High MA period
input int               InpLowPeriod      =13;  //Low MA period
input int               InpClosePeriod    =5;   //Close MA period

int            handleHigh, handleLow, handleClose;
double         longBuffer[];
double         shortBuffer[];
double         bufferHigh[],bufferLow[],bufferClose[];

//+------------------------------------------------------------------+
//| Initialize the indicator                                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Data buffer mapping
   SetIndexBuffer(0,longBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,shortBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,bufferHigh,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,bufferLow,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,bufferClose,INDICATOR_CALCULATIONS);
   
   ArraySetAsSeries(longBuffer,1);
   ArraySetAsSeries(shortBuffer,1);
   ArraySetAsSeries(bufferHigh,1);
   ArraySetAsSeries(bufferLow,1);
   ArraySetAsSeries(bufferClose,1);
   
   if((handleHigh = iMA(Symbol(),PERIOD_CURRENT,InpHighPeriod,0,InpMAMode,PRICE_HIGH))==INVALID_HANDLE) {
      Print("Error assigning high MA, lasterror: ",GetLastError());
      return(INIT_FAILED);
   }
   if((handleLow = iMA(Symbol(),PERIOD_CURRENT,InpLowPeriod,0,InpMAMode,PRICE_LOW))==INVALID_HANDLE) {
      Print("Error assigning low MA, lasterror: ",GetLastError());
      return(INIT_FAILED);
   }
   if((handleClose = iMA(Symbol(),PERIOD_CURRENT,InpClosePeriod,0,InpMAMode,PRICE_CLOSE))==INVALID_HANDLE) {
      Print("Error assigning close MA, lasterror: ",GetLastError());
      return(INIT_FAILED);
   }

//---
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Release indicators at shut down                                  |
//+------------------------------------------------------------------+
int OnDeinit(const int reason) {
   IndicatorRelease(handleHigh);
   IndicatorRelease(handleLow);
   IndicatorRelease(handleClose);
   
   return(reason);
}

//+------------------------------------------------------------------+
//| Iterate through rates and copy data                              |
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
   if(IsStopped()) return 0;                                // Stop flag
   
   
   //--- Check if all indicator has been calculated
   if(BarsCalculated(handleHigh) < rates_total)          
      return 0;
   if(BarsCalculated(handleLow) < rates_total)           
      return 0;
   if(BarsCalculated(handleClose) < rates_total)           
      return 0;
   
   int copyBars = 0;
   if(prev_calculated>rates_total || prev_calculated<=0) {
      copyBars = rates_total;
   }
   else {
      copyBars = rates_total-prev_calculated;
      if(prev_calculated>0) copyBars++;
   }     
 
//---
     
   for(int i=0;i<rates_total;i++) {
      longBuffer[i]=NormalizeDouble((bufferClose[i]-bufferHigh[i]), _Digits);
      shortBuffer[i]=NormalizeDouble((bufferLow[i]-bufferClose[i]), _Digits);   
   }
  
   if(CopyBuffer(handleHigh, 0, 0, rates_total, bufferHigh) <= 0)  
      return 0;
   if(CopyBuffer(handleLow, 0, 0, rates_total, bufferLow) <= 0)  
      return 0;  
   if(CopyBuffer(handleClose, 0, 0, rates_total, bufferClose) <= 0)  
      return 0;  
      
   return(rates_total);
  }
