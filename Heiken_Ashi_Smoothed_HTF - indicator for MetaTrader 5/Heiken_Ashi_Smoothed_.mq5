//+------------------------------------------------------------------+
//|                                         Heiken_Ashi_Smoothed.mq5 |
//|                             Copyright © 2011,   Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
#property description "Heiken Ashi Smoothed"
//---- номер версии индикатора
#property version   "1.00"
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- для расчёта и отрисовки индикатора использовано пять буферов
#property indicator_buffers 5
//---- использовано всего одно графическое построение
#property indicator_plots   1
//---- в качестве индикатора использованы цветные свечи
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  DodgerBlue, Red
//---- отображение метки индикатора
#property indicator_label1  "Heiken Ashi Open;Heiken Ashi High;Heiken Ashi Low;Heiken Ashi Close"

//+-----------------------------------+
//|  Описание классов усреднений      |
//+-----------------------------------+
#include <SmoothAlgorithms.mqh> 
//+-----------------------------------+
//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XMAO,XMAL,XMAH,XMAC;
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
   PRICE_TRENDFOLLOW1_   //TrendFollow_2 Price 
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
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input Smooth_Method MA_Method=MODE_JJMA; //метод усреднения
input int Length=30; //глубина  усреднения                    
input int Phase=100; //параметр усреднения,
                    //для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
// Для VIDIA это период CMO, для AMA это период медленной скользящей
//+----------------------------------------------+

//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double ExtOpenBuffer[];
double ExtHighBuffer[];
double ExtLowBuffer[];
double ExtCloseBuffer[];
double ExtColorBuffer[];
//---
int StartBars;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- инициализация глобальных переменных 
   StartBars=XMAO.GetStartBars(MA_Method,Length,Phase)+1;

//---- установка алертов на недопустимые значения внешних переменных
   XMAO.XMALengthCheck("Length", Length);
   XMAO.XMAPhaseCheck("Phase", Phase, MA_Method);

//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(0,ExtOpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtCloseBuffer,INDICATOR_DATA);
//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(4,ExtColorBuffer,INDICATOR_COLOR_INDEX);
//---- осуществление сдвига начала отсчёта отрисовки индикатора 1
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,StartBars);

//---- Установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- имя для окон данных и лэйба для субъокон 
   string short_name="Heiken Ashi Smoothed";
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
   if(rates_total<StartBars) return(0);

//---- объявления локальных переменных 
   int first,bar;
   double XmaOpen,XmaHigh,XmaLow,XmaClose;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
     {
      first=0; // стартовый номер для расчёта всех баров
     }
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- Основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      //---- Четыре вызова функции XMASeries.  
      XmaOpen  = XMAO.XMASeries(0, prev_calculated, rates_total, MA_Method, Phase, Length, open [bar], bar, false);
      XmaClose = XMAC.XMASeries(0, prev_calculated, rates_total, MA_Method, Phase, Length, close[bar], bar, false);
      XmaHigh  = XMAH.XMASeries(0, prev_calculated, rates_total, MA_Method, Phase, Length, high [bar], bar, false);
      XmaLow   = XMAL.XMASeries(0, prev_calculated, rates_total, MA_Method, Phase, Length, low  [bar], bar, false);
      
      if(bar<=StartBars)
        {
         ExtOpenBuffer [bar]=XmaOpen;
         ExtCloseBuffer[bar]=XmaClose;
         ExtHighBuffer [bar]=XmaHigh;
         ExtLowBuffer  [bar]=XmaLow;
         
         continue;
        }

      ExtOpenBuffer [bar]=(ExtOpenBuffer[bar-1]+ExtCloseBuffer[bar-1])/2;
      ExtCloseBuffer[bar]=(XmaOpen+XmaHigh+XmaLow+XmaClose)/4;
      ExtHighBuffer [bar]=MathMax(XmaHigh,MathMax(ExtOpenBuffer[bar],ExtCloseBuffer[bar]));
      ExtLowBuffer  [bar]=MathMin(XmaLow,MathMin(ExtOpenBuffer[bar],ExtCloseBuffer[bar]));

      //--- Раскрашивание свечей
      if(ExtOpenBuffer[bar]<ExtCloseBuffer[bar]) ExtColorBuffer[bar]=0.0;
      else                                       ExtColorBuffer[bar]=1.0;

     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
