//+------------------------------------------------------------------+
//|                                          EngulfingStochastic.mq5 |
//|                                                        Jay Davis |
//|                                         https://www.tidyneat.com |
//+------------------------------------------------------------------+
#property copyright "Jay Davis"
#property link      "https://www.mql5.com/en/blogs/post/724674"
#property version   "1.00"
#property description "Detect bullish and bearish engulfing candles when entering overbought or oversold territory" 

#property indicator_separate_window 
#property indicator_buffers 6
#property indicator_plots   6 
//--- the Stochastic plot 
#property indicator_label1  "Stochastic" 
#property indicator_type1   DRAW_LINE 
#property indicator_color1  clrLightSeaGreen 
#property indicator_style1  STYLE_SOLID 
#property indicator_width1  1 
//--- the Signal plot 
#property indicator_label2  "Signal" 
#property indicator_type2   DRAW_LINE 
#property indicator_color2  clrRed 
#property indicator_style2  STYLE_DOT 
#property indicator_width2  1 
//--- the Bullish Engulfing OverSold symbol 
#property indicator_label3  "Bullish_OverSold" 
#property indicator_type3   DRAW_ARROW 
#property indicator_color3  clrOrange
#property indicator_width3  3
//--- the Bearish Engulfing OverSold symbol
#property indicator_label4  "Bearish OverSold" 
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrOrange
#property indicator_width4  3
//--- the Bullish Engulfing OverBought symbol 
#property indicator_label5  "Bullish_OverBought" 
#property indicator_type5   DRAW_ARROW 
#property indicator_color5  clrCornflowerBlue
#property indicator_width5  3
//--- the Bearish Engulfing OverBought symbol
#property indicator_label6  "Bearish_OverBought" 
#property indicator_type6   DRAW_ARROW
#property indicator_color6  clrCornflowerBlue 
#property indicator_width6  3
//--- set limit of the indicator values 
#property indicator_minimum 0 
#property indicator_maximum 100 
//--- horizontal levels in the indicator window 
 #property indicator_level1  80.0 
 #property indicator_level2  20.0 
//+------------------------------------------------------------------+ 
//| Enumeration of the methods of handle creation                    | 
//+------------------------------------------------------------------+ 
enum Creation
  {
   Call_iStochastic,       // use iStochastic 
   Call_IndicatorCreate    // use IndicatorCreate 
  };
//--- input parameters 
input int                  overSold=20; // Over Sold
input int                  overBought=80;// Over Bought
input Creation             type=Call_IndicatorCreate;     // type of the function  
input int                  Kperiod=5;                 // the K period (the number of bars for calculation) 
input int                  Dperiod=3;                 // the D period (the period of primary smoothing) 
input int                  slowing=3;                 // period of final smoothing       
input ENUM_MA_METHOD       ma_method=MODE_SMA;        // type of smoothing    
input ENUM_STO_PRICE       price_field=STO_LOWHIGH;   // method of calculation of the Stochastic 
input string               symbol=" ";                // symbol  
input ENUM_TIMEFRAMES      period=PERIOD_CURRENT;     // timeframe 
//--- indicator buffers 
double         StochasticBuffer[];
double         SignalBuffer[];
double         BullishOverSold[];
double         BearishOverSold[];
double         BullishOverBought[];
double         BearishOverBought[];

//--- variable for storing the handle of the iStochastic indicator 
int    handle;
//--- variable for storing 
string name=symbol;
//--- name of the indicator on a chart 
string short_name;
//--- we will keep the number of values in the Stochastic Oscillator indicator 
int    bars_calculated=0;
//+------------------------------------------------------------------+ 
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//--- set descriptions of horizontal levels
string display = "OverBought "+ (string) overBought;
IndicatorSetString(INDICATOR_LEVELTEXT,0,display);
display = "OverSold "+ (string) overSold;
IndicatorSetString(INDICATOR_LEVELTEXT,1,display);

//--- set horizontal levels accoring to input overbought and oversold
 IndicatorSetDouble(INDICATOR_LEVELVALUE,0,overBought);
 IndicatorSetDouble(INDICATOR_LEVELVALUE,1,overSold);
//--- assignment of arrays to indicator buffers 
   SetIndexBuffer(0,StochasticBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,SignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,BullishOverSold,INDICATOR_DATA);
   SetIndexBuffer(3,BearishOverSold,INDICATOR_DATA);
   SetIndexBuffer(4,BullishOverBought,INDICATOR_DATA);
   SetIndexBuffer(5,BearishOverBought,INDICATOR_DATA);

//PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_ARROW,50);
   PlotIndexSetInteger(2,PLOT_ARROW,236);
   PlotIndexSetInteger(3,PLOT_ARROW,238);
   PlotIndexSetInteger(4,PLOT_ARROW,236);
   PlotIndexSetInteger(5,PLOT_ARROW,238);
//--- Set an empty value
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0);
//--- determine the symbol the indicator is drawn for 
   name=symbol;
//--- delete spaces to the right and to the left 
   StringTrimRight(name);
   StringTrimLeft(name);
//--- if it results in zero length of the 'name' string 
   if(StringLen(name)==0)
     {
      //--- take the symbol of the chart the indicator is attached to 
      name=_Symbol;
     }
