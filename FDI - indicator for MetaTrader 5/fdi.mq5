//+------------------------------------------------------------------------------------------------------------------+
//|                                                                              fractal_dimension.mq5               |
//|                                                            Copyright © 2008, iliko [arcsin5@netscape.net]        |
//|                                                                                                                  |
//|                                                                                                                  |
//|  The Fractal Dimension Index determines the amount of market volatility. The easiest way to use this indicator is|
//|  to understand that a value of 1.5 suggests the market is acting in a completely random fashion.                 |
//|  As the market deviates from 1.5, the opportunity for earning profits is increased in proportion                 |
//|  to the amount of deviation.                                                                                     |
//|  But be carreful, the indicator does not show the direction of trends !!                                         |
//|                                                                                                                  |
//|  The indicator is RED when the market is in a trend. And it is blue when there is a high volatility.             |
//|  When the FDI changes its color from red to blue, it means that a trend is finishing, the market becomes         |
//|  erratic and a high volatility is present. Usually, these "blue times" do not go for a long time.They come before|
//|  a new trend.                                                                                                    |
//|                                                                                                                  |
//|  For more informations, see                                                                                      |
//|  http://www.forex-tsd.com/suggestions-trading-systems/6119-tasc-03-07-fractal-dimension-index.html               |
//|                                                                                                                  |
//|                                                                                                                  |   
//|  HOW TO USE INPUT PARAMETERS :                                                                                   |   
//|  -----------------------------                                                                                   |   
//|                                                                                                                  |   
//|      1) e_period [ integer >= 1 ]                                              =>  30                            |   
//|                                                                                                                  |   
//|         The indicator will compute the historical market volatility over this period.                            |   
//|         Choose its value according to the average of trend lengths.                                              |   
//|                                                                                                                  |   
//|      2) IPC [ ENAM = {                                                                                           | 
//|                               PRICE_CLOSE_ = 1,     //Close                                                      | 
//|                               PRICE_OPEN_,          //Open                                                       | 
//|                               PRICE_HIGH_,          //High                                                       | 
//|                               PRICE_LOW_,           //Low                                                        | 
//|                               PRICE_MEDIAN_,        //Median Price (HL/2)                                        | 
//|                               PRICE_TYPICAL_,       //Typical Price (HLC/3)                                      |
//|                               PRICE_WEIGHTED_,      //Weighted Close (HLCC/4)                                    | 
//|                               PRICE_SIMPL_,         //Simpl Price (OC/2)                                         | 
//|                               PRICE_QUARTER_,       //Quarted Price (HLOC/4)                                     | 
//|                               PRICE_TRENDFOLLOW0_,  //TrendFollow_1 Price                                        | 
//|                               PRICE_TRENDFOLLOW1_,  //TrendFollow_2 Price                                        | 
//|                               PRICE_DEMARK_         //Demark Price                                               | 
//|                                                                                                                  |   
//|         Defines on which price type the Fractal Dimension is computed.                                           |   
//|                                                                                                                  |
//|      3) e_random_line [ 0.0 < double < 2.0 ]                                   => 1.5                            |
//|                                                                                                                  |
//|         Defines your separation betwen a trend market (red) and an erratic/high volatily one.                    |   
//|                                                                                                                  |   
//| v1.0 - February 2007                                                                                             |   
//+------------------------------------------------------------------------------------------------------------------+
#property copyright "Copyright © 2008, iliko [arcsin5@netscape.net]"
#property link "http://fractalfinance.blogspot.com/"
//---- номер версии индикатора
#property version   "1.02"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- количество индикаторных буферов
#property indicator_buffers 2 
//---- использовано всего одно графическое построение
#property indicator_plots   1
//+-----------------------------------+
//|  Параметры отрисовки индикатора   |
//+-----------------------------------+
//---- отрисовка индикатора в виде цветных значков
#property indicator_type1   DRAW_COLOR_ARROW
//---- в качестве цветов трехцветной линии использованы
#property indicator_color1  clrYellow,clrRed,clrMediumPurple
//---- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1  2
//---- отображение метки индикатора
#property indicator_label1  "FRASMAv2"
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
input  uint e_period=30;
input uint normal_speed=20;
input Applied_price_ IPC=PRICE_CLOSE_;//Ценовая константа
input double e_random_line=1.5;  //Уровень срабатывания
input int Shift=0; // Сдвиг индикатора по горизонтали в барах
//+-----------------------------------+

//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[];
double ColorIndBuffer[];

//---- Объявление целых переменных начала отсчета данных
int min_rates_total,g_period_minus_1;
//---- объявление глобальных переменных
int Count[];
double Data[],LOG_2;
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
void OnInit()
  {
//---- Инициализация переменных начала отсчета данных
   g_period_minus_1=int(e_period)-1;
   min_rates_total=int(e_period)+g_period_minus_1;
   LOG_2=MathLog(2.0);
//---- распределение памяти под массивы переменных  
   ArrayResize(Count,e_period);
   ArrayResize(Data,e_period);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_COLOR_INDEX);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(IndBuffer,true);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ColorIndBuffer,true);

