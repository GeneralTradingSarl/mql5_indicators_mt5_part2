//+------------------------------------------------------------------+
//|                                                    InstTrend.mq5 |
//|                                                                  |
//|                                                                  |
//| Algorithm taken from book                                        |
//|     "Cybernetics Analysis for Stock and Futures"                 |
//| by John F. Ehlers                                                |
//|                                                                  |
//|                                              contact@mqlsoft.com |
//|                                          http://www.mqlsoft.com/ |
//+------------------------------------------------------------------+
//---- авторство индикатора
#property copyright "Coded by Witold Wozniak"
//---- авторство индикатора
#property link      "www.mqlsoft.com"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- количество индикаторных буферов 2
#property indicator_buffers 2 
//---- использовано всего одно графическое построение
#property indicator_plots   1
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикатора 1 в виде облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цветов облака
#property indicator_color1  clrMediumOrchid,clrAqua
//---- отображение метки индикатора
#property indicator_label1  "InstTrend"
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input double Alpha=0.07;// коэффициент индикатора
input int Shift=0; // сдвиг индикатора по горизонтали в барах 
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double ITrendBuffer[];
double TriggerBuffer[];
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//---- Объявление глобальных переменных
double K0,K1,K2,K3,K4;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=8+3;
   
//---- Инициализация переменных
  double A2=Alpha*Alpha;
  K0=Alpha-A2/4.0;
  K1=0.5*A2;
  K2=Alpha-0.75*A2;
  K3=2.0 *(1.0 - Alpha);
  K4=MathPow((1.0 - Alpha),2);
    
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,ITrendBuffer,INDICATOR_DATA);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,TriggerBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора 1 на 30
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,30);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"Instantaneous Trendline(",Alpha,", ",Shift,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
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

//---- объявления локальных переменных 
   int first,bar;
   double price0,price1,price2;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
     {
      first=3; // стартовый номер для расчёта всех баров
     }
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      price0=(high[bar]+low[bar])/2.0;
      price1=(high[bar-1]+low[bar-1])/2.0;
      price2=(high[bar-2]+low[bar-2])/2.0;

      if(bar<min_rates_total) ITrendBuffer[bar] = (price0+2.0*price1+price2)/4.0;
      else ITrendBuffer[bar] = K0*price0 + K1*price1 - K2*price2 + K3*ITrendBuffer[bar-1] - K4*ITrendBuffer[bar-2];

      TriggerBuffer[bar]=2.0*ITrendBuffer[bar]-ITrendBuffer[bar-2];
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
