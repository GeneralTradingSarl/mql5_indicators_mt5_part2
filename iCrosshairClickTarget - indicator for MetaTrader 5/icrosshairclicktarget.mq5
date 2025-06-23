//+------------------------------------------------------------------+
//|                                        iCrosshairClickTarget.mq5 |
//|                           Copyright 2016, Roberto Jacobs (3rjfx) |
//|                              https://www.mql5.com/en/users/3rjfx |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Roberto Jacobs (3rjfx) ~ By 3rjfx ~ Created: 2016/12/18"
#property link      "https://www.mql5.com/en/users/3rjfx"
#property version   "1.00"
#property strict
//---
// Update_1: 2016/12/21.
// Update_2: 2021/11/21.
//--
#property description "iCrosshairClickTarget indicator is the improved version of iCrosshair indicator for MT4, by adding"
#property description "'click Target' and the trend line, with text of the 'number of bars between target and crosshair',"
#property description "and the difference in pips between Price at target level and Price at crosshair level."
#property description "version: 1.0 ~ Update number: 02 ~ Last update: 2021/11/21 @00:08 AM WIT (Western Indonesian Time)"
//--
///--
#property indicator_chart_window
#property indicator_buffers  1
#property indicator_plots    1 
#property indicator_type1    DRAW_NONE
//---
input color             ColorLine  = clrTomato;   // Line color
input color           ColorTarget  = clrYellow;   // Target color
input color        ColorTrendLine  = clrLime;     // Trend Line color
input ENUM_LINE_STYLE   LineStyle  = STYLE_SOLID; // Line style
input int               LineWidth  = 1;           // Line width
input bool            ShowTooltip  = true;        // Show Tooltip or Not
//--
int bar0=0,
    bar1=0,
    ebar=360;
//--
double pip,
       Price=0,
       Price1=0,
       ePrice[];
//--
long chart_id;
//--- Price handle
double OPEN[];
double HIGH[];
double LOW[];
double CLOSE[];
long   VOLUME[];
datetime TIME[];
//--
string tooltip;
string tooltip1;
string short_name;
//---------//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   //---
   SetIndexBuffer(0,ePrice,INDICATOR_DATA);
   PlotIndexSetString(0,PLOT_LABEL,"Target");
   PlotIndexSetInteger(0,PLOT_SHOW_DATA,true);
   //--
   chart_id=ChartID();
   short_name="iCrosshairClickTarget";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
   IndicatorSetInteger(INDICATOR_DIGITS,Digits());
   //--
   if(Digits()==3||Digits()==5) 
     {pip=Point()*10;}
   else if(Digits()==2||Digits()==4) {pip=Point();}
   if((StringSubstr(Symbol(),0,1)=="X")||(StringSubstr(Symbol(),0,1)=="#")) {pip=Point()*10;}
   //--
   ArrayResize(OPEN,ebar);
   ArrayResize(HIGH,ebar);
   ArrayResize(LOW,ebar);
   ArrayResize(CLOSE,ebar);
   ArrayResize(TIME,ebar);
   ArrayResize(VOLUME,ebar);
   ArrayResize(ePrice,ebar);
   ArraySetAsSeries(OPEN,true);
   ArraySetAsSeries(HIGH,true);
   ArraySetAsSeries(LOW,true);
   ArraySetAsSeries(CLOSE,true);
   ArraySetAsSeries(TIME,true);
   ArraySetAsSeries(VOLUME,true);
   ArraySetAsSeries(ePrice,true);
   //--
   FillArraysBuffers(0,ebar);
   //--
   double PriceMin = ChartGetDouble(chart_id,CHART_PRICE_MIN,0); 
   double PriceMax = ChartGetDouble(chart_id,CHART_PRICE_MAX,0);
   Price1   = NormalizeDouble(PriceMin+((PriceMax-PriceMin)/2),Digits());
   Price    = NormalizeDouble(PriceMin+((PriceMax-PriceMin)/2),Digits());
   double pi= NormalizeDouble(fabs(Price1-Price)/pip,Digits());
   //--
   DrawHVLine(chart_id,"H Line",OBJ_HLINE,TIME[0],Price1,ColorLine,LineStyle,LineWidth,"Click me!"); // update_1: Change Price to Price1
   DrawHVLine(chart_id,"V Line",OBJ_VLINE,TIME[0],Price1,ColorLine,LineStyle,LineWidth,"Click me!"); // update_1: Change Price to Price1
   DrawPriceLevel(chart_id,"DotStart",OBJ_TEXT,TIME[0],Price1,CharToString(119),"Wingdings",14,ColorTarget,"Click me!");
   DrawPriceLevel(chart_id,"DotTarget",OBJ_TEXT,TIME[0],Price1,CharToString(164),"Wingdings",14,ColorTarget,"Click me!");
   //TextTarget(chart_id,"TargetText",OBJ_TEXT,TIME[0],Price1,ColorTarget,0,pi);
   //---
