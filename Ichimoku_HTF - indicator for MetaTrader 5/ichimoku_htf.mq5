//+------------------------------------------------------------------+ 
//|                                                 Ichimoku_HTF.mq5 | 
//|                               Copyright © 2016, Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2016, Nikolay Kositsin"
#property link "farria@mail.redcom.ru"
//--- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window
//---- количество индикаторных буферов 8
#property indicator_buffers 8
//---- использовано всего пять графических построений
#property indicator_plots   5
//+----------------------------------------------+
//| объявление констант                          |
//+----------------------------------------------+
#define RESET 0                                 // Константа для возврата терминалу команды на пересчет индикатора
#define INDICATOR_NAME "Ichimoku"               // Константа для имени индикатора
#define SIZE 8                                  // Константа для количества вызовов функции CountLine
//+----------------------------------------------+
//| Параметры отрисовки индикатора Tenkan-sen    |
//+----------------------------------------------+
//---- отрисовка индикатора 1 в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета основной линии индикатора использован цвет Red
#property indicator_color1  clrRed
//---- линия индикатора 1 - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора 1 равна 1
#property indicator_width1  1
//---- отображение метки линии индикатора
#property indicator_label1  "Tenkan-sen"
//+----------------------------------------------+
//| Параметры отрисовки индикатора Kijun-sen     |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде линии
#property indicator_type2   DRAW_LINE
//---- в качестве цвета сигнальной линии индикатора использован цвет Blue
#property indicator_color2  clrBlue
//---- линия индикатора 2 - непрерывная кривая
#property indicator_style2  STYLE_SOLID
//---- толщина линии индикатора 2 равна 1
#property indicator_width2  1
//---- отображение метки линии индикатора
#property indicator_label2  "Kijun-sen"
//+----------------------------------------------+
//|  Параметры отрисовки облака Senkou           |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветного облака
#property indicator_type3   DRAW_FILLING
//---- в качестве цвета облака использован
#property indicator_color3  clrPaleTurquoise,clrLavenderBlush
//---- отображение метки индикатора
#property indicator_label3  "Senkou Span A;Senkou Span B"
//+----------------------------------------------+
//|  Параметры отрисовки мувинга  Chinkou Span   |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type4   DRAW_LINE
//---- в качестве цвета линии индикатора использован салатовый цвет
#property indicator_color4 clrLime
//---- линия индикатора - сплошная
#property indicator_style4  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width4  2
//---- отображение метки индикатора
#property indicator_label4  "Chinkou Span"
//+----------------------------------------------+
//|  Параметры отрисовки мувинга  Chinkou Span   |
//+----------------------------------------------+
//---- отрисовка индикатора в виде цветной гистограммы
#property indicator_type5   DRAW_COLOR_HISTOGRAM2
//---- в качестве цвета линии индикатора использованы
#property indicator_color5 clrRed,clrBlue
//---- линия индикатора - штрих-пунктир
#property indicator_style5  STYLE_DASHDOTDOT
//---- толщина линии индикатора равна 1
#property indicator_width5  1
//---- отображение метки индикатора
#property indicator_label5  "Tenkan-sen; Kijun-sen"
//+----------------------------------------------+
//| Входные параметры индикатора                 |
//+----------------------------------------------+ 
input ENUM_TIMEFRAMES TimeFrame=PERIOD_H4;// Период графика
input int InpTenkan=9;     // Tenkan-sen
input int InpKijun=26;     // Kijun-sen
input int InpSenkou=52;    // Senkou Span B
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double ExtLineBuffer1[],ExtLineBuffer2[],ExtLineBuffer3[],ExtLineBuffer4[];
double ExtLineBuffer5[],ExtLineBuffer6[],ExtLineBuffer7[],ExtLineBuffer8[];
//--- объявление строковых переменных
string Symbol_,Word;
//--- объявление целочисленных переменных начала отсчета данных
int min_rates_total,Shift;
//--- объявление целочисленных переменных для хендлов индикаторов
int Ind_Handle;
//+------------------------------------------------------------------+
//| Получение таймфрейма в виде строки                               |
//+------------------------------------------------------------------+
string GetStringTimeframe(ENUM_TIMEFRAMES Timeframe)
  {return(StringSubstr(EnumToString(Timeframe),7,-1));}
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//--- проверка периодов графиков на корректность
   if(InpTenkan>0)
      if(TimeFrame<Period() && TimeFrame!=PERIOD_CURRENT)
        {
         Print("Период графика для индикатора Ichimoku не может быть меньше периода текущего графика");
         return(INIT_FAILED);
        }
