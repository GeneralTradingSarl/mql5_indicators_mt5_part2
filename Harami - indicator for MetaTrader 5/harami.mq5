//+------------------------------------------------------------------+
//|                                                       Harami.mq5 |
//|                                  Copyright © 2009, Paul Stringer |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property description "Harami"
//---- авторство индикатора
#property copyright "Copyright © 2009, Paul Stringer"
//---- ссылка на сайт автора
#property link      "http://www.metaquotes.net"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- для расчёта и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//---- использовано всего два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//|  Параметры отрисовки верхнего индикатора     |
//+----------------------------------------------+
//---- отрисовка индикатора 1 в виде символа
#property indicator_type1   DRAW_ARROW
//---- в качестве цвета индикатора использован розовый цвет
#property indicator_color1  clrMagenta
//---- толщина линии индикатора 1 равна 1
#property indicator_width1  1
//---- отображение бычей метки индикатора
#property indicator_label1  "Up Harami"
//+----------------------------------------------+
//|  Параметры отрисовки нижнего индикатора      |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде символа
#property indicator_type2   DRAW_ARROW
//---- в качестве цвета индикатора использован синий цвет
#property indicator_color2  clrBlue
//---- толщина линии индикатора 2 равна 1
#property indicator_width2  1
//---- отображение медвежьей метки индикатора
#property indicator_label2 "Down Harami"

//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint MinMasterSize = 40;
input uint MaxMasterSize = 500;
input uint MinHaramiSize = 20;
input uint MaxHaramiSize = 300;
input double   MaxRatioHaramiToMaster = 0.75;
input double   MinRatioHaramiToMaster = 0.5;
input uint ArrowOffSet=35;
input int  UpLable=218;//лейба верхнего фрактала
input int  DnLable=217;//лейба нижнего фрактала
//+----------------------------------------------+

//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double SellBuffer[];
double BuyBuffer[];
//---- Объявление целых переменных начала отсчёта данных
int  min_rates_total;
double dMinMasterSize,dMaxMasterSize,dMinHaramiSize,dMaxHaramiSize,dArrowOffSet;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- инициализация глобальных переменных 
   min_rates_total=6;
   dMinMasterSize=MinMasterSize*_Point;
   dMaxMasterSize=MaxMasterSize*_Point;
   dMinHaramiSize=MinHaramiSize*_Point;
   dMaxHaramiSize=MaxHaramiSize*_Point;
   dArrowOffSet=ArrowOffSet*_Point;

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- символ для индикатора
   PlotIndexSetInteger(0,PLOT_ARROW,UpLable);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(SellBuffer,true);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- символ для индикатора
   PlotIndexSetInteger(1,PLOT_ARROW,DnLable);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(BuyBuffer,true);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);

//---- Установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- имя для окон данных и лэйба для субъокон 
   string short_name="Harami";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//----   
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
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(0);

//---- объявления локальных переменных 
   int limit;

//---- расчёты необходимого количества копируемых данных и
//стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчёта всех баров
     }
   else
     {
      limit=rates_total-prev_calculated; // стартовый номер для расчёта новых баров
     }

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);

//---- основной цикл расчёта индикатора
   for(int bar=limit; bar>=1 && !IsStopped(); bar--)
     {
      BuyBuffer[bar-1]=SellBuffer[bar-1]=NULL;
      double _MasterBarSize=MathAbs(open[bar+1]-close[bar+1]);
      double _HaramiBarSize=MathAbs(open[bar]-close[bar]);
      double MaxM=_MasterBarSize-dMaxMasterSize;
      double MinM=_MasterBarSize-dMinMasterSize;
      double MaxH=_HaramiBarSize-dMaxHaramiSize;
      double MinH=_HaramiBarSize-dMinHaramiSize;
      if(!_MasterBarSize) _MasterBarSize=_Point;
      double res=_HaramiBarSize/_MasterBarSize;

      if(MaxM && MinM && MaxH && MinH && res<=MaxRatioHaramiToMaster && res>=MinRatioHaramiToMaster)
        {
         // Is it reversal in favour of a BEAR reversal...
         if(
            (open[bar+1]>close[bar+1]) && 
            (open[bar]<close[bar]) && 
            (close[bar+1]<open[bar]) && 
            (open[bar+1]>close[bar])
            )
           {
            // Reversal favouring a bull coming...
            BuyBuffer[bar-1]=low[bar-1]-dArrowOffSet;
           }

         // Is it reversal in favour of a BULL reversal...
         if(
            (open[bar+1]<close[bar+1]) && 
            (open[bar]>close[bar]) && 
            (close[bar+1]>open[bar]) && 
            (open[bar+1]<close[bar])
            )
           {
            // Reversal favouring a bull coming...
            SellBuffer[bar-1]=high[bar-1]+dArrowOffSet;
           }
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