//---
   return(INIT_SUCCEEDED);
  }
//---------//
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//----
   ObjectsDeleteAll(ChartID(),0,-1);
   GlobalVariablesDeleteAll();
//----
   return;
  }
//---------//
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
//---
   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//---------//
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,            // Event identifier
                  const long &lparam,      // Event parameter of long type
                  const double &dparam,    // Event parameter of double type
                  const string &sparam)    // Event parameter of string type
  {
//---
   ResetLastError();
   //--
   static bool keyPressed=false;
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
       FillArraysBuffers(0,ebar);
       if(sparam=="H Line" || sparam=="V Line" || sparam=="DotTarget")
         {
           if(!keyPressed) keyPressed=true;
           else keyPressed=false;
         }
       if(keyPressed) ChartSetInteger(chart_id,CHART_EVENT_MOUSE_MOVE,true);
       else ChartSetInteger(chart_id,CHART_EVENT_MOUSE_MOVE,false);
     }
   //--
//--- this is an event of a mouse move on the chart
   if(id==CHARTEVENT_MOUSE_MOVE)
     {
      //--- Prepare variables
       FillArraysBuffers(0,ebar);
       int x           = (int)lparam;
       int y           = (int)dparam;
       datetime time   = 0;
       int      window = 0;
       Price = 0;
       //--- Convert the X and Y coordinates in terms of date/time
       if(ChartXYToTimePrice(chart_id,x,y,window,time,Price))
         {
           bar0=iBarShift(Symbol(),0,time,false);
           tooltip="Candle: "+(string)bar0+
                   "\nOpen: "+DoubleToString(OPEN[bar0],Digits())+
                   "\nHigh: "+DoubleToString(HIGH[bar0],Digits())+
                   "\nLow: "+DoubleToString(LOW[bar0],Digits())+
                   "\nClose: "+DoubleToString(CLOSE[bar0],Digits())+
                   "\nVolume: "+DoubleToString(VOLUME[bar0],0)+
                   "\n"+
                   "\nPrice: "+DoubleToString(Price,Digits())+
                   "\nUp Wick: "+DoubleToString(upWick(bar0),0)+
                   "\nBody: "+DoubleToString(BarBody(bar0),0)+
                   "\nDn Wick: "+DoubleToString(dnWick(bar0),0)+
                   "\nRangeHL: "+DoubleToString(RangeHL(bar0),0)+
                   "\n";
           //--- draw horizontal and vertical lines
           DrawHVLine(chart_id,"H Line",OBJ_HLINE,time,Price,ColorLine,LineStyle,LineWidth,tooltip);
           DrawHVLine(chart_id,"V Line",OBJ_VLINE,time,Price,ColorLine,LineStyle,LineWidth,tooltip);
         }
       //--
       //--- Prepare variables 
       int x1           = (int)lparam; 
       int y1           = (int)dparam; 
       datetime dt0     = 0; 
       int      window1 = 0;
       int        cand  = 0;
       Price1 = 0;
       //--- Convert the X and Y coordinates in terms of date/time on the target
       if(ChartXYToTimePrice(chart_id,x1,y1,window1,dt0,Price1)) 
         { 
           bar1=iBarShift(Symbol(),0,dt0,false);
           if(bar1<=0) bar1=0;
           if(bar1<=2) cand=0;
           else cand=bar1-2;
           int bars=fabs(bar1-bar0);
           double pips=fabs(Price1-Price)/pip;
           //--
           tooltip="Candle: "+(string)bar0+
                   "\nOpen: "+DoubleToString(OPEN[bar0],Digits())+
                   "\nHigh: "+DoubleToString(HIGH[bar0],Digits())+
                   "\nLow: "+DoubleToString(LOW[bar0],Digits())+
                   "\nClose: "+DoubleToString(CLOSE[bar0],Digits())+
                   "\nVolume: "+DoubleToString(VOLUME[bar0],0)+
                   "\n"+
                   "\nPrice: "+DoubleToString(Price,Digits())+
                   "\nUp Wick: "+DoubleToString(upWick(bar0),0)+
                   "\nBody: "+DoubleToString(BarBody(bar0),0)+
                   "\nDn Wick: "+DoubleToString(dnWick(bar0),0)+
                   "\nRangeHL: "+DoubleToString(RangeHL(bar0),0)+
                   "\n";
           //--
           tooltip1="Candle: "+(string)bar1+
                    "\nBars Distance: "+IntegerToString(bars,2,' ')+
                    "\nPips Distance: "+DoubleToString(pips,1)+
                    "\nPrice: "+DoubleToString(Price1,Digits())+
                    "\n";
           //--
           ObjectDelete(chart_id,"TrendLine");
           ePrice[bar1]=Price1;
           DrawHVLine(chart_id,"H Line",OBJ_HLINE,TIME[bar1],Price1,ColorLine,LineStyle,LineWidth,tooltip);
           DrawHVLine(chart_id,"V Line",OBJ_VLINE,TIME[bar1],Price1,ColorLine,LineStyle,LineWidth,tooltip);
           DrawPriceLevel(chart_id,"DotTarget",OBJ_TEXT,TIME[bar1],Price1,CharToString(164),"Wingdings",14,ColorTarget,tooltip1);
           DrawPriceLevel(chart_id,"DotStart",OBJ_TEXT,TIME[bar0],Price,CharToString(119),"Wingdings",14,ColorTarget,tooltip);
           TextTarget(chart_id,"TargetText",OBJ_TEXT,TIME[cand],Price1,ColorTarget,bars,pips);
         }
       //---
     }
