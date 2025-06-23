//+---------------------------------------------------------------------+
//|                                                           JSatl.mq5 |
//|                                  Copyright © 2016, Nikolay Kositsin |
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2016, Nikolay Kositsin"
#property link      "farria@mail.redcom.ru"
#property version   "1.00"
//---- отрисовка индикатора в основном окне
#property indicator_chart_window
//---- для расчёта и отрисовки индикатора использован один буфер
#property indicator_buffers 1
//---- использовано всего одно графическое построение
#property indicator_plots   1
//---- отрисовка индикатора в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета линии индикатора использован розовый цвет
#property indicator_color1  clrDeepPink
//---- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1  2
//---- отображение метки индикатора
#property indicator_label1  "JSATL"
//+----------------------------------------------+
//|  объявление перечислений                     |
//+----------------------------------------------+
enum Applied_price_ //Тип константы
  {
   PRICE_CLOSE_ = 1,     //PRICE_CLOSE
   PRICE_OPEN_,          //PRICE_OPEN
   PRICE_HIGH_,          //PRICE_HIGH
   PRICE_LOW_,           //PRICE_LOW
   PRICE_MEDIAN_,        //PRICE_MEDIAN
   PRICE_TYPICAL_,       //PRICE_TYPICAL
   PRICE_WEIGHTED_,      //PRICE_WEIGHTED
   PRICE_SIMPL_,         //PRICE_SIMPL_
   PRICE_QUARTER_,       //PRICE_QUARTER_
   PRICE_TRENDFOLLOW0_,  //PRICE_TRENDFOLLOW0_
   PRICE_TRENDFOLLOW1_,  // TrendFollow_2 Price 
   PRICE_DEMARK_         // Demark Price 
  };
//+----------------------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА                |
//+----------------------------------------------+
input uint iLength=5; // глубина JMA сглаживания                   
input int iPhase=100; // параметр JMA сглаживания,
//---- изменяющийся в пределах -100 ... +100,
//---- влияет на качество переходного процесса;
input Applied_price_ IPC=PRICE_CLOSE_;//ценовая константа
input int SATLShift=0; // сдвиг Фатла по горизонтали в барах
input int PriceShift=0; // cдвиг Фатла по вертикали в пунктах
//+----------------------------------------------+
//---- объявление и инициализация переменной для хранения количества расчётных баров
int SATLPeriod=65;
//---- объявление динамического массива, который будет в 
// дальнейшем использован в качестве индикаторного буфера
double ExtLineBuffer[];
//----
int min_rates_total,fstart,SATLSize;
double dPriceShift;
//+------------------------------------------------------------------+
// Описание функции iPriceSeries()                                   |
// Описание функции iPriceSeriesAlert()                              |
// Описание класса CJJMA                                             |
//+------------------------------------------------------------------+ 
#include <SmoothAlgorithms.mqh> 
//---- объявление переменной класса CJJMA из файла JJMASeries_Cls.mqh
CJJMA JMA; 
//---- объявление переменной класса CSATL из файла JJMASeries_Cls.mqh
CSATL STL; 
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- превращение динамического массива ExtLineBuffer в индикаторный буфер
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора по горизонтали на SATLShift
   PlotIndexSetInteger(0,PLOT_SHIFT,SATLShift);
//---- инициализация переменных 
   min_rates_total=SATLSize+30;
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"JSATL(",iLength," ,",iPhase,")");
//--- создание метки для отображения в DataWindow
   PlotIndexSetString(0,PLOT_LABEL,shortname);
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
//---- Инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
//---- установка алертов на недопустимые значения внешних переменных
   JMA.JJMALengthCheck("iLength", iLength);
   JMA.JJMAPhaseCheck("iPhase", iPhase);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
   if(rates_total<min_rates_total)return(0);

//---- объявления локальных переменных 
   int first,bar;
   double price,satl,jsatl;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
     {
      first=SATLPeriod-1; // стартовый номер для расчёта всех баров
      fstart=first;
     }
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      price=PriceSeries(IPC,bar,open,low,high,close);
      satl=STL.SATLSeries(0,prev_calculated,rates_total,price,bar,false);
      jsatl=JMA.JJMASeries(fstart,prev_calculated,rates_total,0,iPhase,iLength,satl,bar,false);
      ExtLineBuffer[bar]=jsatl+dPriceShift;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
