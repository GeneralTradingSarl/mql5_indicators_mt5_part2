//+------------------------------------------------------------------+
//|                                                     Ichimoku.mq5 |
//|                        Copyright 2009, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "2010, MetaQuotes Software Corp."
#property link      "http://www.mql5.com"
#property description "Ichimoku Kinko Hyo"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   5
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_FILLING
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_COLOR_HISTOGRAM2
#property indicator_color1  Red
#property indicator_color2  Blue
#property indicator_color3  PaleTurquoise,LavenderBlush
#property indicator_color4  Lime
#property indicator_color5  Red,Blue
#property indicator_label1  "Tenkan-sen"
#property indicator_label2  "Kijun-sen"
#property indicator_label3  "Senkou Span A;Senkou Span B"
#property indicator_label4  "Chinkou Span"
#property indicator_label5  "Sen"
#property indicator_style5  STYLE_DASHDOTDOT
#property indicator_width5  1
//--- input parameters
input int InpTenkan=9;     // Tenkan-sen
input int InpKijun=26;     // Kijun-sen
input int InpSenkou=52;    // Senkou Span B
//--- indicator buffers
double    ExtTenkanBuffer[];
double    ExtKijunBuffer[];
double    ExtSpanABuffer[];
double    ExtSpanBBuffer[];
double    ExtChinkouBuffer[];
double    ExtTenkanBuffer1[];
double    ExtKijunBuffer1[];
double    ExtColorBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtTenkanBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtKijunBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtSpanABuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtSpanBBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,ExtChinkouBuffer,INDICATOR_DATA);
   SetIndexBuffer(5,ExtTenkanBuffer1,INDICATOR_DATA);
   SetIndexBuffer(6,ExtKijunBuffer1,INDICATOR_DATA);
   SetIndexBuffer(7,ExtColorBuffer,INDICATOR_COLOR_INDEX);
//---- индексация элементов в буферах как в таймсериях   
   ArraySetAsSeries(ExtTenkanBuffer,true);
   ArraySetAsSeries(ExtKijunBuffer,true);  
   ArraySetAsSeries(ExtSpanABuffer,true);
   ArraySetAsSeries(ExtSpanBBuffer,true); 
   ArraySetAsSeries(ExtChinkouBuffer,true);
   ArraySetAsSeries(ExtTenkanBuffer1,true);
   ArraySetAsSeries(ExtKijunBuffer1,true);  
   ArraySetAsSeries(ExtColorBuffer,true);
//---
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,InpTenkan);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpKijun);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,InpSenkou-1);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,InpTenkan);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,InpKijun);
   PlotIndexSetInteger(5,PLOT_DRAW_BEGIN,MathMax(InpTenkan,InpKijun));
//--- lines shifts when drawing
   PlotIndexSetInteger(2,PLOT_SHIFT,InpKijun);
   PlotIndexSetInteger(3,PLOT_SHIFT,-InpKijun);
//--- change labels for DataWindow 
   PlotIndexSetString(0,PLOT_LABEL,"Tenkan-sen("+string(InpTenkan)+")");
   PlotIndexSetString(1,PLOT_LABEL,"Kijun-sen("+string(InpKijun)+")");
   PlotIndexSetString(2,PLOT_LABEL,"Senkou Span A;Senkou Span B("+string(InpSenkou)+")");
//--- initialization done
  }
//+------------------------------------------------------------------+
//| Ichimoku Kinko Hyo                                               |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
   int limit;
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);  
   ArraySetAsSeries(Close,true);
//---
   if(prev_calculated==0) limit=0;
   else                   limit=prev_calculated-1;
//---
   for(int i=limit;i<rates_total && !IsStopped();i++)
     {
      ExtChinkouBuffer[i]=Close[i];
      //--- tenkan sen
      double high=High[ArrayMaximum(High,i,InpTenkan)];
      double low=Low[ArrayMinimum(Low,i,InpTenkan)];
      ExtTenkanBuffer[i]=ExtTenkanBuffer1[i]=(high+low)/2.0;
      //--- kijun sen
      high=High[ArrayMaximum(High,i,InpKijun)];
      low=Low[ArrayMinimum(Low,i,InpKijun)];
      ExtKijunBuffer[i]=ExtKijunBuffer1[i]=(high+low)/2.0;
      //--- senkou span a
      ExtSpanABuffer[i]=(ExtTenkanBuffer[i]+ExtKijunBuffer[i])/2.0;
      //--- senkou span b
      high=High[ArrayMaximum(High,i,InpSenkou)];
      low=Low[ArrayMinimum(Low,i,InpSenkou)];
      ExtSpanBBuffer[i]=(high+low)/2.0;
      if(ExtKijunBuffer[i]<ExtTenkanBuffer[i]) ExtColorBuffer[i]=1;
      else ExtColorBuffer[i]=0;
     }
//--- done
   return(rates_total);
  }
//+------------------------------------------------------------------+