//--- инициализация переменных 
   min_rates_total=2;
   if(InpTenkan>0) Shift=(InpKijun-2)*PeriodSeconds(TimeFrame)/PeriodSeconds(PERIOD_CURRENT);
   Symbol_=Symbol();
   Word=INDICATOR_NAME+" индикатор: "+Symbol_+StringSubstr(EnumToString(_Period),7,-1);
//--- получение хендла индикатора Ichimoku
   if(InpTenkan>0)
     {
      Ind_Handle=iCustom(Symbol_,TimeFrame,MQLInfoString(MQL_PROGRAM_NAME),PERIOD_CURRENT,-InpTenkan,InpKijun,InpSenkou);
      if(Ind_Handle==INVALID_HANDLE)
        {
         Print(" Не удалось получить хендл индикатора "+MQLInfoString(MQL_PROGRAM_NAME));
         return(INIT_FAILED);
        }
     }
//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(0,ExtLineBuffer1,INDICATOR_DATA);
   SetIndexBuffer(1,ExtLineBuffer2,INDICATOR_DATA);
   SetIndexBuffer(2,ExtLineBuffer3,INDICATOR_DATA);
   SetIndexBuffer(3,ExtLineBuffer4,INDICATOR_DATA);
   SetIndexBuffer(4,ExtLineBuffer5,INDICATOR_DATA);
   SetIndexBuffer(5,ExtLineBuffer6,INDICATOR_DATA);
   SetIndexBuffer(6,ExtLineBuffer7,INDICATOR_DATA);
   SetIndexBuffer(7,ExtLineBuffer8,INDICATOR_COLOR_INDEX);
