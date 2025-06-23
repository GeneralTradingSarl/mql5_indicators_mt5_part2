//+------------------------------------------------------------------+
//|                                                    ExTrendV2.mq5 |
//|                           Copyright © 2006, Alex Sidd (Executer) | 
//|                                           mailto:work_st@mail.ru | 
//+------------------------------------------------------------------+ 
//---- авторство индикатора
#property copyright "Copyright © 2006, Alex Sidd (Executer)k"
//---- авторство индикатора
#property link      "mailto:work_st@mail.ru"
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в отдельном окне
#property indicator_separate_window
//---- для расчета и отрисовки индикатора использовано два буфера
#property indicator_buffers 2
//--- использовано всего одно графическое построение
#property indicator_plots   1
//+----------------------------------------------+
//| Параметры отрисовки индикатора 1             |
//+----------------------------------------------+
//--- отрисовка индикатора в виде цветного облака
#property indicator_type1   DRAW_FILLING
//--- в качестве цветов индикатора использованы
#property indicator_color1  clrForestGreen,clrHotPink
//---- отображение метки линии индикатора
#property indicator_label1  "Up Line"
//+----------------------------------------------+
//| Параметры отображения горизонтальных уровней |
//+----------------------------------------------+
#property indicator_level1 0.0
#property indicator_levelcolor clrGray
#property indicator_levelstyle STYLE_DASHDOTDOT
//+----------------------------------------------+
//|  Объявление констант                         |
//+----------------------------------------------+
#define RESET 0       // константа для возврата терминалу команды на пересчет индикатора
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+ 
input color UpLineColor=clrTeal; //цвет тренда верхних фракталов
input color DnLineColor=clrMagenta; //цвет тренда нижних фракталов
input int Shift=0;        // Сдвиг индикатора по горизонтали в барах 
//+----------------------------------------------+
//---- объявление динамических массивов, которые в дальнейшем
//---- будут использованы в качестве индикаторных буферов
double UpBuffer[];
double DnBuffer[];
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//----
string Up_level_name,Dn_level_name;
double FractUp1,FractUp2,FractDn1,FractDn2,Res1,Res2;
datetime FTimeUp1,FTimeUp2,FTimeDn1,FTimeDn2,curTime;
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
                 int      width,         // толщина линии
                 string   text           // текст
                 )
//---- 
  {
//----
   ObjectCreate(chart_id,name,OBJ_TREND,nwin,time1,price1,time2,price2);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetInteger(chart_id,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart_id,name,OBJPROP_WIDTH,width);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,false);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY_RIGHT,true);
   ObjectSetInteger(chart_id,name,OBJPROP_RAY,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTED,true);
   ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,true);
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
              int      width,         // толщина линии
              string   text           // текст
              )
//---- 
  {
//----
   if(ObjectFind(chart_id,name)==-1) CreateTline(chart_id,name,nwin,time1,price1,time2,price2,Color,style,width,text);
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectMove(chart_id,name,0,time1,price1);
      ObjectMove(chart_id,name,1,time2,price2);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
     }
//----
  }
