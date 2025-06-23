//+------------------------------------------------------------------+
//|                                              Hacking Objects.mq5 |
//|                                            Copyright 2024, phade |
//|                                                 https://mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Software Corp."
#property link      "https://mql5.com"
#property version   "1.00"
#property description "Modification of objects within an EX5 indicator"

#define none 0
#property indicator_chart_window
#property indicator_buffers none
#property indicator_plots   none

string obj_prefix_1 = "PZMDALS-diagonal";
string obj_prefix_2 = "PZMDALS-confluence";

int handle = INVALID_HANDLE;
string indicatorShortName = "";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(){

   if (handle == INVALID_HANDLE){
   //   handle = iCustom(_Symbol, _Period, "Market\\PZ Multidiagonals MT5"); //uncomment this, or use another indicator
      
      if (handle != INVALID_HANDLE){
      
         ChartIndicatorAdd(0, 0, handle);
      }
   }  
   /**** 
   Uncomment this function call to get a list of all the object names. 
   They will be revealed in the Experts tab.
   ****/
   //LogChartObjectNames(); 
   
   // Modify chart objects
   ModifyChartObjects(obj_prefix_1, 2);
   ModifyChartObjects(obj_prefix_2, 20);
   ChartRedraw(0);
   
   indicatorShortName = ChartIndicatorName(0, 0, 1);
   ChartIndicatorDelete(0, 0, indicatorShortName);

   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){

   IndicatorRelease(handle);
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
   // Modify chart objects on every recalculation (new tick)
   ModifyChartObjects(obj_prefix_1, 2);
   ModifyChartObjects(obj_prefix_2, 20);

   return rates_total;
  }
  
//+------------------------------------------------------------------+
//| Log all chart object names to the Experts tab        |
//+------------------------------------------------------------------+
void LogChartObjectNames(){

   int total = ObjectsTotal(0);
   for (int i = 0; i < total; i++){
   
      string name = ObjectName(0,i);
      Print("Chart Object Name: ", name);
   }
}


void ModifyChartObjects(string prefix, int spared)
{
   int totalObjects = ObjectsTotal(0);
   for (int i = totalObjects-1-spared; i >= 0; i--){
      string objName = ObjectName(0, i);
      
      long currentCol = ObjectGetInteger(0, objName, OBJPROP_COLOR);
      
      if (StringFind(objName, prefix) == 0 && currentCol != clrNONE){
         ObjectSetInteger(0, objName, OBJPROP_COLOR, clrNONE);         
         //Print("Modified Object: ", objName);
      }          
   }
   
   
   for (int i = totalObjects-1; i >= totalObjects-spared; i--){
      string objName = ObjectName(0, i);
      
      long currentWidth = ObjectGetInteger(0, objName, OBJPROP_WIDTH);
       
      if (StringFind(objName, obj_prefix_1) == 0 && currentWidth != 3){        
         ObjectSetInteger(0, objName, OBJPROP_WIDTH, 3);        
         //Print("Changed width on object: ", objName); 
      }
   }   
}
