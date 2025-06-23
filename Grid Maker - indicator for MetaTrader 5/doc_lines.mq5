//+------------------------------------------------------------------+
//|                                                    doc_lines.mq5 |
//|                                                    Copyright doc |
//|                                        http://www.forex-tsd.com/ |
//+------------------------------------------------------------------+
#property copyright "doc"
#property link      "http://www.forex-tsd.com/"
#property version   "1.03"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
//--- input parameters
input int     Step           = 1000;                                   // Step for horintal lines
input double  max            = 1.4;                                    // Max price value
input double  min            = 1.2;                                    // Min price value
input string  Settings_H     = "Displacement for horizontal lines";  
input int     Displacement1  = 0;                                      // Level 0
input int     Displacement2  = 100;                                    // Displacement for long entry
input int     Displacement3  = 900;                                    // Displacement for short entry
input int     Displacement4  = 400;                                    // Displacement for TP long
input int     Displacement5  = 600;                                    // Displacement for TP short
input string  Settings_V     = "Hours for vertical lines";  
input string  StartLine0     = "00:00";
input string  StartLine1     = "05:00";
input string  StartLine2     = "08:00";
input string  StartLine3     = "15:30";
input string  StartLine4     = "21:00";

                        // color of vertical lines
color zero    = Red;    // 
color inter   = Khaki;  // 
                        // color of horizontal lines                          
color H_zero  = Red;    // 
color H_entry = Yellow; // 
color H_tp    = Lime;   // 

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,0,OBJ_HLINE);   // delete all horizontal lines
   ObjectsDeleteAll(0,0,OBJ_VLINE);   // delete all vertical lines
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate (const int rates_total,      // rates total
                 const int prev_calculated,  // bars calculated at previous call
                 const datetime& time[],     // Time
                 const double& open[],       // Open
                 const double& high[],       // High
                 const double& low[],        // Low
                 const double& close[],      // Close
                 const long& tick_volume[],  // Tick Volume
                 const long& volume[],       // Real Volume
                 const int& spread[])        // Spread
  {     
   if (_Period>=PERIOD_H4) return(rates_total);

          ObjectsDeleteAll(0,0,OBJ_HLINE); // delete all horizontal lines
          Ris_H_Line();                    // draw horizontal lines      

   int    line_counter=0; // lines counter

   MqlDateTime str,stp;  
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      TimeToStruct(time[i]  ,str);
      TimeToStruct(time[i]-1,stp);

      datetime startTime0  = StringToTime(TimeToString(time[i],TIME_DATE)+" "+StartLine0);
      datetime startTime1  = StringToTime(TimeToString(time[i],TIME_DATE)+" "+StartLine1);
      datetime startTime2  = StringToTime(TimeToString(time[i],TIME_DATE)+" "+StartLine2);
      datetime startTime3  = StringToTime(TimeToString(time[i],TIME_DATE)+" "+StartLine3);
      datetime startTime4  = StringToTime(TimeToString(time[i],TIME_DATE)+" "+StartLine4);


      if(str.day_of_year!=stp.day_of_year)
      {
         if (str.day_of_week>0 && str.day_of_week<6)
         {
            line_counter++;
            SetVLine0("Vline_0_" +string(line_counter),startTime0, zero);
            SetVLine1("Vline_1_" +string(line_counter),startTime1, inter);
            SetVLine1("Vline_2_" +string(line_counter),startTime2, inter);
            SetVLine1("Vline_3_" +string(line_counter),startTime3, inter);
            SetVLine1("Vline_4_" +string(line_counter),startTime4, inter);

         }            
      }
   }
   return(rates_total);
}

//+----------------------------------------------------------------------------+
//|  Description : Set the OBJ_VLINE vertical line                             |
//+----------------------------------------------------------------------------+
//|  Parameters:                                                               |
//|    nm - line name                                                          |
//|    t1 - line time                                                          |
//|    cl - line color                                                         |
//+----------------------------------------------------------------------------+
void SetVLine0(string nm,datetime t1,color cl=Red)
  {
   if(t1<=0) return;
   if(ObjectFind(0,nm)<0) ObjectCreate(0,nm,OBJ_VLINE,0,t1,2);
   ObjectSetInteger(0,nm,OBJPROP_TIME,t1);
   ObjectSetInteger(0,nm,OBJPROP_COLOR,cl);
   ObjectSetInteger(0,nm,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSetInteger(0,nm,OBJPROP_WIDTH,     1);         
   ObjectSetInteger(0,nm,OBJPROP_BACK,      true);      
   ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);      
  }
