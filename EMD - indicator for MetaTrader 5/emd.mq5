//+------------------------------------------------------------------+
//|                                                          EMD.mq5 |
//|                                                                  |
//|                     https://www.mql5.com/ru/market/product/11550 |
//+------------------------------------------------------------------+
#property copyright "baramantan"
#property link      "https://www.mql5.com/ru/market/product/11550"
#property version   "1.00"
#property description "Visit my project NeuroPlus"
#property description "https://www.mql5.com/ru/market/product/11550"
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1
#property indicator_label1  "EMD" 
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrOrangeRed,clrBlue 
#property indicator_style1  STYLE_SOLID 
#property indicator_width1  2 

input int CALC=5000;
input int EMD_1 = 1;
input int EMD_2 = 2;
input int EMD_3 = 3;
input int EMD_4 = 4;
input int EMD_5 = 5;
input int EMD_6 = 6;
input int EMD_7 = 7;
input int EMD_8 = 8;
input int EMD_9 = 9;
input int EMD_10= 10;
input int EMD_11= 11;
input int EMD_12= 12;
input int EMD_13= 13;
input int EMD_14= 14;
input int EMD_15= 15;

int prev=-1;
int prev2=0;
#include "CEMD_2.mqh"
double Buffer[];
double Color[];
double d1[],d2[];
CEMD *emd=new CEMD();
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void Init()
  {
   SetIndexBuffer(0,Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,Color,INDICATOR_COLOR_INDEX);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnInit()
  {
   Init();
   prev2=CALC;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete  emd;
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(prev<rates_total)prev=rates_total;else return(rates_total);
   ArrayInitialize(Buffer,EMPTY_VALUE);
   int x=ArrayResize(d2,CopyClose(_Symbol,_Period,0,prev2,d1));
   prev2++;
   ArrayInitialize(d2,0);
   emd.Decomp(d1);
   IndicatorSetString(INDICATOR_SHORTNAME,"EMD - "+(string)(emd.nIMF-1)+"    ");

   if(EMD_1>0 && EMD_1<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_1);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_2>0 && EMD_2<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_2);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_3>0 && EMD_3<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_3);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_4>0 && EMD_4<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_4);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_5>0 && EMD_5<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_5);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_6>0 && EMD_6<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_6);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_7>0 && EMD_7<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_7);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_8>0 && EMD_8<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_8);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_9>0 && EMD_9<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_9);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_10>0 && EMD_10<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_10);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_11>0 && EMD_11<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_11);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_12>0 && EMD_12<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_12);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_13>0 && EMD_13<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_13);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_14>0 && EMD_14<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_14);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }
   if(EMD_15>0 && EMD_15<emd.nIMF)
     {
      emd.GetIMF(d1,EMD_15);
      for(int y=0;y<ArraySize(d1);y++)d2[y]+=d1[y];
     }

   for(int kl=0;kl<x;kl++)
     {
      Buffer[rates_total-1-kl]=d2[x-1-kl];//:))  
      if(kl>0 && d2[x-1-kl]>d2[x-kl])Color[rates_total-1-kl]=1;else Color[rates_total-1-kl]=0;
     }

   return (rates_total);
  }
//+------------------------------------------------------------------+
