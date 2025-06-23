//+------------------------------------------------------------------+
//|                                                   quantile bands |
//+------------------------------------------------------------------+
#property link      "www.forex-tsd.com"
#property copyright "www.forex-tsd.com"

#property indicator_chart_window
#property indicator_buffers 13
#property indicator_plots   9
#property indicator_label1  "upper filling"
#property indicator_type1   DRAW_FILLING
#property indicator_color1  C'221,247,221'
#property indicator_label2  "lower filling"
#property indicator_type2   DRAW_FILLING
#property indicator_color2  C'253,238,227'
#property indicator_label3  "Upper band"
#property indicator_type3   DRAW_COLOR_LINE
#property indicator_color3  clrLimeGreen,clrSandyBrown
#property indicator_width3  3
#property indicator_label4  "Lower band"
#property indicator_type4   DRAW_COLOR_LINE
#property indicator_color4  clrLimeGreen,clrSandyBrown
#property indicator_width4  3
#property indicator_label5  "Middle value"
#property indicator_color5  clrDarkGray
#property indicator_type5   DRAW_LINE
#property indicator_width5  2
#property indicator_label6  "value 0.236"
#property indicator_color6  clrDarkGray
#property indicator_type6   DRAW_LINE
#property indicator_style6  STYLE_DOT
#property indicator_label7  "value 0.382"
#property indicator_color7  clrDarkGray
#property indicator_type7   DRAW_LINE
#property indicator_style7  STYLE_DOT
#property indicator_label8  "value 0.618"
#property indicator_color8  clrDarkGray
#property indicator_type8   DRAW_LINE
#property indicator_style8  STYLE_DOT
#property indicator_label9  "value 0.764"
#property indicator_color9  clrDarkGray
#property indicator_type9   DRAW_LINE
#property indicator_style9  STYLE_DOT

//
//
//
//
//

input int HighLowPeriod = 50; // High/low period

//
//
//
//
//

double bufferUp[],bufferUpc[];
double bufferDn[],bufferDnc[];
double bufferMe[],fupu[],fupd[],fdnd[],fdnu[],lev1[],lev2[],lev3[],lev4[];

//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

int OnInit()
{
   SetIndexBuffer( 0,fupu,INDICATOR_DATA);      SetIndexBuffer(1,fupd,INDICATOR_DATA);
   SetIndexBuffer( 2,fdnu,INDICATOR_DATA);      SetIndexBuffer(3,fdnd,INDICATOR_DATA);
   SetIndexBuffer( 4,bufferUp ,INDICATOR_DATA); SetIndexBuffer(5,bufferUpc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer( 6,bufferDn ,INDICATOR_DATA); SetIndexBuffer(7,bufferDnc,INDICATOR_COLOR_INDEX);
   SetIndexBuffer( 8,bufferMe ,INDICATOR_DATA);
   SetIndexBuffer( 9,lev1     ,INDICATOR_DATA);
   SetIndexBuffer(10,lev2     ,INDICATOR_DATA);
   SetIndexBuffer(11,lev3     ,INDICATOR_DATA);
   SetIndexBuffer(12,lev4     ,INDICATOR_DATA);
   return(0);
}
void OnDeinit(const int reason) { return; }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//
//

int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const datetime& time[],
                 const double& open[],
                 const double& high[],
                 const double& low[],
                 const double& close[],
                 const long& tick_volume[],
                 const long& volume[],
                 const int& spread[])
{
   if (Bars(_Symbol,_Period)<rates_total) return(-1);
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total && !IsStopped(); i++)
   {
      double hh = high[i];
      double ll = low[i];
      for (int k=1; k<HighLowPeriod && (i-k)>=0; k++)
      {
         hh = MathMax(hh,high[i-k]);
         ll = MathMin(ll,low [i-k]);
      }
      double rng = hh-ll;
      bufferUp[i] = hh;
      bufferDn[i] = ll;
      bufferMe[i] = (hh+ll)/2;
      lev1[i]     = ll+0.236*rng;
      lev2[i]     = ll+0.382*rng;
      lev3[i]     = ll+0.618*rng;
      lev4[i]     = ll+0.764*rng;
      fupd[i]     = bufferMe[i]; fupu[i] = bufferUp[i]; 
      fdnu[i]     = bufferMe[i]; fdnd[i] = bufferDn[i]; 
      if (i>0)
      {
         bufferUpc[i] = bufferUpc[i-1];
         bufferDnc[i] = bufferDnc[i-1];

         //
         //
         //
         //
         //
                           
         if (bufferUp[i]>bufferUp[i-1]) bufferUpc[i] = 0;
         if (bufferUp[i]<bufferUp[i-1]) bufferUpc[i] = 1;
         if (bufferDn[i]>bufferDn[i-1]) bufferDnc[i] = 0;
         if (bufferDn[i]<bufferDn[i-1]) bufferDnc[i] = 1;
      }                     
   }         
   return(rates_total);         
}