//+----------------------------------------------------------------------------+
void SetVLine1(string lm,datetime t2,color c2=Red)
  {
   if(t2<=0) return;
   if(ObjectFind(0,lm)<0) ObjectCreate(0,lm,OBJ_VLINE,0,t2,2);
   ObjectSetInteger(0,lm,OBJPROP_TIME,t2);
   ObjectSetInteger(0,lm,OBJPROP_COLOR,c2);
   ObjectSetInteger(0,lm,OBJPROP_STYLE,STYLE_DOT);
   ObjectSetInteger(0,lm,OBJPROP_WIDTH,     1);          
   ObjectSetInteger(0,lm,OBJPROP_BACK,      true);      
   ObjectSetInteger(0,lm,OBJPROP_SELECTABLE,false);     
  }
//+----------------------------------------------------------------------------+
//|  Description : Set the OBJ_HLINE horizontal line                           |
//+----------------------------------------------------------------------------+
//|  Parameters:                                                               |
//|    nm - line name                                                          |
//|    p1 - price                                                              |
//|    cl - line color                                                         |
//+----------------------------------------------------------------------------+
void SetHLine1(string nm,double p1,color cl=Red)
  {
   if(ObjectFind(0,nm)<0) ObjectCreate(0,nm,OBJ_HLINE,0,0,p1);
   ObjectSetInteger(0,nm,OBJPROP_COLOR,     cl);           
   ObjectSetInteger(0,nm,OBJPROP_STYLE,     STYLE_SOLID);
   ObjectSetInteger(0,nm,OBJPROP_WIDTH,     1);          
   ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);          
  }

void SetHLine2(string xc,double p2,color c2=Red)
  {
   if(ObjectFind(0,xc)<0) ObjectCreate(0,xc,OBJ_HLINE,0,0,p2);
   ObjectSetInteger(0,xc,OBJPROP_COLOR,     c2);         
   ObjectSetInteger(0,xc,OBJPROP_STYLE,     STYLE_DASH);
   ObjectSetInteger(0,xc,OBJPROP_WIDTH,     1);          
   ObjectSetInteger(0,xc,OBJPROP_SELECTABLE,false);      
  }

void SetHLine3(string xv,double p3,color c3=Red)
  {
   if(ObjectFind(0,xv)<0) ObjectCreate(0,xv,OBJ_HLINE,0,0,p3);
   ObjectSetInteger(0,xv,OBJPROP_COLOR,     c3);         
   ObjectSetInteger(0,xv,OBJPROP_STYLE,     STYLE_SOLID);
   ObjectSetInteger(0,xv,OBJPROP_WIDTH,     1);          
   ObjectSetInteger(0,xv,OBJPROP_SELECTABLE,false);      
  }
//+----------------------------------------------------------------------------+
//|  Description : Horizontal lines setting                                    |
//+----------------------------------------------------------------------------+
void Ris_H_Line()
  {
   double Uroven1 =0.0;             // level of first horizontal line
   double Uroven2 =0.0;             
   double Uroven3 =0.0; 
   double Uroven4 =0.0; 
   double Uroven5 =0.0;
            
   int    line_counter=0,          // lines counter
          i=0;                     // passes counter
//--- start drawing
   while(Uroven1<=max)
     {
      i++;
      Uroven1  = (i*Step+Displacement1) *_Point;
      Uroven2  = (i*Step+Displacement2) *_Point;
      Uroven3  = (i*Step+Displacement3) *_Point;
      Uroven4  = (i*Step+Displacement4) *_Point;
      Uroven5  = (i*Step+Displacement5) *_Point;


      if(Uroven1>=min)
        {
         line_counter++;
         SetHLine1 ("Hline_0_"  +string(line_counter),Uroven1, H_zero);
         SetHLine2 ("Hline_1_"  +string(line_counter),Uroven2, H_entry);
         SetHLine2 ("Hline_2_"  +string(line_counter),Uroven3, H_entry);
         SetHLine3 ("Hline_3_"  +string(line_counter),Uroven4, H_tp);
         SetHLine3 ("Hline_4_"  +string(line_counter),Uroven5, H_tp);
        }
     }// end while (Uroven<=Max)
   ChartRedraw();
  }