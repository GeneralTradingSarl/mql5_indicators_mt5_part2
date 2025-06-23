//+---------------------------------------------------------------------+
//|                                                           F_RSI.mq5 | 
//|                                Copyright © 2015, Yuriy Tokman (YTG) |
//|                                                  http://ytg.com.ua/ |
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2015, Yuriy Tokman (YTG)"
#property link      "http://ytg.com.ua/"
#property description "Индикатор RSI с динамическими уровнями"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- количество индикаторных буферов 3
#property indicator_buffers 3 
//---- использовано всего два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//| Параметры отрисовки индикатора  RSI Cloud    |
//+----------------------------------------------+
//---- отрисовка индикатора в виде облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цветов облака индикатора использованы
#property indicator_color1  clrLavender
//---- отображение метки индикатора
#property indicator_label1  "RSI Cloud"
//+----------------------------------------------+
//| Параметры отрисовки индикатора RSI           |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде линии
#property indicator_type2   DRAW_LINE
//---- в качестве цвета линии индикатора использован цвет DeepPink
#property indicator_color2  clrDeepPink
//---- линия индикатора 2 - непрерывная кривая
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора 2 равна 2
#property indicator_width2  2
//---- отображение метки индикатора
#property indicator_label2  "RSI"
//+----------------------------------------------+
//| Параметры отображения горизонтальных уровней |
//+----------------------------------------------+
#property indicator_level1  70
#property indicator_level2  50
#property indicator_level3  30
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//| Описание класса CXMA                         |
//+----------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+----------------------------------------------+
//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XMA1,XMA2,XMA3;
//+----------------------------------------------+
//| Объявление перечислений                      |
//+----------------------------------------------+
enum Applied_price_ //тип константы
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
input uint PeriodRSI=7;                               // Период индикатора RSI
input Smooth_Method XMA_Method=MODE_SMMA;             // Метод усреднения
input int XPhase=15; // Параметр сглаживания
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- для VIDIA это период CMO, для AMA это период медленной скользящей
input double Dev=1;                                   // Девиация
input ENUM_APPLIED_PRICE  Applied_price=PRICE_CLOSE;  // Тип цены или handle
input int Shift=0;                                    // Сдвиг индикатора по горизонтали в барах  
//+----------------------------------------------+
//---- объявление динамических массивов, которые в дальнейшем
//---- будут использованы в качестве индикаторных буферов
double Line1Buffer[];
double Line2Buffer[];
double Line3Buffer[];
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total,min_rates_1,min_rates_2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_1=1;
   min_rates_2=min_rates_1+GetStartBars(XMA_Method,PeriodRSI,XPhase);
   min_rates_total=min_rates_2+int(PeriodRSI);
//---- превращение динамического массива Line2Buffer[] в индикаторный буфер
   SetIndexBuffer(0,Line2Buffer,INDICATOR_DATA);
//---- превращение динамического массива Line3Buffer[] в индикаторный буфер
   SetIndexBuffer(1,Line3Buffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 2 по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора 1 на min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

//---- превращение динамического массива Line1Buffer[] в индикаторный буфер
   SetIndexBuffer(2,Line1Buffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 3 по горизонтали на Shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора 2 на min_rates_total
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);

//---- инициализация переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"F_RSI(",PeriodRSI,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
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
//---- проверка количества баров на достаточность для расчета
   if(rates_total<min_rates_total) return(0);
//---- объявление переменных с плавающей точкой  
   double rl,rsi,ps,ng,srsi,sqr,s_dv;
//---- объявление целочисленных переменных и получение уже посчитанных баров
   int first,bar;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
      first=min_rates_1; // стартовый номер для расчета всех баров
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      rl=PriceSeries(Applied_price,bar,open,low,high,close)-PriceSeries(Applied_price,bar-1,open,low,high,close);
      ps=MathMax(0,rl);
      ng=-MathMin(0,rl);
      ps=XMA1.XMASeries(min_rates_1,prev_calculated,rates_total,XMA_Method,XPhase,PeriodRSI,ps,bar,false);
      ng=XMA2.XMASeries(min_rates_1,prev_calculated,rates_total,XMA_Method,XPhase,PeriodRSI,ng,bar,false);
      if(!ng || !(1+ps/ng)) rsi=100.0;
      else rsi=100.0-100.0/(1+ps/ng);
      Line1Buffer[bar]=rsi;
      srsi=XMA3.XMASeries(min_rates_2,prev_calculated,rates_total,MODE_SMA_,0,PeriodRSI,rsi,bar,false);
      sqr=0;
      for(int kkk=int(PeriodRSI)-1; kkk>=0; kkk--)
        {
         int index=MathMax(0,bar-kkk);
         sqr+=(Line1Buffer[index]-srsi)*(Line1Buffer[index]-srsi);
        }
      s_dv=MathPow(sqr/PeriodRSI,0.5);
      Line2Buffer[bar]=50+Dev*s_dv;
      Line3Buffer[bar]=50-Dev*s_dv;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