//---- установка позиции, с которой начинается отрисовка уровней
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- индексация элементов в буфере как в таймсерии
   ArraySetAsSeries(ExtLineBuffer1,true);
   ArraySetAsSeries(ExtLineBuffer2,true);
   ArraySetAsSeries(ExtLineBuffer3,true);
   ArraySetAsSeries(ExtLineBuffer4,true);
   ArraySetAsSeries(ExtLineBuffer5,true);
   ArraySetAsSeries(ExtLineBuffer6,true);
   ArraySetAsSeries(ExtLineBuffer7,true);
   ArraySetAsSeries(ExtLineBuffer8,true);
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME"(",GetStringTimeframe(TimeFrame),")");
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+  
//| Custom iteration function                                        | 
//+------------------------------------------------------------------+  
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
  {
//--- проверка количества баров на достаточность для расчета
   if(rates_total<min_rates_total) return(RESET);
   if(InpTenkan>0)
     {
      //--- индексация элементов в массивах как в таймсериях  
      ArraySetAsSeries(Time,true);
      //---- осуществление сдвига индикатора по горизонтали
      datetime time1[1],timex[];
      if(CopyTime(Symbol(),TimeFrame,1,1,time1)<=0) return(RESET);
      if(CopyTime(Symbol(),NULL,Time[0],time1[0],timex)<=0) return(RESET);
      int shiftx=Shift+ArraySize(timex);
      PlotIndexSetInteger(2,PLOT_SHIFT,shiftx);
      PlotIndexSetInteger(3,PLOT_SHIFT,-shiftx);
      //--- основной цикл расчета индикатора
      if(!CountIndicator(0,NULL,TimeFrame,Ind_Handle,0,ExtLineBuffer1,Time,rates_total,prev_calculated,min_rates_total)) return(RESET);
      if(!CountIndicator(1,NULL,TimeFrame,Ind_Handle,1,ExtLineBuffer2,Time,rates_total,prev_calculated,min_rates_total)) return(RESET);
      if(!CountIndicator(2,NULL,TimeFrame,Ind_Handle,2,ExtLineBuffer3,Time,rates_total,prev_calculated,min_rates_total)) return(RESET);
      if(!CountIndicator(3,NULL,TimeFrame,Ind_Handle,3,ExtLineBuffer4,Time,rates_total,prev_calculated,min_rates_total)) return(RESET);
      if(!CountIndicator(4,NULL,TimeFrame,Ind_Handle,4,ExtLineBuffer5,Time,rates_total,prev_calculated,min_rates_total)) return(RESET);
      if(!CountIndicator(5,NULL,TimeFrame,Ind_Handle,5,ExtLineBuffer6,Time,rates_total,prev_calculated,min_rates_total)) return(RESET);
      if(!CountIndicator(6,NULL,TimeFrame,Ind_Handle,6,ExtLineBuffer7,Time,rates_total,prev_calculated,min_rates_total)) return(RESET);
      if(!CountIndicator(7,NULL,TimeFrame,Ind_Handle,7,ExtLineBuffer8,Time,rates_total,prev_calculated,min_rates_total)) return(RESET);
     }
   else
     {
      int limit;
      //---- индексация элементов в массивах как в таймсериях  
      ArraySetAsSeries(High,true);
      ArraySetAsSeries(Low,true);
      ArraySetAsSeries(Close,true);
      //---
      if(prev_calculated==0) limit=0;
      else                   limit=prev_calculated-1;
      //---
      for(int i=limit;i<rates_total && !IsStopped();i++)
        {
         ExtLineBuffer5[i]=Close[i];
         //--- tenkan sen
         double high=High[ArrayMaximum(High,i,MathAbs(InpTenkan))];
         double low=Low[ArrayMinimum(Low,i,MathAbs(InpTenkan))];
         ExtLineBuffer1[i]=ExtLineBuffer6[i]=(high+low)/2.0;
         //--- kijun sen
         high=High[ArrayMaximum(High,i,InpKijun)];
         low=Low[ArrayMinimum(Low,i,InpKijun)];
         ExtLineBuffer2[i]=ExtLineBuffer7[i]=(high+low)/2.0;
         //--- senkou span a
         ExtLineBuffer3[i]=(ExtLineBuffer1[i]+ExtLineBuffer2[i])/2.0;
         //--- senkou span b
         high=High[ArrayMaximum(High,i,InpSenkou)];
         low=Low[ArrayMinimum(Low,i,InpSenkou)];
         ExtLineBuffer4[i]=(high+low)/2.0;
         if(ExtLineBuffer2[i]<ExtLineBuffer1[i]) ExtLineBuffer8[i]=1;
         else ExtLineBuffer8[i]=0;
        }
     }
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| CountLine                                                        |
//+------------------------------------------------------------------+
bool CountIndicator(uint     Numb,            // Номер функции CountLine по списку в коде индикатора (стартовый номер - 0)
                    string   Symb,            // Символ графика
                    ENUM_TIMEFRAMES TFrame,   // Период графика
                    int      IndHandle,       // Хендл обрабатываемого индикатора
                    uint     BuffNumb,        // Номер буфера обрабатываемого индикатора
                    double&  IndBuf[],        // Приемный буфер индикатора
                    const datetime& iTime[],  // Таймсерия времени
                    const int Rates_Total,    // количество истории в барах на текущем тике
                    const int Prev_Calculated,// количество истории в барах на предыдущем тике
                    const int Min_Rates_Total)// минимальное количество истории в барах для расчета
  {
//---
   static int LastCountBar[SIZE];
   datetime IndTime[1];
   int limit;
//--- расчеты необходимого количества копируемых данных
//--- и стартового номера limit для цикла пересчета баров
   if(Prev_Calculated>Rates_Total || Prev_Calculated<=0)// проверка на первый старт расчета индикатора
     {
      limit=Rates_Total-Min_Rates_Total-1; // стартовый номер для расчета всех баров
      LastCountBar[Numb]=limit;
     }
   else limit=LastCountBar[Numb]+Rates_Total-Prev_Calculated; // стартовый номер для расчета новых баров 
//--- основной цикл расчета индикатора
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      //--- обнулим содержимое индикаторных буферов до расчета
      IndBuf[bar]=0.0;
      //--- копируем вновь появившиеся данные в массив IndTime
      if(CopyTime(Symbol_,TimeFrame,iTime[bar],1,IndTime)<=0) return(RESET);
      //---
      if(iTime[bar]>=IndTime[0] && iTime[bar+1]<IndTime[0])
        {
         LastCountBar[Numb]=bar;
         double Arr[1];
         //--- копируем вновь появившиеся данные в массив Arr
         if(CopyBuffer(IndHandle,BuffNumb,iTime[bar],1,Arr)<=0) return(RESET);
         IndBuf[bar]=Arr[0];
        }
      else IndBuf[bar]=IndBuf[bar+1];
     }
//---     
   return(true);
  }
//+------------------------------------------------------------------+
