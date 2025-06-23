//+---------------------------------------------------------------------+
//|                                                            GMMA.mq5 | 
//|                                Copyright © 2011,   Nikolay Kositsin | 
//|                                 Khabarovsk,   farria@mail.redcom.ru | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
//---- номер версии индикатора
#property version   "1.01"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//+-----------------------------------+
//|  объявление констант              |
//+-----------------------------------+
#define LINES_SIRNAME     "GMMA" // Строковая константа для названия индикатора
#define LINES_TOTAL         12   // Константа для количества линий индикатора
#define RESET                0   // Константа для возврата терминалу команды на пересчет индикатора
//+-----------------------------------+
#property description LINES_SIRNAME
//---- количество индикаторных буферов
#property indicator_buffers LINES_TOTAL 
//---- использовано всего графических построений
#property indicator_plots   LINES_TOTAL
//+-----------------------------------+
//|  Параметры отрисовки индикаторов  |
//+-----------------------------------+
//---- отрисовка осцилляторов в виде линий
#property indicator_type1   DRAW_LINE
//---- линии - штрихпунктирные кривые
#property indicator_style1 STYLE_SOLID
//---- толщина линий 1
#property indicator_width1  1
//---- в качестве цвета линий индикатора использован красный цвет
#property indicator_color1 clrRed
#property indicator_color2 clrRed
#property indicator_color3 clrRed
#property indicator_color4 clrRed
#property indicator_color5 clrRed
#property indicator_color6 clrRed
//---- в качестве цвета линий индикатора использован синий цвет
#property indicator_color7 clrBlue
#property indicator_color8 clrBlue
#property indicator_color9 clrBlue
#property indicator_color10 clrBlue
#property indicator_color11 clrBlue
#property indicator_color12 clrBlue
//+-----------------------------------+
//|  Описание класса CXMA             |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+
//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XMA[LINES_TOTAL];
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
//|  объявление перечислений          |
//+-----------------------------------+
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
//|  Входные параметры индикатора     |
//+-----------------------------------+
input Smooth_Method xMA_Method=MODE_EMA; //Метод усреднения
//----
input int TrLength1=3; //Период усреднения 1 трейдерский 
input int TrLength2=5; //Период усреднения 2 трейдерский 
input int TrLength3=8; //Период усреднения 3 трейдерский 
input int TrLength4=10; //Период усреднения 4 трейдерский 
input int TrLength5=12; //Период усреднения 5 трейдерский
input int TrLength6=15; //Период усреднения 6 трейдерский 
//----
input int InvLength1=30; //Период усреднения 1 инвесторский
input int InvLength2=35; //Период усреднения 2 инвесторский
input int InvLength3=40; //Период усреднения 3 инвесторский
input int InvLength4=45; //Период усреднения 4 инвесторский
input int InvLength5=50; //Период усреднения 5 инвесторский
input int InvLength6=60; //Период усреднения 6 инвесторский
//----                  
input int xPhase=100; //Параметр сглаживания
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- Для VIDIA это период CMO, для AMA это период медленной скользящей
input Applied_price_ IPC=PRICE_CLOSE;//Ценовая константа
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
//+-----------------------------------+
int period[LINES_TOTAL];
//---- Объявление переменной значения вертикального сдвига мувингов
double dPriceShift;
//---- Объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//+------------------------------------------------------------------+
//|  Массивы переменных для создания индикаторных буферов            |
//+------------------------------------------------------------------+  
class CIndicatorsBuffers
  {
public: double    IndBuffer[];
  };
//+------------------------------------------------------------------+
//| Создание индикаторных буферов                                    |
//+------------------------------------------------------------------+
CIndicatorsBuffers Ind[LINES_TOTAL];
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Инициализация переменных начала отсчета данных   
   period[0]=TrLength1;
   period[1]=TrLength2;
   period[2]=TrLength3;
   period[3]=TrLength4;
   period[4]=TrLength5;
   period[5]=TrLength6;
   period[6]=InvLength1;
   period[7]=InvLength2;
   period[8]=InvLength3;
   period[9]=InvLength4;
   period[10]=InvLength5;
   period[11]=InvLength6;
//----
   int MaxPeriod=period[ArrayMaximum(period)];
   min_rates_total=XMA[0].GetStartBars(xMA_Method,MaxPeriod,xPhase);
//----
   for(int numb=0; numb<LINES_TOTAL; numb++)
     {
      string shortname="";
      StringConcatenate(shortname,LINES_SIRNAME,numb,"(",period[numb],")");
      //--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
      PlotIndexSetString(numb,PLOT_LABEL,shortname);
      //---- установка значений индикатора, которые не будут видимы на графике
      PlotIndexSetDouble(numb,PLOT_EMPTY_VALUE,EMPTY_VALUE);
      //---- осуществление сдвига начала отсчета отрисовки индикатора
      PlotIndexSetInteger(numb,PLOT_DRAW_BEGIN,min_rates_total);
      //---- превращение динамических массивов в индикаторные буферы
      SetIndexBuffer(numb,Ind[numb].IndBuffer,INDICATOR_DATA);
      //---- индексация элементов в буферах как в таймсериях   
      ArraySetAsSeries(Ind[numb].IndBuffer,true);
      //---- копирование свойств первой линии индикатора для всех остальных
      PlotIndexSetInteger(numb,PLOT_DRAW_TYPE,PlotIndexGetInteger(0,PLOT_DRAW_TYPE));
      PlotIndexSetInteger(numb,PLOT_LINE_STYLE,PlotIndexGetInteger(0,PLOT_LINE_STYLE));
      PlotIndexSetInteger(numb,PLOT_LINE_WIDTH,PlotIndexGetInteger(0,PLOT_LINE_WIDTH));
     }
//---- инициализации переменной для короткого имени индикатора
   string shortname;
   string Smooth1=XMA[0].GetString_MA_Method(xMA_Method);
   StringConcatenate(shortname,LINES_SIRNAME,LINES_TOTAL,"(",Smooth1,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- завершение инициализации
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
//---- проверка количества баров на достаточность для расчета
   if(rates_total<min_rates_total) return(RESET);
//---- объявления локальных переменных 
   int bar,limit,maxbar;
   double price_;
//----
   maxbar=rates_total-1;
//---- расчет стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
      limit=rates_total-1; // стартовый номер для расчета всех баров
   else limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
//---- основной цикл расчета индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- Вызов функции PriceSeries для получения входной цены price_
      price_=PriceSeries(IPC,bar,open,low,high,close);
      //----
      for(int numb=0; numb<LINES_TOTAL; numb++)
         Ind[numb].IndBuffer[bar]=XMA[numb].XMASeries(maxbar,prev_calculated,rates_total,xMA_Method,xPhase,period[numb],price_,bar,true);
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
