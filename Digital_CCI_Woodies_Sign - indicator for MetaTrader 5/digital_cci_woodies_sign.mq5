//+---------------------------------------------------------------------+
//|                                        Digital_CCI_Woodies_Sign.mq5 | 
//|                                           Copyright © 2015, Ramdass | 
//|                                                                     | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2015, Ramdass"
#property link ""
//---- номер версии индикатора
#property version   "1.00"
//--- отрисовка индикатора в главном окне
#property indicator_chart_window 
//--- для расчета и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//--- использовано два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//| Параметры отрисовки медвежьего индикатора    |
//+----------------------------------------------+
//--- отрисовка индикатора 1 в виде символа
#property indicator_type1   DRAW_ARROW
//--- в качестве цвета медвежьей линии индикатора использован Red цвет
#property indicator_color1  clrRed
//--- толщина линии индикатора 1 равна 4
#property indicator_width1  4
//--- отображение медвежьей метки индикатора
#property indicator_label1  "Digital_CCI_Woodies Sell"
//+----------------------------------------------+
//| Параметры отрисовки бычьего индикатора       |
//+----------------------------------------------+
//--- отрисовка индикатора 2 в виде символа
#property indicator_type2   DRAW_ARROW
//--- в качестве цвета бычьей линии индикатора использован DarkTurquoisee цвет
#property indicator_color2  clrDarkTurquoise
//--- толщина линии индикатора 2 равна 4
#property indicator_width2  4
//--- отображение бычьей метки индикатора
#property indicator_label2 "Digital_CCI_Woodies Buy"
//+----------------------------------------------+
//| Объявление констант                          |
//+----------------------------------------------+
#define RESET 0       // константа для возврата терминалу команды на пересчет индикатора
//+----------------------------------------------+
//| Описание класса CXMA                         |
//+----------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+----------------------------------------------+
//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XMA1,XMA2,XMA3,XMA4;
//+----------------------------------------------+
//| Объявление перечислений                      |
//+----------------------------------------------+
enum Applied_price_ //Тип константы
  {
   PRICE_CLOSE_ = 1,     //Close
   PRICE_OPEN_,          //Open
   PRICE_HIGH_,          //High
   PRICE_LOW_,           //Low
   PRICE_MEDIAN_,        //Median Price (HL/2)
   PRICE_TYPICAL_,       //Typical Price (HLC/3)
   PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)
   PRICE_SIMPL_,         //Simpl Price (OC/2)
   PRICE_QUARTER_,       //Quarted Price (HLOC/4) 
   PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price 
   PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price 
   PRICE_DEMARK_         //Demark Price
  };
//+----------------------------------------------+
//| Объявление перечислений                      |
//+----------------------------------------------+
/*enum Smooth_Method - перечисление объявлено в файле SmoothAlgorithms.mqh
  {
   MODE_SMA_,  //SMA
   MODE_EMA_,  //EMA
   MODE_SMMA_, //SMMA
   MODE_LWMA_, //LWMA
   MODE_JJMA,  //JJMA
   MODE_JurX,  //JurX
   MODE_ParMA, //ParMA
   MODE_T3,    //T3
   MODE_VIDYA, //VIDYA
   MODE_AMA,   //AMA
  }; */
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input Smooth_Method MA_Method1=MODE_SMA; // Метод усреднения первого сглаживания
input int Length1=14; // Глубина  первого сглаживания
input int Phase1=15;  // Параметр первого сглаживания
//--- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//--- для VIDIA это период CMO, для AMA это период медленной скользящей
input Smooth_Method MA_Method2=MODE_SMA; // Метод усреднения второго сглаживания
input int Length2=6; // Глубина  второго сглаживания
input int Phase2=15; // Параметр второго сглаживания
                     //--- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//--- для VIDIA это период CMO, для AMA это период медленной скользящей
input Applied_price_ IPC=PRICE_CLOSE; // Ценовая константа
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
//+----------------------------------------------+
//--- объявление динамических массивов, которые в дальнейшем
//--- будут использованы в качестве индикаторных буферов
double SellBuffer[],BuyBuffer[];
//--- объявление целочисленных переменных для хендлов индикаторов
int ATR_Handle;
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total,min_rates_,min_rates_1,min_rates_2;
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//--- получение хендла индикатора ATR
   int ATR_Period=15;
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора ATR");
      return(INIT_FAILED);
     }
//---- инициализация переменных начала отсчета данных
   min_rates_=26;
   min_rates_1=min_rates_+GetStartBars(MA_Method1,Length1,Phase1);
   min_rates_2=min_rates_+GetStartBars(MA_Method2,Length2,Phase2);
   min_rates_total=2*(MathMax(min_rates_1,min_rates_2)-min_rates_)+min_rates_+1;
   min_rates_total=MathMax(min_rates_total,ATR_Period);
//---- установка алертов на недопустимые значения внешних переменных
   XMA1.XMALengthCheck("Length1", Length1);
   XMA2.XMALengthCheck("Length2", Length2);
//---- установка алертов на недопустимые значения внешних переменных
   XMA1.XMAPhaseCheck("Phase1", Phase1, MA_Method1);
   XMA2.XMAPhaseCheck("Phase2", Phase2, MA_Method2);
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//--- осуществление сдвига начала отсчета отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- символ для индикатора
   PlotIndexSetInteger(0,PLOT_ARROW,172);
