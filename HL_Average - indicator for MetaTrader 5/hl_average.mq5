//+------------------------------------------------------------------+ 
//|                                                   HL_Average.mq5 | 
//|                                           Copyright © 2007, KCBT | 
//|                              http://www.kcbt.ru/forum/index.php? | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2007, KCBT"
#property link "http://www.kcbt.ru/forum/index.php?"
//---- номер версии индикатора
#property version   "2.00"
#property description "Линии сопротивлений и поддержки по фиксированному таймфрейму"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window
//---- количество индикаторных буферов 7
#property indicator_buffers 7 
//---- использовано всего пять графических построений
#property indicator_plots   5
//+----------------------------------------------+
//| Объявление констант                          |
//+----------------------------------------------+
#define RESET 0                         // константа для возврата терминалу команды на пересчет индикатора
//+----------------------------------------------+
//| Параметры отрисовки индикатора 1             |
//+----------------------------------------------+
//---- отрисовка индикатора 1 в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета индикатора использован
#property indicator_color1  clrLimeGreen
//---- толщина линии индикатора 1 равна 2
#property indicator_width1  2
//---- отображение метки индикатора
#property indicator_label1  "HL Up"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 2             |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде линии
#property indicator_type2   DRAW_LINE
//---- в качестве цвета индикатора использован
#property indicator_color2  clrDodgerBlue
//---- толщина линии индикатора 2 равна 2
#property indicator_width2  2
//---- отображение метки индикатора
#property indicator_label2  "HL Pivot"
//+----------------------------------------------+
//| Параметры отрисовки индикатора 3             |
//+----------------------------------------------+
//---- отрисовка индикатора 3 в виде линии
#property indicator_type3   DRAW_LINE
//---- в качестве цвета индикатора использован
#property indicator_color3  clrMagenta
//---- толщина линии индикатора 2 равна 2
#property indicator_width3  2
//---- отображение метки индикатора
#property indicator_label3  "HL Down"
//+----------------------------------------------+
//| Параметры отрисовки облака  1                |
//+----------------------------------------------+
//---- отрисовка индикатора 4 в виде облака
#property indicator_type4   DRAW_FILLING
//---- в качестве цвета индикатора использован цвет PaleTurquoise
#property indicator_color4  clrPaleTurquoise
//---- отображение метки индикатора
#property indicator_label4  "HL Up Cloud"
//+----------------------------------------------+
//| Параметры отрисовки облака  2                |
//+----------------------------------------------+
//---- отрисовка индикатора 5 в виде облака
#property indicator_type5   DRAW_FILLING
//---- в качестве цвета индикатора использован цвет MistyRose
#property indicator_color5  clrMistyRose
//---- отображение метки индикатора
#property indicator_label5  "HL Down Cloud"
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_D1;   // Период графика для расчета уровней
input bool ShowComment=true;                 // Отрисовка комментария
input int  Shift=0;                          // Сдвиг индикатора по горизонтали в барах
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
//---- дальнейшем использованы в качестве индикаторных буферов
double Ind1Buffer[];
double Ind2Buffer[];
double Ind3Buffer[];
double Ind4Buffer[];
double Ind5Buffer[];
double Ind6Buffer[];
double Ind7Buffer[];
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- проверка таймфрейма индикатора на корректность
   if(!TimeFramesCheck("HL",TimeFrame,Period())) return(INIT_FAILED);
//---- инициализация переменных 
   min_rates_total=2;
//---- инициализация индикаторных буферов
   BufInit(0,Ind1Buffer);
   BufInit(1,Ind2Buffer);
   BufInit(2,Ind3Buffer);
   BufInit(3,Ind4Buffer);
   BufInit(4,Ind5Buffer);
   BufInit(5,Ind6Buffer);
   BufInit(6,Ind7Buffer);
//----
   IndInit(0,0.0,min_rates_total,Shift);
   IndInit(1,0.0,min_rates_total,Shift);
   IndInit(2,0.0,min_rates_total,Shift);
   IndInit(3,EMPTY_VALUE,min_rates_total,Shift);
   IndInit(4,EMPTY_VALUE,min_rates_total,Shift);
//---- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   string shortname;
   StringConcatenate(shortname,"HL(",EnumToString(TimeFrame),")");
//----
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//---- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//---- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   Comment("");
//----
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
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
   if(rates_total<min_rates_total) return(RESET);
//---- объявление целочисленных переменных
   int limit,bar;
