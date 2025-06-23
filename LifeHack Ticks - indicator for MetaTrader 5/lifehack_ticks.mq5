//+------------------------------------------------------------------+
//|                                               LifeHack Ticks.mq5 |
//|                              Copyright © 2016, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2016, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "1.003"
#property description "Tick Indicators"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
//--- plot Ask
#property indicator_label1  "Ask"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Bid
#property indicator_label2  "Bid"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- indicator buffers
double         AskBuffer[];
double         BidBuffer[];
double         AskBufferTemp[];
double         BidBufferTemp[];
//--- parameters
int            InpVisible=300;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,AskBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,BidBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,AskBufferTemp,INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,BidBufferTemp,INDICATOR_CALCULATIONS);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0);
   ArraySetAsSeries(AskBuffer,true);
   ArraySetAsSeries(BidBuffer,true);
   ArraySetAsSeries(AskBufferTemp,true);
   ArraySetAsSeries(BidBufferTemp,true);
//--- name for DataWindow and indicator subwindow label 
   IndicatorSetString(INDICATOR_SHORTNAME,"LifeHack Ticks ");
//--- construct a short indicator name based on input parameters 
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
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
   if(prev_calculated==0)
     {
      for(int i=0;i<rates_total;i++)
        {
         AskBuffer[i]=0;
         AskBufferTemp[i]=0;
         BidBuffer[i]=0;
         BidBufferTemp[i]=0;
        }
      //--- create Event object 
      if(!TextCreate(0,"Text",ChartWindowFind(),time[rates_total-1],0.0,"Text","Arial",10,clrGreen,
         0.0,ANCHOR_RIGHT,false,false,true,0))
         return(rates_total);
      return(rates_total);
     }
//---
   MqlTick last_tick;
   if(SymbolInfoTick(Symbol(),last_tick))
     {
      int delta=rates_total-prev_calculated;
      //---
      ArrayCopy(AskBufferTemp,AskBuffer,1,0+delta,InpVisible);
      AskBufferTemp[0]=last_tick.ask;
      ArrayCopy(AskBuffer,AskBufferTemp,0,0,InpVisible);
      //---
      ArrayCopy(BidBufferTemp,BidBuffer,1,0+delta,InpVisible);
      BidBufferTemp[0]=last_tick.bid;
      ArrayCopy(BidBuffer,BidBufferTemp,0,0,InpVisible);
      //---
      for(int z=0;z<delta;z++)
        {
         AskBuffer[InpVisible-z]=0;
         AskBufferTemp[InpVisible-z]=0;
         BidBuffer[InpVisible-z]=0;
         BidBufferTemp[InpVisible-z]=0;
        }
      TextChange(0,"Text",TimeToString(last_tick.time,TIME_DATE|TIME_MINUTES|TIME_SECONDS));
      double max=ChartGetDouble(0,CHART_PRICE_MAX,ChartWindowFind());
      double min=ChartGetDouble(0,CHART_PRICE_MIN,ChartWindowFind());
      TextMove(0,"Text",time[rates_total-20],(max+min)/2.0);
     }
   else
      return(0);
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+ 
//| Creating Text object                                             | 
//+------------------------------------------------------------------+ 
bool TextCreate(const long              chart_ID=0,               // chart's ID 
                const string            name="Text",              // object name 
                const int               sub_window=0,             // subwindow index 
                datetime                time=0,                   // anchor point time 
                double                  price=0,                  // anchor point price 
                const string            text="Text",              // the text itself 
                const string            font="Arial",             // font 
                const int               font_size=10,             // font size 
                const color             clr=clrRed,               // color 
                const double            angle=0.0,                // text slope 
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type 
                const bool              back=false,               // in the background 
                const bool              selection=false,          // highlight to move 
                const bool              hidden=true,              // hidden in the object list 
                const long              z_order=0)                // priority for mouse click 
  {
//--- set anchor point coordinates if they are not set 
   ChangeTextEmptyPoint(time,price);
//--- reset the error value 
   ResetLastError();
//--- create Text object 
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": failed to create \"Text\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set the text 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text 
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type 
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the object by mouse 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Move the anchor point                                            | 
//+------------------------------------------------------------------+ 
bool TextMove(const long   chart_ID=0,  // chart's ID 
              const string name="Text", // object name 
              datetime     time=0,      // anchor point time coordinate 
              double       price=0)     // anchor point price coordinate 
  {
//--- if point position is not set, move it to the current bar having Bid price 
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value 
   ResetLastError();
//--- move the anchor point 
   if(!ObjectMove(chart_ID,name,0,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Change the object text                                           | 
//+------------------------------------------------------------------+ 
bool TextChange(const long   chart_ID=0,  // chart's ID 
                const string name="Text", // object name 
                const string text="Text") // text 
  {
//--- reset the error value 
   ResetLastError();
//--- change object text 
   if(!ObjectSetString(chart_ID,name,OBJPROP_TEXT,text))
     {
      Print(__FUNCTION__,
            ": failed to change the text! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Delete Text object                                               | 
//+------------------------------------------------------------------+ 
bool TextDelete(const long   chart_ID=0,  // chart's ID 
                const string name="Text") // object name 
  {
//--- reset the error value 
   ResetLastError();
//--- delete the object 
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete \"Text\" object! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Check anchor point values and set default values                 | 
//| for empty ones                                                   | 
//+------------------------------------------------------------------+ 
void ChangeTextEmptyPoint(datetime &time,double &price)
  {
//--- if the point's time is not set, it will be on the current bar 
   if(!time)
      time=TimeCurrent();
//--- if the point's price is not set, it will have Bid value 
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
  }
//+------------------------------------------------------------------+
