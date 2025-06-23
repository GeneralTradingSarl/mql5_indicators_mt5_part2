//+------------------------------------------------------------------+
//|                                      ExtremPriceDistribution.mq5 |
//|                              Copyright © 2012, Khlystov Vladimir |
//|                                         http://cmillion.narod.ru |
//+------------------------------------------------------------------+
//---- авторство индикатора
#property copyright "Copyright © 2012, cmillion@narod.ru"
//---- ссылка на сайт автора
#property link      "http://cmillion.narod.ru"
#property description "Индикатор показывает гистограмму распределения экстемальных цен за период в барах от текущего"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- для расчёта индикатора использовано два буфера
#property indicator_buffers 2
//---- для расчёта и отрисовки индикатора не используются графические построения
#property indicator_plots   0

//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+
input string  SirName="ExtremPriceDistribution";  //Первая часть имени графических объектов
input uint iPeriod=3000;                  //период расчёта 
input int  Shift=-300;                    //сдвиг начального уровня отрисовки гистограммы
input double Dev=30.0;                    //масштаб отрисовки гистограммы
input color PrColor=clrLime;              //цвет количества цен
//+----------------------------------------------+
//--- объявление целочисленных переменных начала отсчета данных
int min_rates_total, iperiod;
//--- объявление целочисленных переменных для хендлов индикаторов
int Ind_Handle;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- инициализация глобальных переменных 
   min_rates_total=int(iPeriod);
   iperiod=int(iPeriod);
//---- Установка формата точности отображения индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- имя для окон данных и лэйба для субъокон 
   string short_name="ExtremPriceDistribution";
   IndicatorSetString(INDICATOR_SHORTNAME,short_name);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   ObjectsDeleteAll(0,SirName,-1,OBJ_TREND);
   Comment("");
//----
   ChartRedraw(0);
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
//---- объявления локальных переменных 
   int to_copy,Pr,limit;
   double max,min,P;
   string txt,name;   

//---- расчёты необходимого количества копируемых данных и
//стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=rates_total-1;
     }
   else
     {
      limit=rates_total-prev_calculated;
     }
   if(!limit) return(rates_total);
   to_copy=limit+1;
      
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(time,true);
//---- сдвигаем отрисовку гистограммы по горизонтали
   datetime TimeSt = time[0]+PeriodSeconds()*Shift;
//----   
   max=high[ArrayMaximum(high,0,iperiod)];
   min=low[ArrayMinimum(low,0,iperiod)];
   iperiod=MathMin(iperiod,rates_total-1);
   txt="";
   StringConcatenate(txt,"Баров в истории ",iperiod," с ",TimeToString(time[iperiod],TIME_DATE),
                         "\nМаксимум ",DoubleToString(max,_Digits),"\nМинимум ",DoubleToString(min,_Digits));
   Comment(txt,"\n","Старт расчета ",TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS));

   Pr=int((max-min)/_Point);
   double Price[];
   ArrayResize(Price,Pr);
   ArrayInitialize(Price,0);
   for(int bar=1; bar<=int(iperiod); bar++)
     {
      for(int kkk=0; kkk<Pr; kkk++)
        {
         P=NormalizeDouble(min+kkk*_Point,_Digits);
         if(low[bar]==P || high[bar]==P) Price[kkk]++;
        }
     }
     
   for(int rrr=0; rrr<Pr; rrr++)
     {
      P=NormalizeDouble(min+rrr*_Point,_Digits);
      name="";
      StringConcatenate(name,SirName," ",P);
      SetTline(0,name,0,TimeSt,P,datetime(TimeSt+Price[rrr]*Dev*PeriodSeconds()),P,PrColor,0,3);
     }
//----     
   ChartRedraw(0);
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  Создание трендовой линии                                        |
//+------------------------------------------------------------------+
void CreateTline(
                 long     chart_id,      // идентификатор графика
                 string   name,          // имя объекта
                 int      nwin,          // индекс окна
                 datetime time1,         // время 1 ценового уровня
                 double   price1,        // 1 ценовой уровень
                 datetime time2,         // время 2 ценового уровня
                 double   price2,        // 2 ценовой уровень
                 color    Color,         // цвет линии
                 int      style,         // стиль линии
                 int      width          // толщина линии
                 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_TREND,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,false);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,true);
//----
  }
//+------------------------------------------------------------------+
//|  Переустановка трендовой линии                                   |
//+------------------------------------------------------------------+
void SetTline(
              long     chart_id,      // идентификатор графика
              string   name,          // имя объекта
              int      nwin,          // индекс окна
              datetime time1,         // время 1 ценового уровня
              double   price1,        // 1 ценовой уровень
              datetime time2,         // время 2 ценового уровня
              double   price2,        // 2 ценовой уровень
              color    Color,         // цвет линии
              int      style,         // стиль линии
              int      width          // толщина линии
              )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateTline(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width);
   else
     {
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
      ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
      ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
     }
//----
  }
//+------------------------------------------------------------------+