//---
//--- This is an event of a mouse click on the chart 
   if(id==CHARTEVENT_CLICK) 
     { 
      //--- Prepare variables
       FillArraysBuffers(0,ebar);
       int x1           = (int)lparam; 
       int y1           = (int)dparam; 
       datetime dt1     = 0; 
       int      window1 = 0;
       int        cand  = 0;
       Price1 = 0;
       //--- Convert the X and Y coordinates in terms of date/time on the target
       if(ChartXYToTimePrice(chart_id,x1,y1,window1,dt1,Price1)) 
         { 
           bar1=iBarShift(Symbol(),0,dt1,false);
           if(bar1<=0) bar1=0;
           if(bar1<=2) cand=0;
           else cand=bar1-2;
           int bars=fabs(bar1-bar0);
           double pips=fabs(Price1-Price)/pip;
           //--
           tooltip="Candle: "+(string)bar0+
                   "\nOpen: "+DoubleToString(OPEN[bar0],Digits())+
                   "\nHigh: "+DoubleToString(HIGH[bar0],Digits())+
                   "\nLow: "+DoubleToString(LOW[bar0],Digits())+
                   "\nClose: "+DoubleToString(CLOSE[bar0],Digits())+
                   "\nVolume: "+DoubleToString(VOLUME[bar0],0)+
                   "\n"+
                   "\nPrice: "+DoubleToString(Price,Digits())+
                   "\nUp Wick: "+DoubleToString(upWick(bar0),0)+
                   "\nBody: "+DoubleToString(BarBody(bar0),0)+
                   "\nDn Wick: "+DoubleToString(dnWick(bar0),0)+
                   "\nRangeHL: "+DoubleToString(RangeHL(bar0),0)+
                   "\n";
           //--
           tooltip1="Candle: "+(string)bar1+
                    "\nBars Distance: "+IntegerToString(bars,2,' ')+
                    "\nPips Distance: "+DoubleToString(pips,1)+
                    "\nPrice: "+DoubleToString(Price1,Digits())+
                    "\n";
           //--
           ePrice[bar1]=Price1;
           TrendLine(chart_id,"TrendLine",OBJ_TREND,TIME[bar0],Price,TIME[bar1],Price1,ColorTrendLine,0,LineWidth);
           DrawPriceLevel(chart_id,"DotTarget",OBJ_TEXT,TIME[bar1],Price1,CharToString(164),"Wingdings",14,ColorTarget,tooltip1); 
           DrawPriceLevel(chart_id,"DotStart",OBJ_TEXT,TIME[bar0],Price,CharToString(119),"Wingdings",14,ColorTarget,tooltip);
           TextTarget(chart_id,"TargetText",OBJ_TEXT,TIME[cand],Price1,ColorTarget,bars,pips);
         }
     }
   //---
