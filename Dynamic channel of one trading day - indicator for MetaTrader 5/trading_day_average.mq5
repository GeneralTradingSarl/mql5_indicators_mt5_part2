//+------------------------------------------------------------------+
//|                                          Trading_Day_Average.mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   3
//--- plot Cloud
#property indicator_label1  "Cloud"
#property indicator_type1   DRAW_HISTOGRAM2
#property indicator_color1  clrYellow
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Low
#property indicator_label2  "High"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot High
#property indicator_label3  "Low"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrGreen
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- input parameters
input uchar    InpHourBegin      =  3; // Hour of the beginning of the day
input uchar    InpMinutesBegin   =  0; // Minute of the beginning of the day
//--- indicator buffers
double         BufferCloud1[];
double         BufferCloud2[];
double         BufferLow[];
double         BufferHigh[];
//--- global variables
uchar          hour_begin;
uchar          minutes_begin;
datetime       time_begin;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- setting parameters
   hour_begin=(InpHourBegin>23 ? 23 : InpHourBegin);
   minutes_begin=(InpMinutesBegin>59 ? 59 : InpMinutesBegin);
//--- indicator buffers mapping
   SetIndexBuffer(0,BufferCloud1,INDICATOR_DATA);
   SetIndexBuffer(1,BufferCloud2,INDICATOR_DATA);
   SetIndexBuffer(2,BufferHigh,INDICATOR_DATA);
   SetIndexBuffer(3,BufferLow,INDICATOR_DATA);
//--- strings parameters
   IndicatorSetString(INDICATOR_SHORTNAME,"Trading day average");
//---
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
//--- Checking for minimum number of bars
   if(rates_total<3) return 0;
//--- Set arrays as time series
   ArraySetAsSeries(BufferCloud1,true);
   ArraySetAsSeries(BufferCloud2,true);
   ArraySetAsSeries(BufferHigh,true);
   ArraySetAsSeries(BufferLow,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(time,true);
//--- check for limits
   int limit=rates_total-prev_calculated;
   if(limit>1)
     {
      limit=rates_total-1;
      ArrayInitialize(BufferCloud1,EMPTY_VALUE);
      ArrayInitialize(BufferCloud2,EMPTY_VALUE);
      ArrayInitialize(BufferHigh,EMPTY_VALUE);
      ArrayInitialize(BufferLow,EMPTY_VALUE);
     }
//--- calculate indicator
   for(int i=limit; i>=0 && !IsStopped(); i--)
     {
      datetime last_begin=LastBegin(time[i],hour_begin,minutes_begin);
      if(last_begin==0) return 0;
      if(last_begin>time[i]) last_begin-=PeriodSeconds(PERIOD_D1);
      int last_begin_bar=BarShift(Symbol(),PERIOD_CURRENT,last_begin);
      if(last_begin_bar==WRONG_VALUE) return 0;
      int period=last_begin_bar-i+1;
      double ma_high=GetMA(period,MODE_SMA,PRICE_HIGH,i);
      double ma_low=GetMA(period,MODE_SMA,PRICE_LOW,i);
      if(ma_high==WRONG_VALUE || ma_low==WRONG_VALUE) return 0;
      BufferHigh[i]=BufferCloud1[i]=ma_high;
      BufferLow[i]=BufferCloud2[i]=ma_low;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Calculate for last time begin                                    |
//+------------------------------------------------------------------+
datetime LastBegin(const datetime time,const int hour,const int minutes)
  {
   MqlDateTime stm;
   datetime tm=time;
   if(tm==0) return 0;
   TimeToStruct(tm,stm);
   stm.hour=hour;
   stm.min=minutes;
   return StructToTime(stm);
  }
//+------------------------------------------------------------------+
//| Returns the bar number by time                                   |
//+------------------------------------------------------------------+
int BarShift(const string symbol_name,const ENUM_TIMEFRAMES timeframe,const datetime time)
  {
   int res=WRONG_VALUE;
   datetime last_bar=0;
   if(::SeriesInfoInteger(symbol_name,timeframe,SERIES_LASTBAR_DATE,last_bar))
     {
      if(time>last_bar) res=0;
      else
        {
         const int shift=::Bars(symbol_name,timeframe,time,last_bar);
         if(shift>0) res=shift-1;
        }
     }
   return(res);
  }
//+------------------------------------------------------------------+
//| MA one from one specified bar                                    |
//+------------------------------------------------------------------+
double GetMA(const int period,
             const ENUM_MA_METHOD method,
             const ENUM_APPLIED_PRICE price,
             const int shift)
  {
   double array[];
   ResetLastError();
   int handle=iMA(NULL,PERIOD_CURRENT,period,0,method,price);
   if(handle==INVALID_HANDLE)
     {
      Print("Trading day average: Error creating MA handle ",GetLastError(),", recalculate now");
      return(WRONG_VALUE);
     }
   if(CopyBuffer(handle,0,shift,1,array)==1) return array[0];
   return WRONG_VALUE;
  }
//+------------------------------------------------------------------+
