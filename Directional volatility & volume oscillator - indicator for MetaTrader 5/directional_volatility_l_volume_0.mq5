//+------------------------------------------------------------------+
//|                            Directional volatility & volume_0.mq5 |
//|                                        Copyright 2021, PuguForex |
//|                          https://www.mql5.com/en/users/puguforex |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, PuguForex"
#property link      "https://www.mql5.com/en/users/puguforex"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers   15
#property indicator_plots     5

#property indicator_label1 "Volatility"
#property indicator_type1  DRAW_COLOR_HISTOGRAM
#property indicator_color1 clrNavy,clrCrimson
#property indicator_style1 STYLE_SOLID
#property indicator_width1 2

#property indicator_label2 "Volatility slope"
#property indicator_type2  DRAW_COLOR_LINE
#property indicator_color2 clrLimeGreen,clrDeepPink
#property indicator_style2 STYLE_SOLID
#property indicator_width2 2

#property indicator_label3 "Volume"
#property indicator_type3  DRAW_COLOR_HISTOGRAM2
#property indicator_color3 clrAqua,clrYellow
#property indicator_style3 STYLE_SOLID
#property indicator_width3 2

#property indicator_label4 "Zone up"
#property indicator_type4  DRAW_LINE
#property indicator_color4 clrSilver
#property indicator_style4 STYLE_SOLID
#property indicator_width4 2

#property indicator_label5 "Zone down"
#property indicator_type5  DRAW_LINE
#property indicator_color5 clrSilver
#property indicator_style5 STYLE_SOLID
#property indicator_width5 2

input int            inpVolatilityPeriod  = 5;        //Volatility period
input ENUM_MA_METHOD inpVolatilityMethod  = MODE_SMA; //Volatility method
input int            inpVolumePeriod      = 14;       //Volume period
input ENUM_MA_METHOD inpVolumeMethod      = MODE_SMA; //Volume method
input int            inpZonePeriod        = 14;       //Zone period
input ENUM_MA_METHOD inpZoneMethod        = MODE_SMA; //Zone method

double   vola[],volacl[],vlsl[],vlslcl[],volu[],vold[],volucl[],znup[],zndn[],zl[],cl[],hi[],lo[],vl[],vlsm[];
int      mdHandle,clHandle,hiHandle,loHandle;

#include <MovingAverages.mqh>
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,vola   ,INDICATOR_DATA);
   SetIndexBuffer(1,volacl ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(2,vlsl   ,INDICATOR_DATA);
   SetIndexBuffer(3,vlslcl ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(4,volu   ,INDICATOR_DATA);
   SetIndexBuffer(5,vold   ,INDICATOR_DATA);
   SetIndexBuffer(6,volucl ,INDICATOR_COLOR_INDEX);
   SetIndexBuffer(7,znup   ,INDICATOR_DATA);
   SetIndexBuffer(8,zndn   ,INDICATOR_DATA);
   SetIndexBuffer(9,zl     ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(10,cl    ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(11,hi    ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(12,lo    ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(13,vl    ,INDICATOR_CALCULATIONS);
   SetIndexBuffer(14,vlsm  ,INDICATOR_CALCULATIONS);
//---

   mdHandle =  iMA(_Symbol,_Period,inpZonePeriod,0,inpZoneMethod,PRICE_MEDIAN);
   clHandle =  iMA(_Symbol,_Period,inpVolatilityPeriod,0,inpVolatilityMethod,PRICE_CLOSE);
   hiHandle =  iMA(_Symbol,_Period,inpZonePeriod,0,inpZoneMethod,PRICE_HIGH);
   loHandle =  iMA(_Symbol,_Period,inpZonePeriod,0,inpZoneMethod,PRICE_LOW);
   
   if(mdHandle==INVALID_HANDLE || clHandle==INVALID_HANDLE || hiHandle==INVALID_HANDLE || loHandle==INVALID_HANDLE)
     {
      Print("Failed to create all handles, Try again");
      return(INIT_FAILED);
     }
   return(INIT_SUCCEEDED);
  }
  
void OnDeinit(const int reason)
  {
   if(mdHandle!=INVALID_HANDLE)  IndicatorRelease(mdHandle);
   if(clHandle!=INVALID_HANDLE)  IndicatorRelease(clHandle);
   if(hiHandle!=INVALID_HANDLE)  IndicatorRelease(hiHandle);
   if(loHandle!=INVALID_HANDLE)  IndicatorRelease(loHandle);
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
   int   tocopy   =  (prev_calculated) ?  rates_total-prev_calculated+1 :  rates_total;
   if(CopyBuffer(mdHandle,MAIN_LINE,0,tocopy,zl)!=tocopy ||
      CopyBuffer(clHandle,MAIN_LINE,0,tocopy,cl)!=tocopy ||
      CopyBuffer(hiHandle,MAIN_LINE,0,tocopy,hi)!=tocopy ||
      CopyBuffer(loHandle,MAIN_LINE,0,tocopy,lo)!=tocopy )
     {
      return(prev_calculated);
     }

   int   limit =  (prev_calculated>0)  ?  prev_calculated-1 :  0;     
//---
   for(int i=limit;  i<rates_total  && !_StopFlag; i++)
     {
      vola[i]     =  cl[i] -  zl[i];
      volacl[i]   =  vola[i]>0   ?  0  :  vola[i]<0   ?  1  :  (i>0) ?  volacl[i-1] :  0;
      
      vlsl[i]     =  vola[i];
      vlslcl[i]   =  (i>0) ?  vlsl[i]>vlsl[i-1] ?  0  :  vlsl[i]<vlsl[i-1] ?  1  :  vlslcl[i-1] :  0;
      
      znup[i]  =  hi[i] -  zl[i];
      zndn[i]  =  lo[i] -  zl[i];
      
      volu[i]  =  znup[i]; vold[i]  =  zndn[i];
      
      vl[i] =  (close[i]>open[i])  ?  (double)tick_volume[i] :  (close[i]<open[i])  ?  -(double)tick_volume[i] :  0;
      
      switch(inpVolumeMethod)
        {
         case  MODE_SMA:   vlsm[i]  =  SimpleMA(i,inpVolumePeriod,vl);                             break;
         case  MODE_EMA:   vlsm[i]  =  ExponentialMA(i,inpVolumePeriod,(i>0)?vlsm[i-1]:vl[i],vl);  break;
         case  MODE_SMMA:  vlsm[i]  =  SmoothedMA(i,inpVolumePeriod,(i>0)?vlsm[i-1]:vl[i],vl);     break;
         case  MODE_LWMA:  vlsm[i]  =  LinearWeightedMA(i,inpVolumePeriod,vl);                     break;
         default:          vlsm[i]  =  vl[i];                                                      break;
        }
        
      volucl[i]   =  vlsm[i]>0   ?  0  :  vlsm[i]<0   ?  1  :  (i>0) ?  volucl[i-1] :  0;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
