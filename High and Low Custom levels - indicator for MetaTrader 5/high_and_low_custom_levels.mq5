//+------------------------------------------------------------------+
//|                                   High and Low Custom levels.mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.002"
#property indicator_chart_window
#property indicator_plots 0
//--- input parameters
sinput string           _0_="*-*-*-*-*-*"; // Global parameters
input int               shift_high        = 10;
input int               shift_low         = -10;
input uchar             count_day=3;  // count day "0" -> current day
sinput string           _1_="*-*-*-*-*-*"; // High Level parameters
//--- input parameters of the script 
input color             InpColorHigh         = clrBlue;        // Line color 
input ENUM_LINE_STYLE   InpStyleHigh         = STYLE_DASH;     // Line style 
input int               InpWidthHigh         = 1;              // Line width 
sinput string           _2_="Low Level parameters";
//--- input parameters of the script 
input color             InpColorLow          = clrRed;         // Line color 
input ENUM_LINE_STYLE   InpStyleLow          = STYLE_DASH;     // Line style 
input int               InpWidthLow          = 1;              // Line width 
//---
string name_high="High Level";
string name_low="Low Level";
//---
double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(Digits()==3 || Digits()==5)
      digits_adjust=10;
   m_adjusted_point=Point()*digits_adjust;
//---
   if(ObjectFind(0,name_high)<0)
      HLineCreate(0,name_high,0,0.0,InpColorHigh,InpStyleHigh,InpWidthHigh);
   if(ObjectFind(0,name_low)<0)
      HLineCreate(0,name_low,0,0.0,InpColorLow,InpStyleLow,InpWidthLow);
//---
   MqlRates rates_array[];
   CopyRates(Symbol(),PERIOD_D1,0,count_day,rates_array);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Indicator deinitialization function                              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   Print(__FUNCTION__,", ",reason);
   if(reason==1) // REASON_REMOVE
     {
      HLineDelete(0,name_high);
      HLineDelete(0,name_low);
     }
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
   static int number=-9;
   number++;
   if(number%50==0)
     {
      //Comment(number);
      number=0;
     }
   else
     {
      //Comment(number);
      return(rates_total);
     }
//---
   double High[];
   double Low[];
   int count=(count_day==0)?1:count_day;
   CopyHigh(Symbol(),PERIOD_D1,0,count,High);
   CopyLow(Symbol(),PERIOD_D1,0,count,Low);
   double price_high=0.0;
   double price_low=0.0;
   if(count_day>0)
     {
      price_high=High[ArrayMaximum(High,0,WHOLE_ARRAY)];
      price_low=Low[ArrayMinimum(Low,0,WHOLE_ARRAY)];
     }
   else
     {
      price_high=High[0];
      price_low=Low[0];
     }

   price_high+=shift_high*m_adjusted_point;
   price_low+=shift_low*m_adjusted_point;

   if(ObjectFind(0,name_high)<0)
      HLineCreate(0,name_high,0,0.0,InpColorHigh,InpStyleHigh,InpWidthHigh);
   HLineMove(0,name_high,price_high);

   if(ObjectFind(0,name_low)<0)
      HLineCreate(0,name_low,0,0.0,InpColorLow,InpStyleLow,InpWidthLow);
   HLineMove(0,name_low,price_low);
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+ 
//| Create the horizontal line                                       | 
//+------------------------------------------------------------------+ 
bool HLineCreate(const long            chart_ID=0,        // chart's ID 
                 const string          name="HLine",      // line name 
                 const int             sub_window=0,      // subwindow index 
                 double                price=0,           // line price 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_SOLID, // line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=true,    // highlight to move 
                 const bool            hidden=true,       // hidden in the object list 
                 const long            z_order=0)         // priority for mouse click 
  {
//--- if the price is not set, set it at the current Bid price level 
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value 
   ResetLastError();
//--- create a horizontal line 
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true) 
//   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
////--- enable (true) or disable (false) the mode of moving the line by mouse 
////--- when creating a graphical object using ObjectCreate function, the object cannot be 
////--- highlighted and moved by default. Inside this method, selection parameter 
////--- is true by default making it possible to highlight and move the object 
//   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
//   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
////--- hide (true) or display (false) graphical object name in the object list 
//   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
////--- set the priority for receiving the event of a mouse click in the chart 
//   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Move horizontal line                                             | 
//+------------------------------------------------------------------+ 
bool HLineMove(const long   chart_ID=0,   // chart's ID 
               const string name="HLine", // line name 
               double       price=0)      // line price 
  {
//--- if the line price is not set, move it to the current Bid price level 
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value 
   ResetLastError();
//--- move a horizontal line 
   if(!ObjectMove(chart_ID,name,0,0,price))
     {
      Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Delete a horizontal line                                         | 
//+------------------------------------------------------------------+ 
bool HLineDelete(const long   chart_ID=0,   // chart's ID 
                 const string name="HLine") // line name 
  {
//--- reset the error value 
   ResetLastError();
//--- delete a horizontal line 
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+
