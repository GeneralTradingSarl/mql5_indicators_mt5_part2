//+------------------------------------------------------------------+
//|                                            histogram_bid_ask.mq5 |
//|                                           Copyright 2016, DC2008 |
//|                              http://www.mql5.com/ru/users/dc2008 |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2016, DC2008"
#property link          "http://www.mql5.com/ru/users/dc2008"
#property version       "1.00"
#property description   "Histogram bid and ask prices"
//---
#property indicator_chart_window
//--- Количество буферов для расчета индикатора
#property indicator_buffers 0
//--- Количество графических серий в индикаторе
#property indicator_plots   0
//--- Макросы
#define  HSIZE    10    // масштаб диаграммы
#define  WIDTH    2     // толщина линий
#define  ObjSet1  ObjectSetInteger(0,name,OBJPROP_WIDTH,WIDTH)
#define  ObjSet2  ObjectSetDouble(0,name,OBJPROP_PRICE,0,price)
#define  ObjSet3  ObjectSetInteger(0,name,OBJPROP_TIME,0,time)
#define  ObjSet4  ObjectSetDouble(0,name,OBJPROP_PRICE,1,price)
#define  ObjSet   ObjSet1;ObjSet2;ObjSet3;ObjSet4
//---
datetime prevTimeBar=0;
//+------------------------------------------------------------------+
//| Перечисление hPrice                                              |
//+------------------------------------------------------------------+
enum hPrice
  {
   bid_and_ask,
   high_and_low,
   open_and_close
  };
input hPrice       histogram=bid_and_ask; // Prices for the analysis
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectsDeleteAll(0,0,-1);
   ChartRedraw(0);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,0,-1);
   ChartRedraw(0);
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
//---
   ArraySetAsSeries(time,true);

   if(histogram==bid_and_ask)
     {
      MqlTick price;
      SymbolInfoTick(_Symbol,price);
      DrawHistogram(true,"+ ask=",price.ask,time[0]);
      DrawHistogram(false,"- bid=",price.bid,time[0]);
     }

   if(histogram==high_and_low)
     {
      ArraySetAsSeries(high,true);
      ArraySetAsSeries(low,true);
      DrawHistogram(true,"+ high=",high[0],time[0]);
      DrawHistogram(false,"- low=",low[0],time[0]);
     }

   if(histogram==open_and_close)
     {
      ArraySetAsSeries(close,true);
      ArraySetAsSeries(open,true);
      DrawHistogram(true,"+ close=",close[0],time[0]);
      DrawHistogram(false,"- open=",open[0],time[0]);
     }

//--- Смещение диаграммы на новый бар
   if(time[0]>prevTimeBar)
     {
      prevTimeBar=time[0];
      for(int obj=ObjectsTotal(0,0,-1)-1;obj>=0;obj--)
        {
         string obj_name=ObjectName(0,obj,0,-1);
         if(StringFind(obj_name,"+",0)>=0)
           {
            ObjectSetInteger(0,obj_name,OBJPROP_TIME,0,time[0]);
            string str=ObjectGetString(0,obj_name,OBJPROP_TEXT);
            string strint=StringSubstr(str,1);
            long n=StringToInteger(strint);
            ObjectSetInteger(0,obj_name,OBJPROP_TIME,1,time[0]+HSIZE*n);
            ObjectSetInteger(0,obj_name,OBJPROP_COLOR,clrLightCoral);
           }
         if(StringFind(obj_name,"-",0)>=0)
           {
            ObjectSetInteger(0,obj_name,OBJPROP_TIME,0,time[0]);
            string str=ObjectGetString(0,obj_name,OBJPROP_TEXT);
            string strint=StringSubstr(str,1);
            long n=StringToInteger(strint);
            ObjectSetInteger(0,obj_name,OBJPROP_TIME,1,time[0]-HSIZE*n);
            ObjectSetInteger(0,obj_name,OBJPROP_COLOR,clrSkyBlue);
           }
        }
     }
//---
   ChartRedraw(0);

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| DrawHistogram function                                           |
//+------------------------------------------------------------------+
void DrawHistogram(bool draw,string h_name,double price,datetime time)
  {
   if(draw)
     {
      string name=h_name+(string)price;
      ObjectCreate(0,name,OBJ_TREND,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clrRed);
      ObjSet;
      if(StringFind(ObjectGetString(0,name,OBJPROP_TEXT),"*",0)<0)
        {
         ObjectSetString(0,name,OBJPROP_TEXT,"*1");
         ObjectSetInteger(0,name,OBJPROP_TIME,1,time+HSIZE);
        }
      else
        {
         string str=ObjectGetString(0,name,OBJPROP_TEXT);
         string strint=StringSubstr(str,1);
         long n=StringToInteger(strint);
         n++;
         ObjectSetString(0,name,OBJPROP_TEXT,"*"+(string)n);
         ObjectSetInteger(0,name,OBJPROP_TIME,1,time+HSIZE*n);
        }
     }
   if(!draw)
     {
      string name=h_name+(string)price;
      ObjectCreate(0,name,OBJ_TREND,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clrBlue);
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
      ObjSet;
      if(StringFind(ObjectGetString(0,name,OBJPROP_TEXT),"*",0)<0)
        {
         ObjectSetString(0,name,OBJPROP_TEXT,"*1");
         ObjectSetInteger(0,name,OBJPROP_TIME,1,time-HSIZE);
        }
      else
        {
         string str=ObjectGetString(0,name,OBJPROP_TEXT);
         string strint=StringSubstr(str,1);
         long n=StringToInteger(strint);
         n++;
         ObjectSetString(0,name,OBJPROP_TEXT,"*"+(string)n);
         ObjectSetInteger(0,name,OBJPROP_TIME,1,time-HSIZE*n);
        }
     }
  }
//+------------------------------------------------------------------+