//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"FRASMAv2(",e_period,", ",normal_speed,")");
//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);

//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,1);
//---- количество  горизонтальных уровней индикатора 1   
   IndicatorSetInteger(INDICATOR_LEVELS,1);
//---- значения горизонтальных уровней индикатора   
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,e_random_line);
//---- в качестве цвета линии горизонтального уровня использован серый цвет 
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrGray);
//---- в линии горизонтального уровня использован короткий штрих-пунктир  
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DASHDOTDOT);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+ 
//| Custom indicator function                                        | 
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
//---- Объявление целых переменных и получение уже посчитанных баров
   int limit,bar;

//--- расчет стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-1; // стартовый номер для расчета всех баров
      ArrayInitialize(Count,0);
      ArrayInitialize(Data,0.0);
     }
   else
     {
      limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров
     }

//--- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);

//---- Основной цикл расчета индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //---- Вызов функции PriceSeries для получения входной цены price
      Data[Count[0]]=PriceSeries(IPC,bar,open,low,high,close);
      //----
      double priceMax=0.0;
      for(int iii=0; iii<int(e_period); iii++) if(Data[Count[iii]]>priceMax) priceMax=Data[Count[iii]];
      double priceMin=99999999.0;
      for(int iii=0; iii<int(e_period); iii++) if(Data[Count[iii]]<priceMin) priceMin=Data[Count[iii]];
      double range=priceMax-priceMin;
      //----
      double length=0.0;
      double fdi,priorDiff=0.0;
      //----
      for(int kkk=0; kkk<=g_period_minus_1; kkk++)
        {
         if(range>0.0)
           {
            double diff=(Data[Count[kkk]]-priceMin)/range;
            if(kkk>0) length+=MathSqrt(MathPow(diff-priorDiff,2.0)+(1.0/MathPow(e_period,2.0)));
            priorDiff=diff;
           }
        }
      if(length>0.0)
        {
         fdi=1.0+(MathLog(length)+LOG_2)/MathLog(2*g_period_minus_1);
        }
      else
        {
/*
         ** The FDI algorithm suggests in this case a zero value.
         ** I prefer to use the previous FDI value.
         */
         fdi=0.0;
        }
      IndBuffer[bar]=fdi;         
      if(bar) Recount_ArrayZeroPos(Count,e_period);
     }

//---- корректировка значения переменной first
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
      limit--; // стартовый номер для расчета всех баров

//---- Основной цикл раскраски сигнальной линии
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      ColorIndBuffer[bar]=1;
      if(IndBuffer[bar]>e_random_line) ColorIndBuffer[bar]=0;
      if(IndBuffer[bar]<e_random_line) ColorIndBuffer[bar]=2;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+   
//| Получение значения ценовой таймсерии                             |
//+------------------------------------------------------------------+ 
double PriceSeries
(
 uint applied_price,// Ценовая константа
 uint   bar,// Индекс сдвига относительно текущего бара на указанное количество периодов назад или вперёд).
 const double &Open[],
 const double &Low[],
 const double &High[],
 const double &Close[]
 )
//PriceSeries(applied_price, bar, open, low, high, close)
//+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -+
  {
//----
   switch(applied_price)
     {
      //---- Ценовые константы из перечисления ENUM_APPLIED_PRICE
      case  PRICE_CLOSE: return(Close[bar]);
      case  PRICE_OPEN: return(Open [bar]);
      case  PRICE_HIGH: return(High [bar]);
      case  PRICE_LOW: return(Low[bar]);
      case  PRICE_MEDIAN: return((High[bar]+Low[bar])/2.0);
      case  PRICE_TYPICAL: return((Close[bar]+High[bar]+Low[bar])/3.0);
      case  PRICE_WEIGHTED: return((2*Close[bar]+High[bar]+Low[bar])/4.0);

      //----                            
      case  8: return((Open[bar] + Close[bar])/2.0);
      case  9: return((Open[bar] + Close[bar] + High[bar] + Low[bar])/4.0);
      //----                                
      case 10:
        {
         if(Close[bar]>Open[bar])return(High[bar]);
         else
           {
            if(Close[bar]<Open[bar])
               return(Low[bar]);
            else return(Close[bar]);
           }
        }
      //----         
      case 11:
        {
         if(Close[bar]>Open[bar])return((High[bar]+Close[bar])/2.0);
         else
           {
            if(Close[bar]<Open[bar])
               return((Low[bar]+Close[bar])/2.0);
            else return(Close[bar]);
           }
         break;
        }
      //----         
      case 12:
        {
         double res=High[bar]+Low[bar]+Close[bar];
         if(Close[bar]<Open[bar]) res=(res+Low[bar])/2;
         if(Close[bar]>Open[bar]) res=(res+High[bar])/2;
         if(Close[bar]==Open[bar]) res=(res+Close[bar])/2;
         return(((res-Low[bar])+(res-High[bar]))/2);
        }
      //----
      default: return(Close[bar]);
     }
//----
//return(0);
  }
//+------------------------------------------------------------------+
