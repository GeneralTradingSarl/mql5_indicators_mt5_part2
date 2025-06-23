//+------------------------------------------------------------------+
//|                                                         M1MA.mq5 |
//|                                    Copyright (c) 2020, Marketeer |
//|                          https://www.mql5.com/en/users/marketeer |
//|                              https://www.mql5.com/en/code/29673/ |
//+------------------------------------------------------------------+
#property copyright "Copyright (c) 2020 Marketeer"
#property link "https://www.mql5.com/en/users/marketeer"
#property version "1.0"
#property description "M1-based Moving Average. It gives more adequate estimation of average price per bar compared to any standard price type (close, open, median, typical, weighted, etc).\n"

#define BUF_NUM 1

#property indicator_chart_window
#property indicator_buffers BUF_NUM
#property indicator_plots   BUF_NUM

#property indicator_color1 clrDodgerBlue
#property indicator_width1 2


#include <IndArray.mqh>
IndicatorArray buffers(BUF_NUM);
// IndicatorArrayGetter getter(buffers);


input uint BarLimit = 100;
input uint BarPeriod = 1;
input ENUM_APPLIED_PRICE M1Price = PRICE_CLOSE;

int handle;


int OnInit()
{
  string parts[];
  string legend = EnumToString(M1Price);
  if(StringSplit(legend, '_', parts) == 2) legend = parts[1];
  
  IndicatorSetString(INDICATOR_SHORTNAME, "M1MA (" + legend + "," + (string)BarPeriod + "[" + (string)(PeriodSeconds() / 60) + "])");
  IndicatorSetInteger(INDICATOR_DIGITS, _Digits);

  PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
  PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 1 + BarPeriod);
  
  const uint p = PeriodSeconds() / 60 * BarPeriod;
  
  handle = iMA(_Symbol, PERIOD_M1, p, 0, MODE_SMA, M1Price); //  only simple MA makes sense for averaging M1's within higher timeframe bars
  
  return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double& price[])
{
  int i, limit = 1;

  static datetime lastBar = 0;
  static int barCount = 0;

  if(lastBar == 0 || fabs(barCount - rates_total) > 1)
  {
    limit = (int)MathMin(rates_total - 1 - BarPeriod, BarLimit);
    for(i = 0; i < rates_total; i++)
    {
      buffers[0][i] = EMPTY_VALUE;
    }
  }
  else if(lastBar != iTime(NULL, 0, 0))
  {
    limit = 2;
  }
  
  static double result[1];
  int bar;

  for(i = 0; i < limit; i++)
  {
    datetime dt = iTime(NULL, 0, i) + PeriodSeconds() - 60;
    if(dt > TimeCurrent()) bar = 0;
    else bar = iBarShift(NULL, PERIOD_M1, dt);
    if(CopyBuffer(handle, 0, bar, 1, result) == 1)
    {
      buffers[0][i] = result[0];
    }
    else
    {
      if(prev_calculated == 0)
      {
        Print("M1 not ready: ", GetLastError());
      }
      return prev_calculated;
    }
  }
  
  lastBar = iTime(NULL, 0, 0);
  barCount = rates_total;
  
  return rates_total;
}
