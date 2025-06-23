//+------------------------------------------------------------------+
//|                                                      GFilter.mq5 |
//|                                         Copyright © 2012, zzuegg | 
//|                                http://when-money-makes-money.com | 
//+------------------------------------------------------------------+
//---- авторство индикатора
#property copyright "Copyright © 2012, zzuegg"
//---- ссылка на сайт автора
#property link      "http://when-money-makes-money.com"
//---- номер версии индикатора
#property version   "1.00"
#property description "This indicator calculates a filterline with the use of gaussian filtration"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- для расчета и отрисовки индикатора использовано четыре буфера
#property indicator_buffers 4
//---- использовано три графических построения
#property indicator_plots   3
//+----------------------------------------------+
//|  Параметры отрисовки линии GFilter           |
//+----------------------------------------------+
//---- отрисовка индикатора в виде многоцветной линии
#property indicator_type1   DRAW_COLOR_LINE
//---- в качестве цветов двухцветной линии использованы
#property indicator_color1  clrTeal,clrCrimson
//---- линия индикатора 1 - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора 1 равна 3
#property indicator_width1  3
//---- отображение бычей метки индикатора
#property indicator_label1  "GFilter"
//+----------------------------------------------+
//|  Параметры отрисовки медвежьего индикатора   |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде символа
#property indicator_type2   DRAW_ARROW
//---- в качестве цвета медвежьего индикатора использован красный цвет
#property indicator_color2  clrMagenta
//---- толщина линии индикатора 2 равна 3
#property indicator_width2  3
//---- отображение медвежьей метки индикатора
#property indicator_label2  "Dn_Signal"
//+----------------------------------------------+
//|  Параметры отрисовки бычьего индикатора      |
//+----------------------------------------------+
//---- отрисовка индикатора 3 в виде символа
#property indicator_type3   DRAW_ARROW
//---- в качестве цвета бычьего индикатора использован зеленый цвет
#property indicator_color3  clrLime
//---- толщина линии индикатора 3 равна 3
#property indicator_width3  3
//---- отображение бычьей метки индикатора
#property indicator_label3  "Up_Signal"
//+----------------------------------------------+
//|  объявление констант                         |
//+----------------------------------------------+
#define pi 3.1415926535
//+----------------------------------------------+
//|  объявление перечислений                     |
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
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input uint FilterPeriod=12;            // Период индикатора
input Applied_price_ IPC=PRICE_CLOSE_; // Ценовая константа
input int Shift=0;                     // Сдвиг индикатора по горизонтали в барах
input int PriceShift=0;                // Сдвиг индикатора по вертикали в пунктах
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double IndBuffer[];
double ColorIndBuffer[];
double BearsBuffer[];
double BullsBuffer[];

double fil_alfa;
//---- Объявление переменной значения вертикального сдвига мувинга
double dPriceShift;
//---- Объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getAlfa(int p)
  {
//----
   double w=2*pi/p;
   double beta=(1-MathCos(w))/(MathPow(1.414,2.0/3)-1);
   double alfa=-beta+MathSqrt(beta*beta+2*beta);
//----
   return (alfa);
  }
//+------------------------------------------------------------------+
//| GSMOOTH                                                          |
//+------------------------------------------------------------------+
double GSMOOTH(double price,double &arr[],double alfa,int index)
  {
//----
   double ret=MathPow(alfa,4)*price+4*(1-alfa)*arr[index-1]-6*MathPow(1-alfa,2)*arr[index-2]+4*MathPow(1-alfa,3)*arr[index-3]-MathPow(1-alfa,4)*arr[index-4];
//----
   return (ret);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Инициализация переменных начала отсчета данных
   min_rates_total=int(FilterPeriod+4);
//---- Инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
//---- Инициализация переменных  
   fil_alfa=getAlfa(FilterPeriod);

//---- превращение динамического массива IndBuffer в индикаторный буфер
   SetIndexBuffer(0,IndBuffer,INDICATOR_DATA);
//---- превращение динамического массива ColorIndBuffer в индикаторный буфер
   SetIndexBuffer(1,ColorIndBuffer,INDICATOR_DATA);
//---- превращение динамического массива BearsBuffer в индикаторный буфер
   SetIndexBuffer(2,BearsBuffer,INDICATOR_DATA);
//---- превращение динамического массива BullsBuffer в индикаторный буфер
   SetIndexBuffer(3,BullsBuffer,INDICATOR_DATA);

//---- осуществление сдвига индикатора 1 по горизонтали на shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора 1
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,FilterPeriod);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

//---- осуществление сдвига индикатора 2 по горизонтали на shift
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора 2
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,FilterPeriod);
//---- выбор символа для отрисовки
   PlotIndexSetInteger(1,PLOT_ARROW,159);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);

//---- осуществление сдвига индикатора 3 по горизонтали на shift
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора 3
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,FilterPeriod);
//---- выбор символа для отрисовки
   PlotIndexSetInteger(2,PLOT_ARROW,159);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"GFilter( ",FilterPeriod," )");
//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//---- объявления локальных переменных 
   int first,bar;
   double series,s1,s2;
//---- расчет стартового номера first для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчета индикатора
     {
      first=int(FilterPeriod)-1; // стартовый номер для расчета всех баров
      IndBuffer[first-1]=PriceSeries(IPC,first-1,open,low,high,close);
      IndBuffer[first-2]=PriceSeries(IPC,first-2,open,low,high,close);
      IndBuffer[first-3]=PriceSeries(IPC,first-3,open,low,high,close);
      IndBuffer[first-4]=PriceSeries(IPC,first-4,open,low,high,close);
     }
   else
     {
      first=prev_calculated-1; // стартовый номер для расчета новых баров
     }
//---- основной цикл расчета индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      BullsBuffer[bar]=0.0;
      BearsBuffer[bar]=0.0;
      //---- Обращение к функции PriceSeries для получения входной цены Series
      series=PriceSeries(IPC,bar,open,low,high,close);
      IndBuffer[bar]=GSMOOTH(series,IndBuffer,fil_alfa,bar);
     }
   if(prev_calculated>rates_total || prev_calculated<=0) first++;
//---- основной цикл раскраски индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      if(IndBuffer[bar]<IndBuffer[bar-1]) ColorIndBuffer[bar]=1;
      else ColorIndBuffer[bar]=0;
     }
   if(prev_calculated>rates_total || prev_calculated<=0) first++;
//---- основной цикл нанесение цветных точек индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      s2=IndBuffer[bar-2]-IndBuffer[bar-1];
      s1=IndBuffer[bar-1]-IndBuffer[bar];
      //----
      if(s1<s2) BullsBuffer[bar]=IndBuffer[bar];
      if(s1>s2) BearsBuffer[bar]=IndBuffer[bar];
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+   
//| Получение значения ценовой таймсерии                             |
//+------------------------------------------------------------------+ 
double PriceSeries(uint applied_price,// Ценовая константа
                   uint   bar,// Индекс сдвига относительно текущего бара на указанное количество периодов назад или вперед).
                   const double &Open[],
                   const double &Low[],
                   const double &High[],
                   const double &Close[])
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
         //----
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