//+------------------------------------------------------------------+
//| Level Calculate Function                                         |
//| функция взята из FractalLines Indicator                          |
//+------------------------------------------------------------------+
double LevelCalculate(double Price1,double Time1,double Price2,double Time2,double NewTime)
  {
//----
   if(Time2!=Time1) return((NewTime-Time1)*(Price2-Price1)/(Time2-Time1)+Price1);
//----
   return(Price2);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+  
double isUpFract(const double &High[],int index)
  {
//----
   if(High[index+3]>High[index+2] && High[index+3]>High[index+4]
      && High[index+4]>High[index+5] && High[index+2]>High[index+1])
      return(High[index+3]);
//---- 
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double isDnFract(const double &Low[],int index)
  {
//----
   if(Low[index+3]<Low[index+2] && Low[index+3]<Low[index+4]
      && Low[index+4]<Low[index+5] && Low[index+2]<Low[index+1])
      return(Low[index+3]);
//---- 
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_total=10;
   FractUp1=0.0;
   FractUp2=0.0;
   FractDn1=0.0;
   FractDn2=0.0;
   Res1=240*60.0;
   Res2=double(1.0/Res1);

//---- превращение динамического массива UpBuffer[] в индикаторный буфер
   SetIndexBuffer(0,UpBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(UpBuffer,true);

//---- превращение динамического массива DnBuffer[] в индикаторный буфер
   SetIndexBuffer(1,DnBuffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(DnBuffer,true);

//---- осуществление сдвига индикатора 1 по горизонтали на Shift
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчета отрисовки индикатора 1 на min_rates_total
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"ExTrend(",Shift,")");
//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,2);
//----  
   Up_level_name=shortname+" Up_level";
   Dn_level_name=shortname+" Dn_level";
   if(ObjectFind(0,Up_level_name)==-1) SetTline(0,Up_level_name,0,0,0,0,0,UpLineColor,0,1,Up_level_name);
   if(ObjectFind(0,Dn_level_name)==-1) SetTline(0,Dn_level_name,0,0,0,0,0,DnLineColor,0,1,Dn_level_name);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//---- удаляем трендовые линии с графика
   ObjectDelete(0,Up_level_name);
   ObjectDelete(0,Dn_level_name);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчета индикатора
                const double& low[],      // ценовой массив минимумов цены  для расчета индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---- проверка количества баров на достаточность для расчета
   if(rates_total<min_rates_total) return(RESET);

//---- объявления локальных переменных 
   int limit;
   double Fup,Fdn,positive,negative;
   static double positive_,negative_;

//---- расчёты необходимого количества копируемых данных и
//стартового номера limit для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчёта индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчёта всех баров
      UpBuffer[limit+1]=0.000000001;
      DnBuffer[limit+1]=0.000000001;
     }
   else
     {
      limit=rates_total-prev_calculated; // стартовый номер для расчёта новых баров
     }

//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
//----   
   positive=positive_;
   negative=negative_;

//---- основной цикл расчёта индикатора
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      negative=0.0;
      positive=0.0;
      Fup=isUpFract(high,bar);
      Fdn=isDnFract(low,bar);

      if(Fup)
        {
         if(!FractUp1 && !FractUp2)
           {
            FractUp1 = Fup;
            FTimeUp1 = time[bar+3];
           }

         if(FractUp1 && !FractUp2 && FTimeUp1!=time[bar+3])
           {
            FractUp2 = Fup;
            FTimeUp2 = time[bar+3];
           }

         if(FractUp1 && FractUp2 && FTimeUp2!=time[bar+3])
           {
            FractUp1 = FractUp2;
            FTimeUp1 = FTimeUp2;
            FractUp2 = Fup;
            FTimeUp2 = time[bar+3];
           }
        }

      if(Fdn)
        {
         if(!FractDn1 && !FractDn2)
           {
            FractDn1 = Fdn;
            FTimeDn1 = time[bar+3];
           }

         if(FractDn1 && !FractDn2 && FTimeDn1!=time[bar+3])
           {
            FractDn2 = Fdn;
            FTimeDn2 = time[bar+3];
           }

         if(FractDn1 && FractDn2 && FTimeDn2!=time[bar+3])
           {
            FractDn1 = FractDn2;
            FTimeDn1 = FTimeDn2;
            FractDn2 = Fdn;
            FTimeDn2 = time[bar+3];
           }
        }

      if(FractUp1 && FractUp2)
        {
         SetTline(0,Up_level_name,0,FTimeUp1,FractUp1,FTimeUp2,FractUp2,UpLineColor,0,1,Up_level_name);
         double y = double((FTimeUp2 - FTimeUp1)/Res1);
         double x = (FractUp2 - FractUp1)*240.0;
         if(!y) y=Res2;
         positive=MathArctan(x/y);
        }

      if(FractDn1 && FractDn2)
        {
         SetTline(0,Dn_level_name,0,FTimeDn1,FractDn1,FTimeDn2,FractDn2,DnLineColor,0,1,Dn_level_name);
         double y = double((FTimeDn2 - FTimeDn1)/Res1);
         double x = (FractDn2 - FractDn1)*240.0;
         if(!y) y=Res2;
         negative=MathArctan(x/y);
        }

      UpBuffer[bar]=positive;
      DnBuffer[bar]=negative;

      if(bar==1)
        {
         positive_=positive;
         negative_=negative;
        }
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
