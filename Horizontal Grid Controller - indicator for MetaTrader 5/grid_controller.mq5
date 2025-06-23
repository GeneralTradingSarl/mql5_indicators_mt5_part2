//+------------------------------------------------------------------+
//|                                              Grid_Controller.mq5 |
//|                                      Rajesh Nait, Copyright 2023 |
//|                  https://www.mql5.com/en/users/rajeshnait/seller |
//+------------------------------------------------------------------+
#property copyright "Rajesh Nait, Copyright 2023"
#property link      "https://www.mql5.com/en/users/rajeshnait/seller"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

//--- input parameters
input int Step=50;              // vertical grid step in points
input int Figure=1000;           // figure step
input int MaxBars=0;             // bars in history (0 - all history)
input color    new_Hfigure=clrDimGray;  // new figure
input color    new_Hline  =clrDimGray;    // new line
int step;
string prefix="grid_";

datetime old_Times[21]= {0};     // array for old times
string      line_name;     // line name
int         line_counter;   // line counter
int         start_pos;      // starting position
uint        start_time;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   CheckOtherTimeFrames(_Symbol);
   step=Step;
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//  EventKillTimer();
   ObjectsDeleteAll(0,prefix);   // delete all horizontal lines
   Comment("");
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

//--- check other timeframes
   if(rates_total<0) return(0);
   if(!CheckOtherTimeFrames(_Symbol)) {
      //Print("Other timeframes are not ready...");
      return(prev_calculated);
   }
//--- first call
   if(prev_calculated==0) {
      Play();
      if(MaxBars!=0) if(MaxBars<rates_total) start_pos=rates_total-MaxBars;
   } else start_pos=prev_calculated-1;
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
//---


   if(id==CHARTEVENT_KEYDOWN) {

      switch(int(lparam)) {

      case 76 : //L = Next
         if(step>=1) {
            step=step+1;
            Play();
         }
         break;


      case 75  : // K Previous
         if(step>=1) {
            step=step-1;
            Play();
         }
         break;

      case 74: // J Reset
         if(step>=1) {
            step=Step;
            Play();
         }
         break;
      }
   }


}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Play() {
//MqlDateTime str;
   line_name="";     // line name
   line_counter=0;   // line counter
   start_pos=0;      // starting position
   start_time=GetTickCount();       //
   //ObjectsDeleteAll(0,0,OBJ_VLINE); // delete all vertical lines
   ObjectsDeleteAll(0,prefix); // delete all horizontal lines
   Ris_H_Line();                    // draw horizontal lines
   ArrayInitialize(old_Times,0);    // initialize array'
   Comment("Steps ",step);
   // calc start [os

}
//+----------------------------------------------------------------------------+
//|  Description : Set the OBJ_HLINE horizontal line                           |
//+----------------------------------------------------------------------------+
//|  Parameters:                                                               |
//|    nm - line name                                                          |
//|    p1 - price                                                              |
//|    cl - line color                                                         |
//+----------------------------------------------------------------------------+
void SetHLine(string nm,double p1,color cl=Red) {
//--- create object if it absent
   if(ObjectFind(0,nm)<0) ObjectCreate(0,nm,OBJ_HLINE,0,0,p1);
//--- set object properties
   ObjectSetInteger(0,nm,OBJPROP_COLOR,     cl);         // color
   ObjectSetInteger(0,nm,OBJPROP_STYLE,     STYLE_DOT);  // style
   ObjectSetInteger(0,nm,OBJPROP_WIDTH,     1);          // line width
   ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);      // disable selection
}
//+----------------------------------------------------------------------------+
//|  Description : Horizontal lines setting                                    |
//+----------------------------------------------------------------------------+
void Ris_H_Line() {
   double Uroven=0.0;      // level of first horizontal line
   int    rez,i=0;;             // is it figure or not
   line_counter=0;         // lines counter
   // passes counter

//--- max and min points
   double mass[],
          max=10,
          min= 0;
   int    index;

   ArraySetAsSeries(mass,true);

   if(CopyHigh(_Symbol,PERIOD_MN1,0,Bars(_Symbol,PERIOD_MN1),mass)>2) {
      index=ArrayMaximum(mass,0,WHOLE_ARRAY);
      CopyHigh(_Symbol,PERIOD_MN1,index,1,mass);
      max=mass[0];
   }
   if(CopyLow(_Symbol,PERIOD_MN1,0,Bars(_Symbol,PERIOD_MN1),mass)>2) {
      index=ArrayMinimum(mass,0,WHOLE_ARRAY);
      CopyLow(_Symbol,PERIOD_MN1,index,1,mass);
      min=mass[0];
   }
//--- start drawing
   while(Uroven<=max) {
      i++;
      Uroven=i*step*_Point;
      if(Uroven>=min) {
         line_counter++;
         rez=(int)MathMod(Uroven*MathPow(10,_Digits),Figure); // mod=0
         if(rez==0) {
            // draw up to W1
            if(_Period<PERIOD_W1) SetHLine(prefix+"HLine_"+string(line_counter),Uroven,new_Hfigure);
         } else
            // the intermediate level up to M30
            if(_Period<PERIOD_M30) SetHLine(prefix+"HLine_"+string(line_counter),Uroven,new_Hline);
      }// end if(Uroven>=Min)
   }// end while (Uroven<=Max)
   ChartRedraw();
}
//+------------------------------------------------------------------+
//| Checking of timeframe (async call)                                |
//+------------------------------------------------------------------+
bool CheckOtherTimeFrames(string symbol) {
   datetime ctm[1];
   datetime checktime=TimeGMT()-86400*60;  // 2 months ago
   bool     res=true;
//--- request each timeframe to "update" it
   if(CopyTime(symbol,PERIOD_H1,checktime,1,ctm)!=1) res=false;
   if(CopyTime(symbol,PERIOD_D1,checktime,1,ctm)!=1) res=false;
   if(CopyTime(symbol,PERIOD_W1,checktime,1,ctm)!=1) res=false;
   if(CopyTime(symbol,PERIOD_MN1,checktime,1,ctm)!=1) res=false;
//--- return result
   return(res);
}
//+------------------------------------------------------------------+
