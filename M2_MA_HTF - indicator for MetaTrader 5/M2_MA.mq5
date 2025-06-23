//+---------------------------------------------------------------------+ 
//|                                                           M2_MA.mq5 | 
//|                                   Copyright © 2011, Dodonov Vitalii |
//|                                                     ellizii@mail.ru | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2010, Dodonov Vitaliin"
#property link "ellizii@mail.ru" 
//---- номер версии индикатора
#property version   "1.01"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов
#property indicator_buffers 1 
//---- использовано всего одно графическое построение
#property indicator_plots   1
//+-----------------------------------+
//|  Параметры отрисовки индикатора   |
//+-----------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета линии индикатора использован clrMediumSlateBlue цвет
#property indicator_color1 clrMediumSlateBlue
//---- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1 2
//---- отображение метки индикатора
#property indicator_label1  "M2_MA"
//+-----------------------------------+
//|  Описание класса CXMA             |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//---- объявление переменных классов CXMA и CMoving_Average из файла SmoothAlgorithms.mqh
CXMA XMA1;
CMoving_Average EMA,LWMA1,LWMA2;
//+-----------------------------------+
//|  объявление перечислений          |
//+-----------------------------------+
/*enum SmoothMethod - перечисление объявлено в файле SmoothAlgorithms.mqh
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
//+-----------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА     |
//+-----------------------------------+
input Smooth_Method XMA_Method=MODE_SMA_; // метод усреднения
input uint MPeriod=6;                     // глубина сглаживания 
input int XPhase=15;                      // параметр сглаживания,
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- Для VIDIA это период CMO, для AMA это период медленной скользящей                  
input Applied_price_ IPC=PRICE_CLOSE_;    // ценовая константа
input int Shift=0;                        // сдвиг индикатора по горизонтали в барах
input int PriceShift=0;                   // cдвиг индикатора по вертикали в пунктах
//+-----------------------------------+
//---- индикаторный буфер
double IndBuffer[];
double dPriceShift;
//---- Объявление глобальных переменных
int min_rates_total,min_rates_;
int period1,period2,period3;
//+------------------------------------------------------------------+
// Описание класса CMoving_Average                                   |
//+------------------------------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+------------------------------------------------------------------+    
//| M2_MA indicator initialization function                          | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   int periodf=int(MPeriod);
   int tme=periodf+5;
   int ry=periodf+3;
   period1=tme/periodf;
   period2=ry/periodf;
   period3=tme/periodf;
   min_rates_=int(MathMin(MathMin(period1,period2),period3));
   min_rates_total=min_rates_+GetStartBars(XMA_Method,int(MPeriod),XPhase);     
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"M2_MA");
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- Инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
//---- завершение инициализации
  }
//+------------------------------------------------------------------+  
//| M2_MA iteration function                                         | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчёта индикатора
                const double& low[],      // ценовой массив минимумов цены  для расчёта индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(0);

//---- Объявление локальных переменных
   int first,bar;
   double series,ema,lwma1,lwma2,ma,xma;

   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
     {
      first=0; // стартовый номер для расчёта всех баров
     }
   else first=prev_calculated; // стартовый номер для расчёта новых баров

//---- основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      series=PriceSeries(IPC,bar,open,low,high,close);
      ema=EMA.EMASeries(0,prev_calculated,rates_total,period2,series,bar,false); 
      lwma1=LWMA1.LWMASeries(0,prev_calculated,rates_total,period1,series,bar,false);
      lwma2=LWMA2.LWMASeries(0,prev_calculated,rates_total,period3,series,bar,false);      
      ma=(2*ema+(((lwma2+ema)/2)-lwma1))/2;  
      xma=XMA1.XMASeries(min_rates_,prev_calculated,rates_total,XMA_Method,XPhase,MPeriod,ma,bar,false);         
      IndBuffer[bar]=xma+dPriceShift;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