//---
  }
//---------//
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double upWick(int i)
  {
   double upBody=fmax(OPEN[i],CLOSE[i]);
   return(fabs(HIGH[i] - upBody)/pip);
  }
//---------//
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BarBody(int i)
  {
   //double dnBody=fmin(OPEN[i],CLOSE[i]),
   //upBody=fmax(OPEN[i],CLOSE[i]);
   return(fabs(OPEN[i] - CLOSE[i])/pip);
  }
//---------//
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double dnWick(int i)
  {
   double dnBody=fmin(OPEN[i],CLOSE[i]);
   return(fabs(dnBody - LOW[i])/pip);
  }
//---------//
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double RangeHL(int i)
  {
   //double RHL=fmin(HIGH[i],LOW[i]);
   return((HIGH[i]-LOW[i])/pip);
  }
//---------//
//+------------------------------------------------------------------+
//|                Draw Horizontal dan Vertical Line                 |
//+------------------------------------------------------------------+
void DrawHVLine(long        chartid,
                string      name,
                ENUM_OBJECT type,
                datetime    time,
                double      prc,
                color       clr,
                int         style,
                int         width,
                string      tooltips)
  {
//---
   ObjectDelete(chartid,name);
   ObjectCreate(chartid,name,type,0,time,prc); 
   ObjectSetInteger(chartid,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chartid,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chartid,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chartid,name,OBJPROP_BACK,false);
   ObjectSetInteger(chartid,name,OBJPROP_SELECTABLE,true); 
   ObjectSetInteger(chartid,name,OBJPROP_SELECTED,true);
   ObjectSetInteger(chartid,name,OBJPROP_ZORDER,0);
   ObjectSetInteger(chartid,name,OBJPROP_HIDDEN,true);
   if(ShowTooltip) ObjectSetString(chartid,name,OBJPROP_TOOLTIP,tooltips);
   //--
   ChartRedraw(0);
//---
  }
