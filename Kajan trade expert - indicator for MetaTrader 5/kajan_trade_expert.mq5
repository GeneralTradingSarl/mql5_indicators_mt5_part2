//+------------------------------------------------------------------+
//|                                           Kajan trade expert.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window

//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots 2

#property indicator_type1 DRAW_ARROW
#property indicator_width1 4
#property indicator_color1 0xFFAA00
#property indicator_label1 "Buy"

#property indicator_type2 DRAW_ARROW
#property indicator_width2 4
#property indicator_color2 0x0000FF
#property indicator_label2 "Sell"

//--- indicator buffers
double Buffer1[];
double Buffer2[];

datetime time_alert; //used when sending alert
input bool Audible_Alerts = true;
double myPoint; //initialized in OnInit
int Stochastic_handle;
double Stochastic_Main[];
double Stochastic_Signal[];
double Low[];
int ATR_handle;
double ATR[];
double High[];

void myAlert(string type, string message)
  {
   if(type == "print")
      Print(message);
   else if(type == "error")
     {
      Print(type+" | kajan trade expert @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
   else if(type == "order")
     {
     }
   else if(type == "modify")
     {
     }
   else if(type == "indicator")
     {
      if(Audible_Alerts) Alert(type+" | kajan trade expert @ "+Symbol()+","+IntegerToString(Period())+" | "+message);
     }
  }

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {   
   SetIndexBuffer(0, Buffer1);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(0, PLOT_ARROW, 241);
   SetIndexBuffer(1, Buffer2);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetInteger(1, PLOT_ARROW, 242);
   //initialize myPoint
   myPoint = Point();
   if(Digits() == 5 || Digits() == 3)
     {
      myPoint *= 10;
     }
   Stochastic_handle = iStochastic(NULL, PERIOD_CURRENT, 5, 3, 3, MODE_SMA, STO_LOWHIGH);
   if(Stochastic_handle < 0)
     {
      Print("The creation of iStochastic has failed: Stochastic_handle=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   ATR_handle = iATR(NULL, PERIOD_CURRENT, 14);
   if(ATR_handle < 0)
     {
      Print("The creation of iATR has failed: ATR_handle=", INVALID_HANDLE);
      Print("Runtime error = ", GetLastError());
      return(INIT_FAILED);
     }
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
  {
   int limit = rates_total - prev_calculated;
   //--- counting from 0 to rates_total
   ArraySetAsSeries(Buffer1, true);
   ArraySetAsSeries(Buffer2, true);
   //--- initial zero
   if(prev_calculated < 1)
     {
      ArrayInitialize(Buffer1, EMPTY_VALUE);
      ArrayInitialize(Buffer2, EMPTY_VALUE);
     }
   else
      limit++;
   datetime Time[];
   
   if(BarsCalculated(Stochastic_handle) <= 0) 
      return(0);
   if(CopyBuffer(Stochastic_handle, MAIN_LINE, 0, rates_total, Stochastic_Main) <= 0) return(rates_total);
   ArraySetAsSeries(Stochastic_Main, true);
   if(BarsCalculated(Stochastic_handle) <= 0) 
      return(0);
   if(CopyBuffer(Stochastic_handle, SIGNAL_LINE, 0, rates_total, Stochastic_Signal) <= 0) return(rates_total);
   ArraySetAsSeries(Stochastic_Signal, true);
   if(CopyLow(Symbol(), PERIOD_CURRENT, 0, rates_total, Low) <= 0) return(rates_total);
   ArraySetAsSeries(Low, true);
   if(BarsCalculated(ATR_handle) <= 0) 
      return(0);
   if(CopyBuffer(ATR_handle, 0, 0, rates_total, ATR) <= 0) return(rates_total);
   ArraySetAsSeries(ATR, true);
   if(CopyHigh(Symbol(), PERIOD_CURRENT, 0, rates_total, High) <= 0) return(rates_total);
   ArraySetAsSeries(High, true);
   if(CopyTime(Symbol(), Period(), 0, rates_total, Time) <= 0) return(rates_total);
   ArraySetAsSeries(Time, true);
   //--- main loop
   for(int i = limit-1; i >= 0; i--)
     {
      if (i >= MathMin(5000-1, rates_total-1-50)) continue; //omit some old rates to prevent "Array out of range" or slow calculation   
      
      //Indicator Buffer 1
      if(Stochastic_Main[i] > Stochastic_Signal[i]
      && Stochastic_Main[i+1] < Stochastic_Signal[i+1] //Stochastic Oscillator crosses above Stochastic Oscillator
      && Stochastic_Main[i] < 20 //Stochastic Oscillator < fixed value
      )
        {
         Buffer1[i] = Low[i] - ATR[i]; //Set indicator value at Candlestick Low - Average True Range
         if(i == 1 && Time[1] != time_alert) myAlert("indicator", "Buy"); //Alert on next bar open
         time_alert = Time[1];
        }
      else
        {
         Buffer1[i] = EMPTY_VALUE;
        }
      //Indicator Buffer 2
      if(Stochastic_Main[i] < Stochastic_Signal[i]
      && Stochastic_Main[i+1] > Stochastic_Signal[i+1] //Stochastic Oscillator crosses below Stochastic Oscillator
      && Stochastic_Main[i] > 20 //Stochastic Oscillator > fixed value
      )
        {
         Buffer2[i] = High[i] + ATR[i]; //Set indicator value at Candlestick High + Average True Range
         if(i == 1 && Time[1] != time_alert) myAlert("indicator", "Sell"); //Alert on next bar open
         time_alert = Time[1];
        }
      else
        {
         Buffer2[i] = EMPTY_VALUE;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+