//--- create handle of the indicator 
   if(type==Call_iStochastic)
      handle=iStochastic(name,period,Kperiod,Dperiod,slowing,ma_method,price_field);
   else
     {
      //--- fill the structure with parameters of the indicator      
      MqlParam pars[5];
      //--- the K period for calculations 
      pars[0].type=TYPE_INT;
      pars[0].integer_value=Kperiod;
      //--- the D period for primary smoothing 
      pars[1].type=TYPE_INT;
      pars[1].integer_value=Dperiod;
      //--- the K period for final smoothing 
      pars[2].type=TYPE_INT;
      pars[2].integer_value=slowing;
      //--- type of smoothing 
      pars[3].type=TYPE_INT;
      pars[3].integer_value=ma_method;
      //--- method of calculation of the Stochastic 
      pars[4].type=TYPE_INT;
      pars[4].integer_value=price_field;
      handle=IndicatorCreate(name,period,IND_STOCHASTIC,5,pars);

     }
//--- if the handle is not created 
   if(handle==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iStochastic indicator for the symbol %s/%s, error code %d",
                  name,
                  EnumToString(period),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- show the symbol/timeframe the Stochastic Oscillator indicator is calculated for 
   short_name=StringFormat("Stoch(%s, %d, %d, %d)",name,Kperiod,Dperiod,slowing);
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- normal initialization of the indicator 
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
//--- set horizontal levels accoring to input overbought and oversold
 IndicatorSetDouble(INDICATOR_LEVELVALUE,0,overBought);
 IndicatorSetDouble(INDICATOR_LEVELVALUE,1,overSold);

//--- number of values copied from the iStochastic indicator 
   int values_to_copy;
//--- determine the number of values calculated in the indicator 
   int calculated=BarsCalculated(handle);
   if(calculated<=0)
     {
      PrintFormat("BarsCalculated() returned %d, error code %d",calculated,GetLastError());
      return(0);
     }
//--- if it is the first start of calculation of the indicator or if the number of values in the iStochastic indicator changed 
//---or if it is necessary to calculated the indicator for two or more bars (it means something has changed in the price history) 
   if(prev_calculated==0 || calculated!=bars_calculated || rates_total>prev_calculated+1)
     {
      //--- if the StochasticBuffer array is greater than the number of values in the iStochastic indicator for symbol/period, then we don't copy everything  
      //--- otherwise, we copy less than the size of indicator buffers 
      if(calculated>rates_total) values_to_copy=rates_total;
      else                       values_to_copy=calculated;
     }
   else
     {
      //--- it means that it's not the first time of the indicator calculation, and since the last call of OnCalculate() 
      //--- for calculation not more than one bar is added 
      values_to_copy=(rates_total-prev_calculated)+1;
     }
//--- fill the arrays with values of the iStochastic indicator 
//--- if FillArraysFromBuffer returns false, it means the information is nor ready yet, quit operation 
   if(!FillArraysFromBuffers(StochasticBuffer,SignalBuffer,handle,values_to_copy)) return(0);
//--- form the message 
   string comm=StringFormat("%s ==>  Updated value in the indicator %s: %d",
                            TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),
                            short_name,
                            values_to_copy);
//--- display the service message on the chart 
   Comment(comm);
//--- memorize the number of values in the Stochastic Oscillator indicator 
   bars_calculated=calculated;
//--- calculate OverBought and OverSold arrows
   OverBoughtAndSoldCalculations(rates_total,prev_calculated,open,close);

//--- return the prev_calculated value for the next call 
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Displays OB and OS arrows when Engulfing is present              |
//+------------------------------------------------------------------+
void OverBoughtAndSoldCalculations(int total,int done,
                                   const double &open[],
                                   const double &close[])
  {
// input over sold and over bought calculations here
   for(int i=done; i<total; i++)
     {
      if(i!=0)
        {
         if(SignalBuffer[i]>overBought && SignalBuffer[i-1]<overBought)
           {
            // Is i bar Engulfing
            if(CheckForEngulfing(open[i-1],close[i-1],open[i],close[i])==true)
              {
               if(open[i]<close[i])// Bull candle
                 {
                  BullishOverBought[i]=SignalBuffer[i];
                 }
               else
                 {
                  BearishOverBought[i]=SignalBuffer[i];
                 }
              }
           }
         else if(SignalBuffer[i]<overSold && SignalBuffer[i-1]>overSold)
           {
            // Is i bar Engulfing
            if(CheckForEngulfing(open[i-1],close[i-1],open[i],close[i])==true)
              {
               if(open[i]<close[i])
                 {
                  BullishOverSold[i]=SignalBuffer[i];
                 }
               else
                 {
                  BearishOverSold[i]=SignalBuffer[i];
                 }
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Checks if the passed candle is and engulfing candle              |
//+------------------------------------------------------------------+
bool CheckForEngulfing(double open1,double close1,
                       double open2,double close2)
  {
   if(open1>=close2 && close1<=open2 && open1<close1)//Bearish Engulfing
     {
      return true;
     }
   else if(open1<=close2 && close1>=open2 && open1>open2)//Bullish Engulfing
     {
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+ 
//| Filling indicator buffers from the iStochastic indicator         | 
//+------------------------------------------------------------------+ 
bool FillArraysFromBuffers(double &main_buffer[],    // indicator buffer of Stochastic Oscillator values 
                           double &signal_buffer[],  // indicator buffer of the signal line 
                           int ind_handle,           // handle of the iStochastic indicator 
                           int amount                // number of copied values 
                           )
  {
//--- reset error code 
   ResetLastError();
//--- fill a part of the StochasticBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(ind_handle,MAIN_LINE,0,amount,main_buffer)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iStochastic indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
//--- fill a part of the SignalBuffer array with values from the indicator buffer that has index 1 
   if(CopyBuffer(ind_handle,SIGNAL_LINE,0,amount,signal_buffer)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iStochastic indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
//--- everything is fine 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Indicator deinitialization function                              | 
//+------------------------------------------------------------------+ 
void OnDeinit(const int reason)
  {
//--- clear the chart after deleting the indicator 
   Comment("");
  }
//+------------------------------------------------------------------+
