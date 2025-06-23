//+---------------------------------------------------------------------+
//|                                                  FastStochastic.mq5 | 
//|                                                 Copyright © 2012, . | 
//|                                          http://www.metaquotes.net/ | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2012, Nikolay Kositsin"
#property link "http://www.metaquotes.net/"
#property description "Быстрый стохастик, выполненный в виде цветной гистограммы"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- количество индикаторных буферов
#property indicator_buffers 5 
//---- использовано всего два графических построения
#property indicator_plots   2
//+-----------------------------------+
//|  Параметры отрисовки индикатора 1 |
//+-----------------------------------+
//---- отрисовка индикатора в виде цветной гистограммы
#property indicator_type1   DRAW_COLOR_HISTOGRAM2
//---- в качестве цветов гистограммы использованы
#property indicator_color1 clrGray,clrLimeGreen,clrTeal,clrCrimson,clrPurple
//---- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 3
#property indicator_width1  3
//---- отображение метки индикатора
#property indicator_label1  "Main"

//+-----------------------------------+
//|  Параметры отрисовки индикатора 2 |
//+-----------------------------------+
//---- отрисовка индикатора в виде трёхцветной линии
#property indicator_type2   DRAW_COLOR_LINE
//---- в качестве цвета линии индикатора использованы
#property indicator_color2 clrGray,clrBlue,clrMagenta
//---- линия индикатора - штрих
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width2  2
//---- отображение метки индикатора
#property indicator_label2  "Signal"
//+----------------------------------------------+
//| Параметры отображения горизонтальных уровней |
//+----------------------------------------------+
#property indicator_level1  70.0
#property indicator_level2  50.0
#property indicator_level3  30.0
#property indicator_levelcolor Violet
#property indicator_levelstyle STYLE_DASHDOTDOT
//+-----------------------------------+
//|  объявление констант              |
//+-----------------------------------+
#define RESET 0 // Константа для возврата терминалу команды на пересчёт индикатора
//+-----------------------------------+
//|  Описание класса CXMA             |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+

//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XMA1;
//+-----------------------------------+
//|  объявление перечислений          |
//+-----------------------------------+
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
//+-----------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА     |
//+-----------------------------------+
input int InpKPeriod=5;  // K period
input Smooth_Method XMA_Method=MODE_SMA; //метод усреднения сигнальной линии
input uint InpDPeriod=3;  // D period               
input int XPhase=15; //параметр сглаживания сигнальной линии,
                     //для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
// Для VIDIA это период CMO, для AMA это период медленной скользящей
input Applied_price_ IPC=PRICE_CLOSE;//ценовая константа
/* , по которой производится расчёт индикатора ( 1-CLOSE, 2-OPEN, 3-HIGH, 4-LOW, 
  5-MEDIAN, 6-TYPICAL, 7-WEIGHTED, 8-SIMPL, 9-QUARTER, 10-TRENDFOLLOW, 11-0.5 * TRENDFOLLOW.) */
input int Shift=0; //сдвиг индикатора по горизонтали в барах
//+-----------------------------------+

//---- объявление динамического массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double UpSTOH[],DnSTOH[],SIGN[];
double ColorSTOH[],ColorSIGN[];
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total,min_rates_;
//+------------------------------------------------------------------+   
//| STOH indicator initialization function                           | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_=InpKPeriod;
   min_rates_total=min_rates_+1+XMA1.GetStartBars(XMA_Method,InpDPeriod,XPhase);;

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,UpSTOH,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(UpSTOH,true);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,DnSTOH,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(DnSTOH,true);

//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(2,ColorSTOH,INDICATOR_COLOR_INDEX);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ColorSTOH,true);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(3,SIGN,INDICATOR_DATA);
//---- осуществление сдвига индикатора 2 по горизонтали
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(SIGN,true);

//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(4,ColorSIGN,INDICATOR_COLOR_INDEX);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ColorSIGN,true);

//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"FastStochastic("+(string)InpKPeriod+","+(string)InpDPeriod+")");

//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+ 
//| STOH iteration function                                          | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(RESET);

//---- Объявление целых переменных
   int limit,bar,maxbar;
//---- Объявление переменных с плавающей точкой  
   double HH,LL,Range,Main,Price;
   static double Prev_Main;

//---- расчёты необходимого количества копируемых данных и
//стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=rates_total-min_rates_; // стартовый номер для расчёта всех баров
      Prev_Main=50;
     }
   else limit=rates_total-prev_calculated; // стартовый номер для расчёта новых баров 

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

   maxbar=rates_total-min_rates_;
   Main=Prev_Main;

//---- Основной цикл расчёта индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      HH=high[ArrayMaximum(high,bar,InpKPeriod)];
      LL=low [ArrayMinimum(low, bar,InpKPeriod)];
      Range=MathMax(_Point*1,HH-LL);
      Price=PriceSeries(IPC,bar,open,low,high,close);
      Main=100*(Price-LL)/Range;
      SIGN[bar]=XMA1.XMASeries(maxbar,prev_calculated,rates_total,XMA_Method,XPhase,InpDPeriod,Main,bar,true);

      if(Main<50)
        {
         DnSTOH[bar]=Main;
         UpSTOH[bar]=50;
        }
      else
        {
         UpSTOH[bar]=Main;
         DnSTOH[bar]=50;
        }

      //---- раскраска индикатора Stoh
      ColorSTOH[bar]=0;
            
      if(Main>50)
        {
         if(Main>Prev_Main) ColorSTOH[bar]=1;
         if(Main<Prev_Main) ColorSTOH[bar]=2;
        }

      if(Main<50)
        {
         if(Main<Prev_Main) ColorSTOH[bar]=3;
         if(Main>Prev_Main) ColorSTOH[bar]=4;
        }

      //---- раскраска сигнальной линии
      ColorSIGN[bar]=0;
      if(Main>SIGN[bar+1]) ColorSIGN[bar]=1;
      if(Main<SIGN[bar+1]) ColorSIGN[bar]=2;
      
      if(bar) Prev_Main=Main;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
