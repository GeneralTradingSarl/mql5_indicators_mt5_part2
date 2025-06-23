//+------------------------------------------------------------------+
//|                                        DonchianChannelsCloud.mq5 |
//|                         Copyright © 2005, Luis Guilherme Damiani |
//|                                      http://www.damianifx.com.br |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, Luis Guilherme Damiani"
#property link      "http://www.damianifx.com.br"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//--- для расчета и отрисовки индикатора использовано семь буферов
#property indicator_buffers 7
//--- использовано пять графических построений
#property indicator_plots   5
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цвета облака использован LightSkyBlue
#property indicator_color1  clrLightSkyBlue
//---- отображение метки индикатора
#property indicator_label1  "Upper Cloud"
//+----------------------------------------------+
//|  Параметры отрисовки верхней границы         |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде линии
#property indicator_type2   DRAW_LINE
//---- в качестве цвета бычей линии индикатора использован DodgerBlue
#property indicator_color2  clrDodgerBlue
//---- линия индикатора 2 - непрерывная кривая
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора 2 равна 2
#property indicator_width2  2
//---- отображение бычей метки индикатора
#property indicator_label2  "Upper Donchian"
//+----------------------------------------------+
//|  Параметры отрисовки средней линии           |
//+----------------------------------------------+
//---- отрисовка индикатора 3 в виде линии
#property indicator_type3   DRAW_LINE
//---- в качестве цвета медвежьей линии индикатора использован DarkViolet
#property indicator_color3  clrDarkViolet
//---- линия индикатора 3 - непрерывная кривая
#property indicator_style3  STYLE_SOLID
//---- толщина линии индикатора 3 равна 2
#property indicator_width3  2
//---- отображение медвежьей метки индикатора
#property indicator_label3  "Middle Donchian"
//+----------------------------------------------+
//|  Параметры отрисовки нижней границы          |
//+----------------------------------------------+
//---- отрисовка индикатора 4 в виде линии
#property indicator_type4   DRAW_LINE
//---- в качестве цвета медвежьей линии индикатора использован Magenta
#property indicator_color4  clrMagenta
//---- линия индикатора 4 - непрерывная кривая
#property indicator_style4  STYLE_SOLID
//---- толщина линии индикатора 4 равна 2
#property indicator_width4  2
//---- отображение медвежьей метки индикатора
#property indicator_label4  "Lower Donchian"
//+----------------------------------------------+
//|  Параметры отрисовки облака                  |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type5   DRAW_FILLING
//---- в качестве цвета облака использован Violet
#property indicator_color5  clrViolet
//---- отображение метки индикатора
#property indicator_label5  "Lower Cloud"
//+-----------------------------------+
//|  Объявление перечисления          |
//+-----------------------------------+
enum Applied_Extrem //Тип экстремумов
  {
   HIGH_LOW,
   HIGH_LOW_OPEN,
   HIGH_LOW_CLOSE,
   OPEN_HIGH_LOW,
   CLOSE_HIGH_LOW
  };
//+-----------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА     |
//+-----------------------------------+
input int DonchianPeriod=20; //Период усреднения
input Applied_Extrem Extremes=HIGH_LOW; //Тип экстремумов
input int Margins=-2;
input int Shift = 0; // сдвиг индикатора по горизонтали в барах
//+-----------------------------------+
//---- объявление динамических массивов, которые будут в дальнейшем использованы в качестве индикаторных буферов
double ExtUp1Buffer[];
double ExtUp2Buffer[];
double ExtABuffer[];
double ExtBBuffer[];
double ExtCBuffer[];
double ExtDn1Buffer[];
double ExtDn2Buffer[];
//---- Объявление целых переменных начала отсчёта данных
int  min_rates_total;
//+------------------------------------------------------------------+
//|  searching index of the highest bar                              |
//+------------------------------------------------------------------+
int iHighest(
             const double &array[],// массив для поиска индекса максимального элемента
             int count,// число элементов массива (в направлении от текущего бара в сторону убывания индекса), 
             // среди которых должен быть произведен поиск.
             int startPos //индекс (смещение относительно текущего бара) начального бара, 
             // с которого начинается поиск наибольшего значения
             )
  {
//----+
   int index=startPos;

//---- проверка стартового индекса на корректность
   if(startPos<0)
     {
      Print("Неверное значение в функции iHighest, startPos = ",startPos);
      return(0);
     }

//---- проверка значения startPos на корректность
   if(startPos-count<0)
      count=startPos;

   double max=array[startPos];

//---- поиск индекса
   for(int i=startPos; i>startPos-count; i--)
     {
      if(array[i]>max)
        {
         index=i;
         max=array[i];
        }
     }
//----+ возврат индекса наибольшего бара
   return(index);
  }
