//+------------------------------------------------------------------+
//|                                               LeManTrendSign.mq5 |
//|                                         Copyright © 2009, LeMan. | 
//|                                                 b-market@mail.ru | 
//+------------------------------------------------------------------+
//---- авторство индикатора
#property copyright "Copyright © 2009, LeMan."
//---- ссылка на сайт автора
#property link "b-market@mail.ru"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//--- для расчета и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//--- использовано всего два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//| Объявление констант                          |
//+----------------------------------------------+
#define RESET 0                        // константа для возврата терминалу команды на пересчет индикатора
//+----------------------------------------------+
//| Параметры отрисовки медвежьего индикатора    |
//+----------------------------------------------+
//--- отрисовка индикатора 1 в виде символа
#property indicator_type1   DRAW_ARROW
//--- в качестве цвета медвежьей линии индикатора использован красный цвет
#property indicator_color1  clrRed
//--- толщина линии индикатора 1 равна 2
#property indicator_width1  2
//--- отображение медвежьей метки индикатора
#property indicator_label1  "LeManTrend Sell"
//+----------------------------------------------+
//| Параметры отрисовки бычьего индикатора       |
//+----------------------------------------------+
//--- отрисовка индикатора 2 в виде символа
#property indicator_type2   DRAW_ARROW
//--- в качестве цвета бычьей линии индикатора использован зеленый цвет
#property indicator_color2  clrGreen
//--- толщина линии индикатора 2 равна 2
#property indicator_width2  2
//--- отображение бычьей метки индикатора
#property indicator_label2 "LeManTrend Buy"
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input int Min       = 13;
input int Midle     = 21;
input int Max       = 34;
input int PeriodEMA = 3; // Период индикатора
input int Shift=0;       // Сдвиг индикатора по горизонтали в барах
//+----------------------------------------------+
//--- объявление динамических массивов, которые в дальнейшем
//--- будут использованы в качестве индикаторных буферов
double SellBuffer[],BuyBuffer[];
//--- объявление целочисленных переменных для хендлов индикаторов
int ATR_Handle;
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total,start;
//+------------------------------------------------------------------+
//| Описание класса CMoving_Average                                  |
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh> 
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
   start=MathMax(MathMax(Min,Midle),Max);
   min_rates_total=start+PeriodEMA+1;
   min_rates_total=MathMax(min_rates_total,ATR_Period);
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//--- осуществление сдвига начала отсчета отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- осуществление сдвига индикатора по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(SellBuffer,true);
//--- символ для индикатора
   PlotIndexSetInteger(0,PLOT_ARROW,234);
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//--- осуществление сдвига начала отсчета отрисовки индикатора 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- осуществление сдвига индикатора по горизонтали на Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
//--- символ для индикатора
   PlotIndexSetInteger(1,PLOT_ARROW,233);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(BuyBuffer,true);

//---- инициализация переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"LeManTrendSign(",Min,", ",Midle,", ",Max,", ",PeriodEMA,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчета индикатора
                const double& low[],      // ценовой массив минимумов цены  для расчета индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- проверка количества баров на достаточность для расчета
   if(BarsCalculated(ATR_Handle)<rates_total || rates_total<min_rates_total) return(RESET);
//---- объявление локальных переменных 
   int limit,to_copy,bar,maxbar;
   double High1,High2,High3,Low1,Low2,Low3,HH,LL,ATR[],Bulls,Bears,trend;
   static double trend_prev;
//---- расчет стартового номера maxbar для функции MASeries()
   maxbar=rates_total-1-start;
//---- расчет стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=maxbar; // стартовый номер для расчета всех баров
      trend_prev=0;
     }
   else limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров
   to_copy=limit+1;
//---- копируем вновь появившиеся данные в массив
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(ATR,true);
//---- объявление переменных класса CMoving_Average из файла SmoothAlgorithms.mqh
   static CMoving_Average BULLS,BEARS;
//---- основной цикл расчета индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      High1=high[ArrayMaximum(high,bar+1,Min)];
      High2=high[ArrayMaximum(high,bar+1,Midle)];
      High3=high[ArrayMaximum(high,bar+1,Max)];
      HH=((high[bar]-High1)+(high[bar]-High2)+(high[bar]-High3));
      //----
      Low1=low[ArrayMinimum(low,bar+1,Min)];
      Low2=low[ArrayMinimum(low,bar+1,Midle)];
      Low3=low[ArrayMinimum(low,bar+1,Max)];
      LL=((Low1-low[bar])+(Low2-low[bar])+(Low3-low[bar]));
      //----
      Bulls=BULLS.MASeries(maxbar,prev_calculated,rates_total,PeriodEMA,MODE_EMA,HH,bar,true);
      Bears=BEARS.MASeries(maxbar,prev_calculated,rates_total,PeriodEMA,MODE_EMA,LL,bar,true);
      trend=Bulls-Bears;
      BuyBuffer[bar]=0.0;
      SellBuffer[bar]=0.0;
      if(trend_prev<=0 && trend>0) BuyBuffer[bar]=low[bar]-ATR[bar]*3/8;
      if(trend_prev>=0 && trend<0) SellBuffer[bar]=high[bar]+ATR[bar]*3/8;
      if(bar) trend_prev=trend;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
