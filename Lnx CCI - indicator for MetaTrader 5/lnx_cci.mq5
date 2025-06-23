//+------------------------------------------------------------------+
//|                                                      Lnx CCI.mq5 |
//|                                                  coded by mladen |
//+------------------------------------------------------------------+
#property copyright "www.forex-tsd.com"
#property link      "www.forex-tsd.com"
#property version   "1.00"


#property indicator_separate_window
#property indicator_buffers    15
#property indicator_plots      5
#property indicator_level1     100
#property indicator_level2     200
#property indicator_level3     300
#property indicator_level4    -100
#property indicator_level5    -200
#property indicator_level6    -300
#property indicator_levelcolor DimGray


//
//
//
//
//

#property indicator_label1  "CCI"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  DimGray,Green,Red,Yellow
#property indicator_width1  2
#property indicator_label2  "CCI"
#property indicator_type2   DRAW_LINE
#property indicator_color2  DimGray
#property indicator_width2  1
#property indicator_label3  "Turbo CCI"
#property indicator_color3  Gold
#property indicator_width3  1
#property indicator_label4  "LSMA trend"
#property indicator_color4  Green,Red
#property indicator_width4  4
#property indicator_label5  "EMA trend"
#property indicator_color5  Green,Red
#property indicator_width5  4

//
//
//
//
//

input int                CCIPeriod      =  14;         // CCI calculation period
input int                TrendPeriod    =   6;         // Number of bars determining trend
input string _0                         =  "";         // Turbo CCI parameters
input bool               ShowTurboCCI   = false;       // Show turbo CCI
input int                TurboCCIPeriod =   5;         // Turbo CCI calculation period
input string _1                         =  "";         // LSMA parameters
input bool               ShowLSMA       = true;        // Show LSMA trend
input int                LSMAPeriod     =  25;         // LSMA period
input ENUM_APPLIED_PRICE LSMAPrice      = PRICE_CLOSE; // LSMA aplied price
input int                LSMAPosition   =  10;         // LSMA drawing position
input string _2                         =  "";         // EMA parameters
input bool               ShowEMA        = true;        // Show EMA trend 
input int                EMAPeriod      =  34;         // EMA period
input ENUM_APPLIED_PRICE EMAPrice       = PRICE_CLOSE; // EMA aplied price
input int                EMAPosition    = -10;         // EMA drawing position


//
//
//
//
//

double CCIHisto[];
double CCIColors[];
double CCILine[];
double TurboCCILine[];
double LSMALine[];
double LSMAColors[];
double EMALine[];
double EMAColors[];
double TrendBufferUp[];
double TrendBufferDn[];

//
//
//
//
//

double LsmaMABuffer1[];
double LsmaMABuffer2[];
double EmaMABuffer[];
double CCIBuffer[];
double TurboCCIBuffer[];

int LsmaMaHandle1;
int LsmaMaHandle2;
int EmaMaHandle;
int CCIHandle;
int TurboCCIHandle;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//

