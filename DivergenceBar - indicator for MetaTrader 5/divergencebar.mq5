//+------------------------------------------------------------------+
//|                                                DivergenceBar.mq5 |
//|                      Copyright © 2010, Dmitry Zhebrak aka Necron | 
//|                                                  www.mqlcoder.ru | 
//+------------------------------------------------------------------+
//--- авторство индикатора
#property copyright "Copyright © 2010, Dmitry Zhebrak aka Necron"
//--- ссылка на сайт автора
#property link      "www.mqlcoder.ru"
//--- номер версии индикатора
#property version   "1.00"
//--- отрисовка индикатора в главном окне
#property indicator_chart_window 
//--- для расчета и отрисовки индикатора использовано три буфера
#property indicator_buffers 3
//--- использовано всего одно графическое построение
#property indicator_plots   2
//+----------------------------------------------+
//|  Параметры отрисовки индикатора              |
//+----------------------------------------------+
//---- отрисовка индикатора в виде многоцветной гистограммы
#property indicator_type1   DRAW_COLOR_HISTOGRAM2
//---- в качестве цветов трёхцветной линии использованы
#property indicator_color1  clrLime,clrRed
//---- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1  2
//---- отображение метки индикатора
#property indicator_label1  "DivergenceBar"
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define RESET  0 // Константа для возврата терминалу команды на пересчёт индикатора
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input ENUM_MA_METHOD SmoothMethod=MODE_SMMA; //метод усреднения цены
input ENUM_APPLIED_PRICE IPC=PRICE_MEDIAN; //ценовая константа
//+----------------------------------------------+
//--- объявление динамических массивов, которые в дальнейшем
//--- будут использованы в качестве индикаторных буферов
double DnBuffer[],UpBuffer[],ColorBuffer[];
//---
int Ind_Handle,min_rates_total;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- инициализация глобальных переменных 
   min_rates_total=int(MathMax(13+8,MathMax(8+5,5+3)))+1;
//--- получение хендла индикатора iAlligator
   Ind_Handle=iAlligator(Symbol(),Period(),13,8,8,5,5,3,SmoothMethod,IPC);
   if(Ind_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора iAlligator");
      return(INIT_FAILED);
     }

//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,DnBuffer,INDICATOR_DATA);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(DnBuffer,true);
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(1,UpBuffer,INDICATOR_DATA);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(UpBuffer,true);
//--- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(2,ColorBuffer,INDICATOR_DATA);
//--- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ColorBuffer,true);

//--- осуществление сдвига начала отсчета отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- Установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- имя для окон данных и метка для подокон 
   string short_name="DivergenceBar";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//---   
   return(INIT_SUCCEEDED);
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
//--- проверка количества баров на достаточность для расчета
   if(BarsCalculated(Ind_Handle)<rates_total || rates_total<min_rates_total) return(RESET);

//--- объявления локальных переменных 
   int to_copy,limit,bar,clr=0;
   double Ind1[],Ind2[],Ind3[];
   double lips,teeth,jaw,up,dn;

//--- расчеты необходимого количества копируемых данных и
//стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_total; // стартовый номер для расчета всех баров
     }
   else
     {
      limit=rates_total-prev_calculated; // стартовый номер для расчета новых баров
     }
   to_copy=limit+1;
//--- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(Ind_Handle,GATORLIPS_LINE,0,to_copy,Ind1)<=0) return(RESET);
   if(CopyBuffer(Ind_Handle,GATORTEETH_LINE,0,to_copy,Ind2)<=0) return(RESET);
   if(CopyBuffer(Ind_Handle,GATORJAW_LINE,0,to_copy,Ind3)<=0) return(RESET);
//--- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(Ind1,true);
   ArraySetAsSeries(Ind2,true);
   ArraySetAsSeries(Ind3,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);

//--- основной цикл расчета индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      lips=Ind1[bar];
      teeth=Ind2[bar];
      jaw=Ind3[bar];
      //---
      up=MathMax(lips,MathMax(teeth,jaw));
      dn=MathMin(lips,MathMin(teeth,jaw));
      //---
      UpBuffer[bar]=low[bar]+(high[bar]-low[bar])/2+(high[bar]-low[bar])/10;
      DnBuffer[bar]=low[bar]+(high[bar]-low[bar])/2-(high[bar]-low[bar])/10;
      //---
      if(high[bar]>high[bar+1] && close[bar]<high[bar]-0.5*(high[bar]-low[bar]) && low[bar]>up) clr=0;
      else if(low[bar]<low[bar+1] && close[bar]>low[bar]+0.5*(high[bar]-low[bar]) && high[bar]<dn) clr=1;
      ColorBuffer[bar]=clr;
     }
//---     
   return(rates_total);
  }
//+------------------------------------------------------------------+