//---- объявление переменных с плавающей точкой  
   double last_close,last_high,last_low,P=0.0,R=0.0,S=0.0;
   datetime iTime[1];
   static uint LastCountBar;
   static double prev_low,prev_high;
//---- расчеты необходимого количества копируемых данных и
//---- стартового номера limit для цикла пересчета баров
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=rates_total-min_rates_total-1; // стартовый номер для расчета всех баров
      LastCountBar=rates_total;
      prev_low=999999999;
      prev_high=0.0;
     }
   else limit=int(LastCountBar)+rates_total-prev_calculated; // стартовый номер для расчета новых баров 
//---- индексация элементов в массивах как в таймсериях  
   ArraySetAsSeries(time,true);
   ArraySetAsSeries(high,true);
   ArraySetAsSeries(low,true);
   ArraySetAsSeries(close,true);
//---- основной цикл расчета индикатора
   for(bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      Ind1Buffer[bar]=0.0;
      Ind2Buffer[bar]=0.0;
      Ind3Buffer[bar]=0.0;
      Ind4Buffer[bar]=0.0;
      Ind5Buffer[bar]=0.0;
      Ind6Buffer[bar]=0.0;
      Ind7Buffer[bar]=0.0;
      //---- копируем вновь появившиеся данные в массив
      if(CopyTime(Symbol(),TimeFrame,time[bar],1,iTime)<=0) return(RESET);
      //----
      if(time[bar]>=iTime[0] && time[bar+1]<iTime[0])
        {
         LastCountBar=bar;
         Ind1Buffer[bar+1]=0.0;
         Ind2Buffer[bar+1]=0.0;
         Ind3Buffer[bar+1]=0.0;
         Ind4Buffer[bar+1]=0.0;
         Ind5Buffer[bar+1]=0.0;
         Ind6Buffer[bar+1]=0.0;
         Ind7Buffer[bar+1]=0.0;
         //----
         last_close=close[bar+1];
         last_high=prev_high;
         last_low=prev_low;
         P=(last_high+last_low )/2;
         R=last_high;
         S=last_low;
         prev_high=high[bar];
         prev_low=low[bar];
        }
      //----
      prev_high=MathMax(prev_high,high[bar]);
      prev_low=MathMin(prev_low,low[bar]);
      //---- загрузка полученных значений в индикаторные буферы
      Ind4Buffer[bar]=Ind1Buffer[bar]=R;
      Ind6Buffer[bar]=Ind5Buffer[bar]=Ind2Buffer[bar]=P;
      Ind7Buffer[bar]=Ind3Buffer[bar]=S;
     }
//----
   if(ShowComment)
     {
      Comment("Current H=",DoubleToString(R,_Digits),
              ", L=",DoubleToString(S,_Digits),
              ", HL/2=",DoubleToString(P,_Digits),
              ", H-L=",DoubleToString((R-S)/_Point,0));
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| Инициализация индикаторного буфера                               |
//+------------------------------------------------------------------+    
void BufInit(int Number,double &Buffer[])
  {
//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(Number,Buffer,INDICATOR_DATA);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(Buffer,true);
//----
  }
//+------------------------------------------------------------------+
//| Инициализация индикаторного буфера                               |
//+------------------------------------------------------------------+    
void IndInit(int Number,double Empty_Value,int Draw_Begin,int nShift)
  {
//---- осуществление сдвига начала отсчета отрисовки индикатора
   PlotIndexSetInteger(Number,PLOT_DRAW_BEGIN,Draw_Begin);
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(Number,PLOT_EMPTY_VALUE,Empty_Value);
//---- осуществление сдвига индикатора 2 по горизонтали на Shift
   PlotIndexSetInteger(Number,PLOT_SHIFT,nShift);
//----
  }
//+------------------------------------------------------------------+
//| TimeFramesCheck()                                                |
//+------------------------------------------------------------------+    
bool TimeFramesCheck(string IndName,
                     ENUM_TIMEFRAMES inTFrame, //Период графика расчета индикатора
                     ENUM_TIMEFRAMES outTFrame)//Период графика индикатора
  {
//---- проверка периодов графиков на корректность
   if(inTFrame<=outTFrame)
     {
      Print("Период графика для индикатора "+IndName+" не может быть меньше ",GetStringTimeframe(inTFrame));
      return(RESET);
     }
//----
   return(true);
  }
//+------------------------------------------------------------------+
//|  Получение таймфрейма в виде строки                              |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES timeframe)
  {
//----
   return(StringSubstr(EnumToString(timeframe),7,-1));
//----
  }
//+------------------------------------------------------------------+