//+------------------------------------------------------------------+
//|  searching index of the lowest bar                               |
//+------------------------------------------------------------------+
int iLowest(
            const double &array[],// массив для поиска индекса минимального элемента
            int count,// число элементов массива (в направлении от текущего бара в сторону убывания индекса), 
            // среди которых должен быть произведен поиск.
            int startPos //индекс (смещение относительно текущего бара) начального бара, 
            // с которого начинается поиск наименьшего значения
            )
  {
//----+
   int index=startPos;

//---- проверка стартового индекса на корректность
   if(startPos<0)
     {
      Print("Неверное значение в функции iLowest, startPos = ",startPos);
      return(0);
     }

//---- проверка значения startPos на корректность
   if(startPos-count<0)
      count=startPos;

   double min=array[startPos];

//---- поиск индекса
   for(int i=startPos; i>startPos-count; i--)
     {
      if(array[i]<min)
        {
         index=i;
         min=array[i];
        }
     }
//----+ возврат индекса наименьшего бара
   return(index);
  }
//+------------------------------------------------------------------+    
//| Donchian Channel indicator initialization function               | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=int(DonchianPeriod)+1;
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,ExtUp1Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtUp2Buffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- осуществление сдвига индикатора по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(2,ExtABuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- осуществление сдвига индикатора по горизонтали
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(3,ExtBBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- осуществление сдвига индикатора по горизонтали
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(4,ExtCBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- осуществление сдвига индикатора по горизонтали
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
   
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(5,ExtDn1Buffer,INDICATOR_DATA);
   SetIndexBuffer(6,ExtDn2Buffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- осуществление сдвига индикатора по горизонтали
   PlotIndexSetInteger(4,PLOT_SHIFT,Shift);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"Donchian( DonchianPeriod = ",DonchianPeriod,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+  
//| Donchian Channel iteration function                              | 
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
   if(rates_total<min_rates_total) return(0);

//---- Объявление переменных с плавающей точкой  
   double smin,smax,SsMax=0,SsMin=0;
//---- Объявление целых переменных
   int first,bar;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated==0) // проверка на первый старт расчёта индикатора
     {
      first=min_rates_total-1; // стартовый номер для расчёта всех баров
     }
   else
     {
      first=prev_calculated-1;// стартовый номер для расчёта новых баров
     }

//---- Основной цикл расчёта канала
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      switch(Extremes)
        {
         case HIGH_LOW:
            SsMax=high[iHighest(high,DonchianPeriod,bar)];
            SsMin=low[iLowest(low,DonchianPeriod,bar)];
            break;

         case HIGH_LOW_OPEN:
            SsMax=(open[iHighest(open,DonchianPeriod,bar)]+high[iHighest(high,DonchianPeriod,bar)])/2;
            SsMin=(open[iLowest(open,DonchianPeriod,bar)]+low[iLowest(high,DonchianPeriod,bar)])/2;
            break;

         case HIGH_LOW_CLOSE:
            SsMax=(close[iHighest(close,DonchianPeriod,bar)]+high[iHighest(high,DonchianPeriod,bar)])/2;
            SsMin=(close[iLowest(close,DonchianPeriod,bar)]+low[iLowest(high,DonchianPeriod,bar)])/2;
            break;

         case OPEN_HIGH_LOW:
            SsMax=open[iHighest(open,DonchianPeriod,bar)];
            SsMin=open[iLowest(open,DonchianPeriod,bar)];
            break;

         case CLOSE_HIGH_LOW:
            SsMax=close[iHighest(close,DonchianPeriod,bar)];
            SsMin=close[iLowest(close,DonchianPeriod,bar)];
            break;
        }

      smin=SsMin+(SsMax-SsMin)*Margins/100;
      smax=SsMax-(SsMax-SsMin)*Margins/100;      
      ExtABuffer[bar]=smax;
      ExtCBuffer[bar]=smin;
      ExtBBuffer[bar]=(smax+smin)/2.0;
      ExtUp1Buffer[bar]=ExtABuffer[bar];
      ExtUp2Buffer[bar]=ExtBBuffer[bar];
      ExtDn1Buffer[bar]=ExtBBuffer[bar];
      ExtDn2Buffer[bar]=ExtCBuffer[bar];
     }
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