//---------//
//+------------------------------------------------------------------+
//|                         Draw Trend Line                          |
//+------------------------------------------------------------------+
void TrendLine(long        chartid,
               string      name,
               ENUM_OBJECT type,
               datetime    time1,
               double      prc1,
               datetime    time2,
               double      prc2,
               color       clr,
               int         style,
               int         width)
  {
//---
   ObjectDelete(chartid,name);
   ObjectCreate(chartid,name,type,0,time1,prc1,time2,prc2);
   ObjectSetInteger(chartid,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chartid,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chartid,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chartid,name,OBJPROP_BACK,false);
   ObjectSetInteger(chartid,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(chartid,name,OBJPROP_ZORDER,0);
   ObjectSetInteger(chartid,name,OBJPROP_HIDDEN,true);
   //--
   ChartRedraw(0);
//---
  }  
//---------//
//+------------------------------------------------------------------+
//|                        Draw Click Target                         |
//+------------------------------------------------------------------+
void DrawPriceLevel(long        chartid,
                   string      name,
                   ENUM_OBJECT type,
                   datetime    time,
                   double      prc,
                   string      text,
                   string      font_mode,
                   int         font_size,
                   color       clr,
                   string      tooltips)
  {
//---
   ObjectDelete(chartid,name);
   ObjectCreate(chartid,name,type,0,time,prc);
   ObjectSetString(chartid,name,OBJPROP_TEXT,text);
   ObjectSetString(chartid,name,OBJPROP_FONT,font_mode);
   ObjectSetInteger(chartid,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(chartid,name,OBJPROP_ANCHOR,ANCHOR_CENTER);
   ObjectSetInteger(chartid,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chartid,name,OBJPROP_BACK,false);
   ObjectSetInteger(chartid,name,OBJPROP_ZORDER,0);
   ObjectSetInteger(chartid,name,OBJPROP_HIDDEN,true);
   if(ShowTooltip) ObjectSetString(chartid,name,OBJPROP_TOOLTIP,tooltips);
   //--
   ChartRedraw(0);
//---
  }
//---------//
//+------------------------------------------------------------------+
//|                 Draw Text Information on target                  |
//+------------------------------------------------------------------+
void TextTarget(long        chartid,
                string      name,
                ENUM_OBJECT type,
                datetime    time,
                double      prc,
                color       clr,
                int         br,
                double      pips)
  {
//---
   ObjectDelete(chartid,name);
   ObjectCreate(chartid,name,type,0,time,prc);
   ObjectSetString(chartid,name,OBJPROP_TEXT,"[ "+string(br)+"  |  "+DoubleToString(pips,1)+"  |  "+DoubleToString(Price1,Digits())+" ]");
   ObjectSetString(chartid,name,OBJPROP_FONT,"Arial Unicode MS Regular");
   ObjectSetInteger(chartid,name,OBJPROP_FONTSIZE,8);
   ObjectSetInteger(chartid,name,OBJPROP_ANCHOR,ANCHOR_LEFT);
   ObjectSetInteger(chartid,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chartid,name,OBJPROP_BACK,false);
   ObjectSetInteger(chartid,name,OBJPROP_ZORDER,0);
   ObjectSetInteger(chartid,name,OBJPROP_HIDDEN,true);
   //--
   ChartRedraw(0);
//---
  }  
//---------//
//+------------------------------------------------------------------+
//|                      Switch Time Frames                          |   
//+------------------------------------------------------------------+  
ENUM_TIMEFRAMES TFmt5(int tf)
  {
//----
    switch(tf)
     {
      case 0:     return(PERIOD_CURRENT);
      case 1:     return(PERIOD_M1);
      case 5:     return(PERIOD_M5);
      case 15:    return(PERIOD_M15);
      case 30:    return(PERIOD_M30);
      case 60:    return(PERIOD_H1);
      case 240:   return(PERIOD_H4);
      case 1440:  return(PERIOD_D1);
      case 10080: return(PERIOD_W1);
      case 43200: return(PERIOD_MN1);
      default:    return(PERIOD_CURRENT);
     }
//----
  }
//---------//
  
//+------------------------------------------------------------------+ 
//| Filling Price buffers                                            | 
//+------------------------------------------------------------------+ 
bool FillArraysBuffers(int period,         // timeframes
                       int amount)         // number of copied values
  { 
//--- reset error code 
   ResetLastError();
   //--
   ENUM_TIMEFRAMES timeframe=TFmt5(period);
   //--
//--- fill a part of the OHLC array with Price values 
   if(CopyOpen(Symbol(),timeframe,0,amount,OPEN)<1)
     { 
       //--- if the copying fails, tell the error code 
       PrintFormat("Failed to copy data OPEN Price, error code %d",GetLastError());
       //--- quit with zero result
       return(false); 
     } 
    //--
   if(CopyHigh(Symbol(),timeframe,0,amount,HIGH)<1)
     { 
       //--- if the copying fails, tell the error code 
       PrintFormat("Failed to copy data HIGH Price, error code %d",GetLastError());
       //--- quit with zero result
       return(false); 
     } 
    //--
   if(CopyLow(Symbol(),timeframe,0,amount,LOW)<1)
     { 
       //--- if the copying fails, tell the error code 
       PrintFormat("Failed to copy data LOW Price, error code %d",GetLastError());
       //--- quit with zero result
       return(false); 
     } 
    //--
   if(CopyClose(Symbol(),timeframe,0,amount,CLOSE)<1)
     { 
       //--- if the copying fails, tell the error code 
       PrintFormat("Failed to copy data CLOSE Price, error code %d",GetLastError());
       //--- quit with zero result
       return(false); 
     }
    //--
   if(CopyTime(Symbol(),timeframe,0,amount,TIME)<1)
     { 
       //--- if the copying fails, tell the error code 
       PrintFormat("Failed to copy data TIME, error code %d",GetLastError());
       //--- quit with zero result
       return(false); 
     }
   //--
   if(CopyTickVolume(Symbol(),timeframe,0,amount,VOLUME)<1)
     { 
       //--- if the copying fails, tell the error code 
       PrintFormat("Failed to copy data TickVolume, error code %d",GetLastError());
       //--- quit with zero result
       return(false); 
     }
    //--
//--- everything is fine 
   return(true); 
  }
//---------//
//+------------------------------------------------------------------+