//+------------------------------------------------------------------+
//|                                                       dTrend.mq5 |
//|                                                     Yuriy Tokman |
//|                                            yuriytokman@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Yuriy Tokman"
#property link      "yuriytokman@gmail.com"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window 
//---- количество индикаторных буферов
#property indicator_buffers 4 
//+-----------------------------------+
//|  Параметры отрисовки индикатора   |
//+-----------------------------------+
//---- использовано всего два графических построения
#property indicator_plots   2
//---- отрисовка индикатора в виде цветной гистограммы
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_type2   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrGreen,clrLime
#property indicator_color2  clrPurple,clrMagenta
#property indicator_width1  2
#property indicator_width2  2
#property indicator_label1  "dTrend Upper"
#property indicator_label2  "dTrend Lower"
//+-----------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА     |
//+-----------------------------------+
input uint Rasrad=16;
input uint Level=15; // уровень срабатывания
input int Shift=0;   // сдвиг индикатора по горизонтали в барах
//+-----------------------------------+
//---- индикаторные буферы
double UpColorsBuffer[];
double LoColorsBuffer[];
double UpperBuffer[];
double LowerBuffer[];

int min_rates_total; 
//+------------------------------------------------------------------+    
//| Momentum indicator initialization function                       | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=int(Rasrad)+1;
//----   
   SetIndexBuffer(0,UpperBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,UpColorsBuffer,INDICATOR_COLOR_INDEX);
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   SetIndexBuffer(2,LowerBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,LoColorsBuffer,INDICATOR_COLOR_INDEX);
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"dTrend(Rasrad=",Rasrad,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);  
//---- количество  горизонтальных уровней индикатора 2  
   IndicatorSetInteger(INDICATOR_LEVELS,2);
//---- значения горизонтальных уровней индикатора   
   IndicatorSetDouble(INDICATOR_LEVELVALUE,0,+Level);
   IndicatorSetDouble(INDICATOR_LEVELVALUE,1,-Level);
//---- в качестве цветов линий горизонтальных уровней использованы серый и розовый цвета  
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,0,clrBlue);
   IndicatorSetInteger(INDICATOR_LEVELCOLOR,1,clrRed);
//---- в линии горизонтального уровня использован короткий штрих-пунктир  
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,0,STYLE_DASHDOTDOT);
   IndicatorSetInteger(INDICATOR_LEVELSTYLE,1,STYLE_DASHDOTDOT);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+  
//| Momentum iteration function                                      | 
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
   double price;
//---- Объявление целых переменных и получение уже посчитанных баров
   int first,bar,count;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
      first=min_rates_total; // стартовый номер для расчёта всех баров
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- Основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      price=high[bar];
      if(price>high[bar-1])
        {
         count=1;
         while(price>high[bar-count])
           {
            count++;
            if(count>int(Rasrad)) break;
           }
         UpperBuffer[bar]=count-1;
        }
      else UpperBuffer[bar]=NULL; 

      price=low[bar];

      if(price<low[bar-1])
        {
         count=1;
         while(price<low[bar-count])
           {
            count++;
            if(count>int(Rasrad)) break;
           }
         LowerBuffer[bar]=1-count;
        }
      else LowerBuffer[bar]=NULL;
      //----     
      if(UpperBuffer[bar]>=+Level) UpColorsBuffer[bar]=1;
      else UpColorsBuffer[bar]=0; 
      //----
      if(LowerBuffer[bar]<=-Level) LoColorsBuffer[bar]=1;
      else LoColorsBuffer[bar]=0; 
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+ 