//--- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//--- осуществление сдвига начала отсчета отрисовки индикатора 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- символ для индикатора
   PlotIndexSetInteger(1,PLOT_ARROW,172);
//--- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- инициализация переменной для короткого имени индикатора
   string shortname;
   string Smooth1=XMA1.GetString_MA_Method(MA_Method1);
   string Smooth2=XMA1.GetString_MA_Method(MA_Method2);
   StringConcatenate(shortname,"Digital_CCI_Woodies(",Length1,", ",Length2,", ",Smooth1,", ",Smooth2,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//--- проверка количества баров на достаточность для расчета
   if(BarsCalculated(ATR_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//---- объявление переменных с плавающей точкой  
   double res,xres1,xres2,rel1,rel2,dev1,dev2,fast,slow,ATR[1];
   static double slow_prev,fast_prev;
//---- объявление целочисленных переменных и получение уже посчитанных баров
   int first,bar;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
      first=min_rates_; // стартовый номер для расчета всех баров
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      res=Get_Filter(IPC,open,low,high,close,bar);
      xres1=XMA1.XMASeries(min_rates_,prev_calculated,rates_total,MA_Method1,Phase1,Length1,res,bar,false);
      xres2=XMA2.XMASeries(min_rates_,prev_calculated,rates_total,MA_Method2,Phase2,Length2,res,bar,false);
      rel1=res-xres1;
      rel2=res-xres2;
      dev1=0.015*XMA3.XMASeries(min_rates_1,prev_calculated,rates_total,MA_Method1,Phase1,Length1,MathAbs(rel1),bar,false);
      dev2=0.015*XMA4.XMASeries(min_rates_2,prev_calculated,rates_total,MA_Method2,Phase2,Length2,MathAbs(rel2),bar,false);
      if(dev1) slow=rel1/dev1; else slow=0.0;
      if(dev2) fast=rel2/dev2; else fast=0.0;
      //--- 
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;
      //---
      if(fast_prev<=slow_prev && fast>slow)
        {
         //--- копируем вновь появившиеся данные в массив
         if(CopyBuffer(ATR_Handle,0,time[bar],1,ATR)<=0) return(RESET);
         BuyBuffer[bar]=low[bar]-ATR[0]*3/8;
        }
      //---
      if(fast_prev>=slow_prev && fast<slow)
        {
         //--- копируем вновь появившиеся данные в массив
         if(CopyBuffer(ATR_Handle,0,time[bar],1,ATR)<=0) return(RESET);
         SellBuffer[bar]=high[bar]+ATR[0]*3/8;
        }
      //---
      if(bar<rates_total-1)
        {
         fast_prev=fast;
         slow_prev=slow;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Получение значений цифрового фильтра                             |
//+------------------------------------------------------------------+   
double Get_Filter(Applied_price_ Price,const double  &Open[],const double  &Low[],const double  &High[],const double  &Close[],int index)
  {
//---- 
   double sum=0.225654509516691000*PriceSeries(Price,index-0,Open,Low,High,Close)
              +0.21924126458513900*PriceSeries(Price,index-1,Open,Low,High,Close)
              +0.20068847968989900*PriceSeries(Price,index-2,Open,Low,High,Close)
              +0.17199251376592300*PriceSeries(Price,index-3,Open,Low,High,Close)
              +0.13627040812928600*PriceSeries(Price,index-4,Open,Low,High,Close)
              +0.09716444691033020*PriceSeries(Price,index-5,Open,Low,High,Close)
              +0.05850647966034450*PriceSeries(Price,index-6,Open,Low,High,Close)
              +0.02374481402976710*PriceSeries(Price,index-7,Open,Low,High,Close)
              -0.00442869436477854*PriceSeries(Price,index-8,Open,Low,High,Close)
              -0.02436367832290450*PriceSeries(Price,index-9,Open,Low,High,Close)
              -0.03556173658348070*PriceSeries(Price,index-10,Open,Low,High,Close)
              -0.03863068174342280*PriceSeries(Price,index-11,Open,Low,High,Close)
              -0.03505645644492430*PriceSeries(Price,index-12,Open,Low,High,Close)
              -0.02689634908050020*PriceSeries(Price,index-13,Open,Low,High,Close)
              -0.01641578870330520*PriceSeries(Price,index-14,Open,Low,High,Close)
              -0.00573862260748731*PriceSeries(Price,index-15,Open,Low,High,Close)
              +0.00342620684434000*PriceSeries(Price,index-16,Open,Low,High,Close)
              +0.00996574022237624*PriceSeries(Price,index-17,Open,Low,High,Close)
              +0.01342232808872480*PriceSeries(Price,index-18,Open,Low,High,Close)
              +0.01393940042379780*PriceSeries(Price,index-19,Open,Low,High,Close)
              +0.01211499384832860*PriceSeries(Price,index-20,Open,Low,High,Close)
              +0.00883315067608292*PriceSeries(Price,index-21,Open,Low,High,Close)
              +0.00502356811075590*PriceSeries(Price,index-22,Open,Low,High,Close)
              +0.00151954406404245*PriceSeries(Price,index-23,Open,Low,High,Close)
              -0.00108567173532015*PriceSeries(Price,index-24,Open,Low,High,Close)
              -0.01333016897970480*PriceSeries(Price,index-25,Open,Low,High,Close);
//----
   return(sum);
  }
//+------------------------------------------------------------------+
