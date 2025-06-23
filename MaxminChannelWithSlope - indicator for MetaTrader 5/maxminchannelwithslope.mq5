//+------------------------------------------------------------------+ 
//|                                       MaxminChannelWithSlope.mq5 | 
//|                                         Copyright © 2016, fajuzi | 
//|                                             fajuzi@yahoo.it 2015 | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2016, fajuzi"
#property link "fajuzi@yahoo.it 2015"
#property description "simple max - min channel with ema slope"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов 2
#property indicator_buffers 2 
//---- использовано одно графическое построение
#property indicator_plots   1
//+-----------------------------------+
//| Параметры отрисовки индикатора    |
//+-----------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//---- в качестве цвета индикатора использован
#property indicator_color1  clrPaleTurquoise
//---- отображение метки индикатора
#property indicator_label1  "MaxminChannelWithSlope"
//+-----------------------------------+
//| Входные параметры индикатора      |
//+-----------------------------------+
input uint      barre=20;      // Bars for calculation min max
input double   ratio=4.0;      // Ratio EMA period / bars
input double   xslope=1.0;     // Slope adjustment
//+-----------------------------------+
//---- объявление целочисленных переменных начала отсчета данных
int  min_rates_total;
double cosemap,emap,xslp,pendenzaxslp;
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double UpBuffer[];
double DnBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_total=3;
   xslp=xslope*0.5;//adjustment of slope
   emap=barre*ratio;//period
   cosemap=(emap+1.0)/2.0;//constant
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,UpBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(UpBuffer,true);
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,DnBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(DnBuffer,true);
//---- инициализация переменной для короткого имени индикатора   
   string shortname;
   StringConcatenate(shortname,"MaxminChannelWithSlope(",barre,", ",DoubleToString(ratio,2),", ",xslope,")");
//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+  
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &Tick_Volume[],
                const long &Volume[],
                const int &Spread[])
  {
//---- проверка количества баров на достаточность для расчета
   if(rates_total<min_rates_total) return(0);
//---- объявление переменных с плавающей точкой  
   double pendenza;
   static double pendenza_prev;
//---- объявление целочисленных переменных
   int limit;
//---- расчет стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчета всех баров
      pendenza_prev=0.0;
     }
   else limit=rates_total-prev_calculated;  // стартовый номер для расчета только новых баров
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(High,true);
   ArraySetAsSeries(Low,true);
//---- основной цикл расчета индикатора
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      pendenza=pendenza_prev+(High[bar]+Low[bar]-High[bar+1]-Low[bar+1]-pendenza_prev)/cosemap;
      pendenzaxslp=pendenza*xslp;
      //----
      switch(bar+1-ArrayMaximum(High,bar,barre))
        {
         case 0 : UpBuffer[bar+1]=High[bar+1]; break;
         default : UpBuffer[bar+1]=UpBuffer[bar+2]+pendenzaxslp;
        }
      switch(bar+1-ArrayMinimum(Low,bar,barre))
        {
         case 0 : DnBuffer[bar+1]=Low[bar+1]; break;
         default : DnBuffer[bar+1]=DnBuffer[bar+2]+pendenzaxslp;
        }
      if(bar) pendenza_prev=pendenza;
     }
   UpBuffer[0]=UpBuffer[1]+pendenzaxslp;
   DnBuffer[0]=DnBuffer[1]+pendenzaxslp;
//----    
   return(rates_total);
  }
//+------------------------------------------------------------------+
