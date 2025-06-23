//+------------------------------------------------------------------+
//|                                          LaguerreFilterCloud.mq5 |
//|                                                                  |
//| Laguerre Filter                                                  |
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
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- для расчета и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//---- использовано одно графическое построение
#property indicator_plots   1
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цветjd индикатора использованы
#property indicator_color1  clrSandyBrown,clrPaleGreen
//---- отображение бычей метки индикатора
#property indicator_label1  "Laguerre Filter"
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input double Gamma=0.7;// коэффициент индикатора 
input int Shift=0; // сдвиг индикатора по горизонтали в барах 
//+----------------------------------------------+
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве кольцевых буферов
double LaguerreBuffer[],FirBuffer[];
//+------------------------------------------------------------------+
//|  получение среднего от ценовых таймсерий                         |
//+------------------------------------------------------------------+   
double Get_Price(const double  &High[],const double  &Low[],int bar)
// Get_Price(high, low, bar)
//+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -+
  {
//----
   return((High[bar]+Low[bar])/2);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=4;

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,LaguerreBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора 1 на min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,FirBuffer,INDICATOR_DATA);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"Laguerre Filter(",DoubleToString(Gamma,4),", ",Shift,")");
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
   double L0,L1,L2,L3,L0A,L1A,L2A,L3A;

//---- объявления статических переменных для хранения действительных значений коэфициентов
   static double L0_,L1_,L2_,L3_,L0A_,L1A_,L2A_,L3A_;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
     {
      first=0; // стартовый номер для расчёта всех баров
      bar=first;
      L0_ =L0A=Get_Price(high, low, bar);
      L1_ =L1A_=Get_Price(high, low, bar);
      L2_ =L2A_=Get_Price(high, low, bar);
      L3_ =L3A_=Get_Price(high, low, bar);
     }
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- восстанавливаем значения переменных
   L0 = L0_;
   L1 = L1_;
   L2 = L2_;
   L3 = L3_;
   L0A = L0A_;
   L1A = L1A_;
   L2A = L2A_;
   L3A = L3A_;

//---- основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      L0A = L0;
      L1A = L1;
      L2A = L2;
      L3A = L3;
      //----
      L0 = (1 - Gamma) * Get_Price(high, low, bar) + Gamma * L0A;
      L1 = - Gamma * L0 + L0A + Gamma * L1A;
      L2 = - Gamma * L1 + L1A + Gamma * L2A;
      L3 = - Gamma * L2 + L2A + Gamma * L3A;
      //----
      if(bar>min_rates_total)
        {
         LaguerreBuffer[bar]=(L0+2.0*L1+2.0*L2+L3)/6.0;
         FirBuffer[bar]=
                        (
                        1.0*Get_Price(high,low,bar-0)
                        +2.0*Get_Price(high,low,bar-1)
                        +2.0*Get_Price(high,low,bar-2)
                        +1.0*Get_Price(high,low,bar-3)
                        )
                        /6.0;
        }
      else
        {
         L0_=Get_Price(high,low,bar);
         L1_ = L0_;
         L2_ = L0_;
         L3_ = L0_;
         LaguerreBuffer[bar]=FirBuffer[bar]=L0_;
        }

      //--- сохраняем значения переменных
      if(bar<rates_total-1)
        {
         L0_ = L0;
         L1_ = L1;
         L2_ = L2;
         L3_ = L3;
         L0A_ = L0A;
         L1A_ = L1A;
         L2A_ = L2A;
         L3A_ = L3A;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
