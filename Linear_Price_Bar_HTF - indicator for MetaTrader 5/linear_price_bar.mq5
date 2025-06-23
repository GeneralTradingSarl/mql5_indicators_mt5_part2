//+------------------------------------------------------------------+
//|                                             Linear_Price_Bar.mq4 |
//|                                      Copyright © 2006, Keris2112 |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Keris2112"
#property link      ""
#property description ""
//---- номер версии индикатора
#property version   "1.00"
//+----------------------------------------------+
//|  ѕараметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- дл€ расчЄта и отрисовки индикатора использовано п€ть буферов
#property indicator_buffers 5
//---- использовано всего одно графическое построение
#property indicator_plots   1
//---- в качестве индикатора использованы цветные свечи
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrDodgerBlue,clrRed
//---- отображение метки индикатора
#property indicator_label1  "Open;High;Low;Close"
//+----------------------------------------------+
//| ¬ходные параметры индикатора                 |
//+----------------------------------------------+

//+----------------------------------------------+

//---- объ€вление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double ExtOpenBuffer[];
double ExtHighBuffer[];
double ExtLowBuffer[];
double ExtCloseBuffer[];
double ExtColorBuffer[];
//---
int min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- инициализаци€ глобальных переменных 
   min_rates_total=1;

//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(0,ExtOpenBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtHighBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLowBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtCloseBuffer,INDICATOR_DATA);
//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(4,ExtColorBuffer,INDICATOR_COLOR_INDEX);
//---- осуществление сдвига начала отсчЄта отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);

//---- ”становка формата точности отображени€ индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,0);
//---- им€ дл€ окон данных и лэйба дл€ субъокон 
   string short_name="Linear_Price_Bar";
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
//---- проверка количества баров на достаточность дл€ расчЄта
   if(rates_total<min_rates_total) return(0);

//---- объ€влени€ локальных переменных 
   int first,bar;
   double ;

//---- расчЄт стартового номера first дл€ цикла пересчЄта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчЄта индикатора
     {
      first=0; // стартовый номер дл€ расчЄта всех баров
     }
   else first=prev_calculated-1; // стартовый номер дл€ расчЄта новых баров

//---- ќсновной цикл расчЄта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {     
      ExtOpenBuffer[bar]=0.0;
      ExtCloseBuffer[bar]=(close[bar]-open[bar])/_Point;
      ExtHighBuffer[bar]=(high[bar]-open[bar])/_Point;
      ExtLowBuffer[bar]=(low[bar]-open[bar])/_Point;
      
      if(ExtCloseBuffer[bar]<0) ExtColorBuffer[bar]=1;
      else ExtColorBuffer[bar]=0;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
