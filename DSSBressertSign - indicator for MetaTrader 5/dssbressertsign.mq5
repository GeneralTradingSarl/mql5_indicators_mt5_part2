//+------------------------------------------------------------------+
//|                                              DSSBressertSign.mq5 |
//|                      Copyright © 2008, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2008, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"
//---- номер версии индикатора
#property version   "1.00"
//--- отрисовка индикатора в главном окне
#property indicator_chart_window 
//--- для расчета и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//--- использовано всего два графических построения
#property indicator_plots   2
//+----------------------------------------------+
//|  Параметры отрисовки медвежьего индикатора   |
//+----------------------------------------------+
//--- отрисовка индикатора 1 в виде символа
#property indicator_type1   DRAW_ARROW
//--- в качестве цвета медвежьей линии индикатора использован розовый цвет
#property indicator_color1  clrMagenta
//--- толщина линии индикатора 1 равна 5
#property indicator_width1  5
//--- отображение бычей метки индикатора
#property indicator_label1  "DSSBressertSign Sell"
//+----------------------------------------------+
//|  Параметры отрисовки бычьго индикатора       |
//+----------------------------------------------+
//--- отрисовка индикатора 2 в виде символа
#property indicator_type2   DRAW_ARROW
//--- в качестве цвета бычей линии индикатора использован зеленый цвет
#property indicator_color2  clrLimeGreen
//--- толщина линии индикатора 2 равна 5
#property indicator_width2  5
//--- отображение медвежьей метки индикатора
#property indicator_label2 "DSSBressertSign Buy"
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define RESET  0 // Константа для возврата терминалу команды на пересчёт индикатора
//+----------------------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА                |
//+----------------------------------------------+
input uint  EMA_period=8;  //период EMA
input uint  Sto_period=13; //период стохастика
input int   Shift=0;       //сдвиг индикатора по горизонтали в барах
//+----------------------------------------------+
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//--- объявление динамических массивов, которые в дальнейшем будут использованы в качестве индикаторных буферов
double SellBuffer[],BuyBuffer[];
//---- Объявление глобальных переменных
double smooth_coefficient;
//---- Объявление целых переменных для хендлов индикаторов
int ATR_Handle;
//---- объявление глобальных переменных
int Count[];
double Mit[];
//+------------------------------------------------------------------+
//|  Пересчет позиции самого нового элемента в массиве               |
//+------------------------------------------------------------------+   
void Recount_ArrayZeroPos(int &CoArr[],// Возврат по ссылке номера текущего значения ценового ряда
                          int Size)
  {
//----
   int numb,Max1,Max2;
   static int count=1;

   Max2=Size;
   Max1=Max2-1;

   count--;
   if(count<0) count=Max1;

   for(int iii=0; iii<Max2; iii++)
     {
      numb=iii+count;
      if(numb>Max1) numb-=Max2;
      CoArr[iii]=numb;
     }
//----
  }
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
int OnInit()
  {
//--- получение хендла индикатора ATR
   int ATR_Period=12;
   ATR_Handle=iATR(NULL,0,ATR_Period);
   if(ATR_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора ATR");
      return(INIT_FAILED);
     }
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=int(MathMax(ATR_Period,Sto_period+1));
//---- Инициализация переменных   
   smooth_coefficient=2.0/(1.0+EMA_period);
//---- распределение памяти под массивы переменных  
   ArrayResize(Count,Sto_period);
   ArrayResize(Mit,Sto_period);
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
//--- осуществление сдвига начала отсчета отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- символ для индикатора
   PlotIndexSetInteger(0,PLOT_ARROW,170);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(SellBuffer,true);
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
//--- осуществление сдвига начала отсчета отрисовки индикатора 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//--- символ для индикатора
   PlotIndexSetInteger(1,PLOT_ARROW,170);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(BuyBuffer,true);
//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"DSS Bressert(",EMA_period,", ",Sto_period,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- завершение инициализации
   return(INIT_SUCCEEDED);
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
//--- проверка количества баров на достаточность для расчета
   if(BarsCalculated(ATR_Handle)<rates_total || rates_total<min_rates_total) return(RESET);

//---- Объявление переменных с плавающей точкой  
   double HighRange,LowRange,delta,MIT,DSS,Dss,ATR[],diff;
   static double Dss_prev;
//---- Объявление целых переменных и получение уже посчитанных баров
   int to_copy,limit,bar;

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(ATR,true);

//---- расчет стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчета всех баров
      ArrayInitialize(Count,0);
      ArrayInitialize(Mit,50.0);
      Dss_prev=50;
     }
   else limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров
   to_copy=limit+1;

//--- копируем вновь появившиеся данные в массив ATR[]
   if(CopyBuffer(ATR_Handle,0,0,to_copy,ATR)<=0) return(RESET);

//---- основной цикл расчета индикатора Mit
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      HighRange=high[ArrayMaximum(high,bar,Sto_period)];
      LowRange=low[ArrayMinimum(low,bar,Sto_period)];
      delta=close[bar]-LowRange;
      diff=(HighRange-LowRange)*100.0;
      if(!diff) diff=_Point*100.0;
      MIT=delta/(HighRange-LowRange)*100.0;
      Mit[Count[0]]=smooth_coefficient*(MIT-Mit[Count[1]])+Mit[Count[1]];
      HighRange=Mit[ArrayMaximum(Mit,0,Sto_period)];
      LowRange=Mit[ArrayMinimum(Mit,0,Sto_period)];
      delta=Mit[Count[0]]-LowRange;
      DSS=delta/(HighRange-LowRange)*100.0;
      Dss=smooth_coefficient*(DSS-Dss_prev)+Dss_prev;
      //---
      BuyBuffer[bar]=NULL;
      SellBuffer[bar]=NULL;
      //---
      if(Mit[Count[1]]<=Dss_prev && Mit[Count[0]]>Dss) BuyBuffer[bar]=low[bar]-ATR[bar]*3/8;
      if(Mit[Count[1]]>=Dss_prev && Mit[Count[0]]<Dss) SellBuffer[bar]=high[bar]+ATR[bar]*3/8;
      //---
      if(bar<rates_total-1)
        {
         Dss_prev=Dss;
         Recount_ArrayZeroPos(Count,Sto_period);
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
