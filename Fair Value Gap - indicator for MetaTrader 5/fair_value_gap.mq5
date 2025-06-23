//+------------------------------------------------------------------+
//|                                               Fair_Value_Gap.mq5 |
//|                                Copyright 2024, Rajesh Kumar Nait |
//|                  https://www.mql5.com/en/users/rajeshnait/seller |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Rajesh Kumar Nait"
#property link      "https://www.mql5.com/en/users/rajeshnait/seller"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0


//--- input parameters
input color             InpColorToUP   =  clrLime;      // Color of the gap up
input color             InpColorToDN   =  clrDeepPink;  // Color of the gap down
input int maxbars = 300;// how many bars to Look back

string prefix;
double price;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   prefix=MQLInfoString(MQL_PROGRAM_NAME)+"_";
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   ObjectsDeleteAll(0,prefix);
   ChartRedraw();
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
                const int &spread[]) {
//---
   if(rates_total<4) return 0;
   price = close[0];
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(time,true);
   int limit=rates_total-prev_calculated;
   if(limit>1) {
      limit=rates_total-5;
   }
   for(int i=maxbars; i>=0 && !IsStopped(); i--) {
      if(low[i]-high[i+2]>=Point()) {

         double up=fmin(high[i],low[i]);
         double dn=fmax(high[i+2],low[i+2]);

         DrawArea(i,up,dn,time,InpColorToUP,1);

      }
      if(low[i+2]-high[i]>=Point()) {

         double up=fmin(high[i+2],low[i+2]);
         double dn=fmax(high[i],low[i]);
         DrawArea(i,up,dn,time,InpColorToDN,0);

      }
   }



//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawArea(const int index, const double price_up,const double price_dn,const datetime &time[],const color color_area,const char dir) {
   string name=prefix+(dir>0 ? "up_" : "dn_")+TimeToString(time[index]);

   if(ObjectFind(0,name)<0 )
      ObjectCreate(0,name,OBJ_RECTANGLE,0,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_FILL,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"\n");
//---
   ObjectSetInteger(0,name,OBJPROP_COLOR,color_area);
   ObjectSetInteger(0,name,OBJPROP_TIME,0,time[index+2]);
   ObjectSetInteger(0,name,OBJPROP_TIME,1,time[index]);
   ObjectSetDouble(0,name,OBJPROP_PRICE,0,price_up);
   ObjectSetDouble(0,name,OBJPROP_PRICE,1,price_dn);

}
//+------------------------------------------------------------------+