int OnInit()
{
   SetIndexBuffer( 0,CCIHisto      ,INDICATOR_DATA);         ArraySetAsSeries(CCIHisto      ,true);
   SetIndexBuffer( 1,CCIColors     ,INDICATOR_COLOR_INDEX);  ArraySetAsSeries(CCIColors     ,true);
   SetIndexBuffer( 2,CCILine       ,INDICATOR_DATA);         ArraySetAsSeries(CCILine       ,true);
   SetIndexBuffer( 3,TurboCCILine  ,INDICATOR_DATA);         ArraySetAsSeries(TurboCCILine  ,true);
   SetIndexBuffer( 4,LSMALine      ,INDICATOR_DATA);         ArraySetAsSeries(LSMALine      ,true);
   SetIndexBuffer( 5,LSMAColors    ,INDICATOR_COLOR_INDEX);  ArraySetAsSeries(LSMAColors    ,true);
   SetIndexBuffer( 6,EMALine       ,INDICATOR_DATA);         ArraySetAsSeries(EMALine       ,true);
   SetIndexBuffer( 7,EMAColors     ,INDICATOR_COLOR_INDEX);  ArraySetAsSeries(EMAColors     ,true);

   SetIndexBuffer( 8,LsmaMABuffer1 ,INDICATOR_CALCULATIONS); ArraySetAsSeries(LsmaMABuffer1 ,true);
   SetIndexBuffer( 9,LsmaMABuffer2 ,INDICATOR_CALCULATIONS); ArraySetAsSeries(LsmaMABuffer2 ,true);
   SetIndexBuffer(10,EmaMABuffer   ,INDICATOR_CALCULATIONS); ArraySetAsSeries(EmaMABuffer   ,true);
   SetIndexBuffer(11,CCIBuffer     ,INDICATOR_CALCULATIONS); ArraySetAsSeries(CCIBuffer     ,true);
   SetIndexBuffer(12,TurboCCIBuffer,INDICATOR_CALCULATIONS); ArraySetAsSeries(TurboCCIBuffer,true);
   SetIndexBuffer(13,TrendBufferUp ,INDICATOR_CALCULATIONS); ArraySetAsSeries(TrendBufferUp ,true);
   SetIndexBuffer(14,TrendBufferDn ,INDICATOR_CALCULATIONS); ArraySetAsSeries(TrendBufferDn ,true);

   //
   //
   //
   //
   //
   
         if (ShowTurboCCI)
               PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_LINE);
         else  PlotIndexSetInteger(2,PLOT_DRAW_TYPE,DRAW_NONE);
         if (ShowLSMA)
               PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_COLOR_LINE);
         else  PlotIndexSetInteger(3,PLOT_DRAW_TYPE,DRAW_NONE);
         if (ShowEMA)
               PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_COLOR_LINE);
         else  PlotIndexSetInteger(4,PLOT_DRAW_TYPE,DRAW_NONE);

   //
   //
   //
   //
   //

      int cLSMAPeriod     = (LSMAPeriod>0)    ? LSMAPeriod     : 1;
      int cEMAPeriod      = (EMAPeriod>0)     ? EMAPeriod      : 1;
      int cCCIPeriod      = (CCIPeriod>0)     ? CCIPeriod      : 1;
      int cTurboCCIPeriod = (TurboCCIPeriod>0)? TurboCCIPeriod : 1;
      
         LsmaMaHandle1  = iMA(NULL,0,cLSMAPeriod,0,MODE_SMA ,LSMAPrice);
         LsmaMaHandle2  = iMA(NULL,0,cLSMAPeriod,0,MODE_LWMA,LSMAPrice);
         EmaMaHandle    = iMA(NULL,0,cEMAPeriod ,0,MODE_EMA ,EMAPrice);
         CCIHandle      = iCCI(NULL,0,cCCIPeriod     ,PRICE_TYPICAL);
         TurboCCIHandle = iCCI(NULL,0,cTurboCCIPeriod,PRICE_TYPICAL);

   //
   //
   //
   //
   //
   
   IndicatorSetString(INDICATOR_SHORTNAME,"Lnx CCI ("+(string)CCIPeriod+","+(string)TurboCCIPeriod+")");
   return(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//

int OnCalculate(const int rates_total,
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

   //
   //
   //
   //
   //
      
      int limit = rates_total-prev_calculated; if (prev_calculated > 0) limit++;
         if (!checkCalculated(LsmaMaHandle1 ,rates_total,"LSMA MA 1"))         return(prev_calculated);
         if (!checkCalculated(LsmaMaHandle2 ,rates_total,"LSMA MA 2"))         return(prev_calculated);
         if (!checkCalculated(EmaMaHandle   ,rates_total,"EMA MA"))            return(prev_calculated);
         if (!checkCalculated(CCIHandle     ,rates_total,"CCI"))               return(prev_calculated);
         if (!checkCalculated(TurboCCIHandle,rates_total,"Turbo CCI"))         return(prev_calculated);
         
         if (!doCopy(LsmaMaHandle1 ,LsmaMABuffer1,0,limit,"LSMA MA buffer 1")) return(prev_calculated);
         if (!doCopy(LsmaMaHandle2 ,LsmaMABuffer2,0,limit,"LSMA MA buffer 2")) return(prev_calculated);
         if (!doCopy(EmaMaHandle   ,EmaMABuffer  ,0,limit,"EMA buffer"))       return(prev_calculated);
         if (!doCopy(CCIHandle     ,CCILine      ,0,limit,"CCI line"))         return(prev_calculated);
         if (!doCopy(TurboCCIHandle,TurboCCILine ,0,limit,"Turbo CCI line"))   return(prev_calculated);

         if (!ArrayGetAsSeries(close)) ArraySetAsSeries(close,true);

         //
         //
         //
         //
         //
      
         if (prev_calculated == 0)
         {
            limit -= 2;
               EMAColors[rates_total-1]  = 0;
               LSMAColors[rates_total-1] = 0;
               CCIColors[rates_total-1]  = 0;
         }

   //
   //
   //
   //
   //

      for(int i = limit; i >= 0 ; i--)
      {
         int k,s=0;
         if (CCILine[i]>0)
            if (TrendBufferUp[i+1] != EMPTY_VALUE) s = TrendPeriod;
            else
               for (k=1,s= 1; k<TrendPeriod && (i+k)<rates_total; k++,s++) if (TrendBufferDn[i+k] != EMPTY_VALUE) break;
         if (CCILine[i]<0)
            if (TrendBufferDn[i+1] != EMPTY_VALUE) s = -TrendPeriod;
            else
               for (k=1,s=-1; k<TrendPeriod && (i+k)<rates_total; k++,s--) if (TrendBufferUp[i+k] != EMPTY_VALUE) break;

         //
         //
         //
         //
         //
            
            TrendBufferUp[i] = EMPTY_VALUE;
            TrendBufferDn[i] = EMPTY_VALUE;
               if (s ==  TrendPeriod) TrendBufferUp[i] = CCILine[i];
               if (s == -TrendPeriod) TrendBufferDn[i] = CCILine[i];
       
            CCIHisto[i]  = CCILine[i];
            CCIColors[i] = 0;
               if (TrendBufferUp[i]!=EMPTY_VALUE) CCIColors[i] = 1;
               if (TrendBufferDn[i]!=EMPTY_VALUE) CCIColors[i] = 2;
               if (MathAbs(s)==(TrendPeriod-1))   CCIColors[i] = 3;

         //
         //
         //
         //
         //
              
            double lsma = 3.0*LsmaMABuffer1[i]-2.0*LsmaMABuffer2[i];
            LSMALine[i]   = LSMAPosition;
            LSMAColors[i] = LSMAColors[i+1];
               if (close[i] > lsma) LSMAColors[i] = 0;
               if (close[i] < lsma) LSMAColors[i] = 1;
            EMALine[i]   = EMAPosition;
            EMAColors[i] = EMAColors[i+1];
               if (close[i] > EmaMABuffer[i]) EMAColors[i] = 0;
               if (close[i] < EmaMABuffer[i]) EMAColors[i] = 1;
      }
   
   //
   //
   //
   //
   //
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//
//
//
//

bool checkCalculated(int bufferHandle, int total, string checkDescription)
{
   int calculated=BarsCalculated(bufferHandle);
   if (calculated<total)
   {
      Print("Not all data of "+checkDescription+" calculated (",(string)(total-calculated)," un-calculated bars )");
      return(false);
   }
   return(true);
}

//
//
//
//
//

bool doCopy(const int bufferHandle, double& buffer[], const int buffNum, const int copyCount, string copyDescription)
{
   if(CopyBuffer(bufferHandle,buffNum,0,copyCount,buffer)<=0)
   {
      Print("Getting "+copyDescription+" failed! Error",GetLastError());
      return(false);
   }
   return(true);
}
