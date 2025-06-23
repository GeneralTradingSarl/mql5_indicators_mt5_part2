//+---------------------------------------------------------------------+
//|                                                           d_XMA.mq5 | 
//|                                  Copyright © 2011, Дмитрий Бургазли | 
//|                                                      dmitriy62@i.ua | 
//+---------------------------------------------------------------------+ 
//| Для работы  индикатора  следует  положить файл SmoothAlgorithms.mqh |
//| в папку (директорию): каталог_данных_терминала\\MQL5\Include        |
//+---------------------------------------------------------------------+
#property copyright "Copyright © 2011, Дмитрий Бургазли"
#property link "dmitriy62@i.ua"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов
#property indicator_buffers 1 
//---- использовано всего одно графическое построение
#property indicator_plots   1
//+----------------------------------------------+
//| Параметры отрисовки индикатора               |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета линии индикатора использован DodgerBlue цвет
#property indicator_color1 clrDodgerBlue
//---- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1  2
//---- отображение метки индикатора
#property indicator_label1  "d_XMA"
//+----------------------------------------------+
//| Описание класса CXMA                         |
//+----------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+----------------------------------------------+
//---- объявление переменных класса CXMA из файла SmoothAlgorithms.mqh
CXMA XMA1;
//+----------------------------------------------+
//| Объявление перечислений                      |
//+----------------------------------------------+
enum Applied_price_      //Тип константы
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
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input Smooth_Method XMA_Method=MODE_SMA; //Метод усреднения
input uint XLength=80;                   //Глубина сглаживания
input int XPhase=15;                     //Параметр сглаживания
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- для VIDIA это период CMO, для AMA это период медленной скользящей
input Applied_price_ IPC=PRICE_CLOSE;    //Ценовая константа
input int Shift=0;                       //Сдвиг индикатора по горизонтали в барах
input int PriceShift=0;                  //Сдвиг индикатора по вертикали в пунктах
uint Len=3;                              //Глубина обзора
//+----------------------------------------------+
//---- объявление динамического массива, который будет в 
// дальнейшем использован в качестве индикаторного буфера
double IndBuffer[];
//---- объявление переменной значения вертикального сдвига мувинга
double dPriceShift;
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total,resl;
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве кольцевых буферов
int Count[];
double d_XMA[];
//+------------------------------------------------------------------+
//|  Пересчет позиции самого нового элемента в массиве               |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos(int &CoArr[],// Возврат по ссылке номера текущего значения ценового ряда
                          int Size)
  {
//----
   int numb,Max1,Max2;
   static int count=1;
//----
   Max2=Size;
   Max1=Max2-1;
//----
   count--;
   if(count<0) count=Max1;
//----
   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
//----
  }
//+------------------------------------------------------------------+   
//| d_XMA indicator initialization function                          | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_total=GetStartBars(XMA_Method,XLength,XPhase);
   resl=int(XLength-3);
//---- установка алертов на недопустимые значения внешних переменных
   XMA1.XMALengthCheck("XLength",XLength);
   XMA1.XMAPhaseCheck("XPhase",XPhase,XMA_Method);
//---- инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
//---- распределение памяти под массивы переменных  
   ArrayResize(Count,Len);
   ArrayResize(d_XMA,Len);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);
//---- инициализация переменной для короткого имени индикатора
   string shortname;
   string Smooth1=XMA1.GetString_MA_Method(XMA_Method);
   StringConcatenate(shortname,"d_XMA(",XLength,", ",Smooth1,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+ 
//| d_XMA iteration function                                         | 
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
   double price,price1,price2,x1xma=0.0,ma1,ma2;
//---- объявление целочисленных переменных и получение уже посчитанных баров
   int first,bar,p_ma;
   static int p_ma1;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      first=int(XLength)+resl; // стартовый номер для расчета всех баров
      ArrayInitialize(Count,0);
      ArrayInitialize(d_XMA,0.0);
      p_ma1=int(XLength);
     }
   else first=prev_calculated-1; // стартовый номер для расчета новых баров
   p_ma=p_ma1;
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      for(int iii=p_ma+resl; iii>=0; iii--)
        {
         price=PriceSeries(IPC,bar-iii,open,low,high,close);
         x1xma=XMA1.XMASeries(bar-p_ma-resl,prev_calculated,rates_total,XMA_Method,XPhase,p_ma,price,bar-iii,false);
        }
      d_XMA[Count[0]]=x1xma;
      price1=PriceSeries(IPC,bar-1,open,low,high,close);
      price2=PriceSeries(IPC,bar-2,open,low,high,close);
      ma1=d_XMA[Count[1]];
      ma2=d_XMA[Count[2]];
      //----
      if((price1>price2 && price1-ma1>price2-ma2) || (price1<price2 && price1-ma1<price2-ma2))
        {
         p_ma--;
         p_ma=MathMax(2,p_ma);
        }
      //----
      if((price1>ma1 && price2<ma2) || (price1<ma1 && price2>ma2)) p_ma=int(XLength);
      //----       
      IndBuffer[bar]=x1xma+dPriceShift;
      if(bar<rates_total-1)
        {
         Recount_ArrayZeroPos(Count,Len);
         p_ma1=p_ma;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
