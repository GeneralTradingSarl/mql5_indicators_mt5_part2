//+------------------------------------------------------------------+ 
//|                           Elliott_Wave_Oscillator_HTF_Signal.mq5 | 
//|                                Copyright © 2016 Nikolay Kositsin | 
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2016, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//---- номер версии индикатора
#property version   "1.60"
//+------------------------------------------------+ 
//|  Параметры отрисовки индикатора                |
//+------------------------------------------------+ 
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
#property indicator_buffers 1
#property indicator_plots   1
//+------------------------------------------------+ 
//|  Объявление констант                           |
//+------------------------------------------------+
#define INDICATOR_NAME      "Elliott_Wave_Oscillator" // Имя индикатора
#define RESET               0                   // Константа для возврата терминалу команды на пересчет индикатора
#define NAMES_SYMBOLS_FONT  "Georgia"           // Шрифт для названия индикатора
#define SIGNAL_SYMBOLS_FONT "Wingdings 3"       // Шрифт для символа входа в позицию
#define TREND_SYMBOLS_FONT  "Wingdings 3"       // Шрифт для символа тренда
#define UP_SIGNAL_SYMBOL    "ж"                 // Символ для открывания long
#define DN_SIGNAL_SYMBOL    "и"                 // Символ для открывания short
#define UP_TREND_SYMBOL     "в"                 // Символ для растущего тренда
#define DN_TREND_SYMBOL     "в"                 // Символ для падающего тренда
#define BUY_SOUND           "alert.wav"         // Звуковой файл для входа в long
#define SELL_SOUND          "alert.wav"         // Звуковой файл для входа в short
#define BUY_ALERT_TEXT      "Buy signal"        // Текст алерта для входа в long
#define SELL_ALERT_TEXT     "Sell signal"       // Текст алерта для входа в short
//+----------------------------------------------+
//|  Описание класса CXMA                        |
//+----------------------------------------------+
#include <SmoothAlgorithms.mqh> 
//+----------------------------------------------+
//|  объявление перечислений                     |
//+----------------------------------------------+
enum Applied_price_ //Тип константы
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
//|  объявление перечислений                     |
//+----------------------------------------------+
enum ENUM_MODE //Тип константы
  {
   MODE1 = 1,     //Изменение направления движения
   MODE2          //Пробой нулевой линии
  };
//+----------------------------------------------+
//|  объявление перечислений                     |
//+----------------------------------------------+
/*enum Smooth_Method - перечисление объявлено в файле SmoothAlgorithms.mqh
  {
   MODE_SMA_,  //SMA
   MODE_EMA_,  //EMA
   MODE_SMMA_, //SMMA
   MODE_LWMA_, //LWMA
   MODE_JJMA,  //JJMA
   MODE_JurX,  //JurX
   MODE_ParMA, //ParMA
   MODE_T3,    //T3
   MODE_VIDYA, //VIDYA
   MODE_AMA,   //AMA
  }; */
//+------------------------------------------------+ 
//| Перечисление для индикации срабатывания уровня |
//+------------------------------------------------+ 
enum ENUM_ALERT_MODE // тип константы
  {
   OnlySound,   // только звук
   OnlyAlert    // только алерт
  };
//+------------------------------------------------+ 
//|  Входные параметры индикатора                  |
//+------------------------------------------------+ 
input string Symbol_="";                               // Финансовый актив
input ENUM_TIMEFRAMES Timeframe=PERIOD_H6;             // Таймфрейм индикатора для расчета индикатора
input ENUM_MODE Mode=MODE1;                            // Алгоритм определения сигнала
input Smooth_Method MA_Method1=MODE_SMA_;              // Метод усреднения первого мувинга
input int Length1=5;                                   // Глубина усреднения первого мувинга                   
input int Phase1=15;                                   // Параметр первого мувинга,
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- Для VIDIA это период CMO, для AMA это период медленной скользящей
input Applied_price_ IPC1=PRICE_MEDIAN_;               // Ценовая константа первого мувинга
input Smooth_Method MA_Method2=MODE_JJMA;              // Метод усреднения второго мувинга
input int Length2=35;                                  // Глубина усреднения второго мувинга
input int Phase2=15;                                   // Параметр второго мувинга,
//---- для JJMA изменяющийся в пределах -100 ... +100, влияет на качество переходного процесса;
//---- Для VIDIA это период CMO, для AMA это период медленной скользящей
input Applied_price_ IPC2=PRICE_MEDIAN_;               // Ценовая константа второго мувинга
//---- настройки визуального отображения индикатора
input uint SignalBar=0;                                // Номер бара для получения сигнала (0 - текущий бар)
input string Symbols_Sirname=INDICATOR_NAME"_Label_";  // Название для меток индикатора
input color Upsymbol_Color=clrPaleGreen;               // Цвет символа роста
input color Dnsymbol_Color=clrDeepPink;                // Цвет символа падения
input color IndName_Color=clrDarkOrchid;               // Цвет названия индикатора
input uint Symbols_Size=60;                            // Размер символов сигнала
input uint Font_Size=10;                               // Размер шрифта названия индикатора
input int X_1=5;                                       // Смещение названия по горизонтали
input int Y_1=-15;                                     // Смещение названия по вертикали
input bool ShowIndName=true;                           // Отображение названия индикатора
input ENUM_BASE_CORNER  WhatCorner=CORNER_RIGHT_UPPER; // Угол расположения
input uint X_=0;                                       // Смещение по горизонтали
input uint Y_=20;                                      // Смещение по вертикали
//---- настройки алертов
input ENUM_ALERT_MODE alert_mode=OnlySound;            // Вариант индикации срабатывания
input uint AlertCount=0;                               // Количество подаваемых алертов
//+-----------------------------------+
//---- объявление целочисленных переменных для хендлов индикаторов
int NRTR_Handle;
//---- объявление целочисленных переменных начала отсчета данных
int min_rates_total;
//---- объявление целочисленных переменных расположения индексов по горизонтали и вертикали
uint X_0,Yn,X_1_,Y_1_;
//---- объявление переменных для имен меток
string name0,name1,IndName,Symb;
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
//|  Создание текстовой метки                                        |
//+------------------------------------------------------------------+
void CreateTLabel(long   chart_id,         // идентификатор графика
                  string name,             // имя объекта
                  int    nwin,             // индекс окна
                  ENUM_BASE_CORNER corner, // положение угла привязки
                  ENUM_ANCHOR_POINT point, // положение точки привязки
                  int    X,                // дистанция в пикселях по оси X от угла привязки
                  int    Y,                // дистанция в пикселях по оси Y от угла привязки
                  string text,             // текст
                  string textTT,           // текст всплывающей подсказки
                  color  Color,            // цвет текста
                  string Font,             // шрифт текста
                  int    Size)             // размер шрифта
  {
//----
   ObjectCreate(chart_id,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(chart_id,name,OBJPROP_CORNER,corner);
   ObjectSetInteger(chart_id,name,OBJPROP_ANCHOR,point);
   ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,X);
   ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,Y);
   ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
   ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
   ObjectSetString(chart_id,name,OBJPROP_FONT,Font);
   ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,Size);
   ObjectSetString(chart_id,name,OBJPROP_TOOLTIP,textTT);
   ObjectSetInteger(chart_id,name,OBJPROP_BACK,true); //объект на заднем плане
//----
  }
//+------------------------------------------------------------------+
//|  Переустановка текстовой метки                                   |
//+------------------------------------------------------------------+
void SetTLabel(long   chart_id,         // идентификатор графика
               string name,             // имя объекта
               int    nwin,             // индекс окна
               ENUM_BASE_CORNER corner, // положение угла привязки
               ENUM_ANCHOR_POINT point, // положение точки привязки
               int    X,                // дистанция в пикселях по оси X от угла привязки
               int    Y,                // дистанция в пикселях по оси Y от угла привязки
               string text,             // текст
               string textTT,           // текст всплывающей подсказки
               color  Color,            // цвет текста
               string Font,             // шрифт текста
               int    Size)             // размер шрифта
  {
//----
   if(ObjectFind(chart_id,name)==-1)
     {
      CreateTLabel(chart_id,name,nwin,corner,point,X,Y,text,textTT,Color,Font,Size);
     }
   else
     {
      ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,X);
      ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,Y);
      ObjectSetInteger(chart_id,name,OBJPROP_COLOR,Color);
      ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,Size);
     }
//----
  }
//+------------------------------------------------------------------+    
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+  
int OnInit()
  {
//---- инициализация переменных начала отсчета данных
   min_rates_total=MathMax(GetStartBars(MA_Method1,Length1,Phase1),GetStartBars(MA_Method2,Length2,Phase2))+3;
   int ATR_Period=15;
   min_rates_total=int(MathMax(min_rates_total,ATR_Period))+1;

//---- инициализация переменных
   if(Symbol_!="") Symb=Symbol_;
   else Symb=Symbol();

   X_0=X_;
   Yn=Y_+5;

   name0=Symbols_Sirname+"0";
   if(ShowIndName)
     {
      Y_1_=Yn+Y_1;
      X_1_=X_0+X_1;
      name1=Symbols_Sirname+"1";
      StringConcatenate(IndName,INDICATOR_NAME,"(",Symb," ",GetStringTimeframe(Timeframe),")");
     }

//---- получение хендла индикатора Elliott_Wave_Oscillator_Sign
   NRTR_Handle=iCustom(Symb,Timeframe,"Elliott_Wave_Oscillator_Sign",Mode,MA_Method1,Length1,Phase1,IPC1,MA_Method2,Length2,Phase2,IPC2,0,false);
   if(NRTR_Handle==INVALID_HANDLE)
     {
      Print(" Не удалось получить хендл индикатора Elliott_Wave_Oscillator");
      return(INIT_FAILED);
     }

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,INDICATOR_NAME,"( ",GetStringTimeframe(Timeframe)," )");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//--- завершение инициализации
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void Deinit()
  {
//----
   if(ObjectFind(0,name0)!=-1) ObjectDelete(0,name0);
   if(ObjectFind(0,name1)!=-1) ObjectDelete(0,name1);
//----
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+    
void OnDeinit(const int reason)
  {
//----
   Deinit();
//----
   ChartRedraw(0);
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
   if(BarsCalculated(NRTR_Handle)<min_rates_total) return(RESET);
   if(BarsCalculated(NRTR_Handle)<Bars(Symb,Timeframe)) return(prev_calculated);

//---- объявление локальных переменных
   int limit,trend;
   double UpSign[],DnSign[];
   datetime rates_time,TIME[1];
   color Color0=clrNONE;
   string SignSymbol;
   static datetime prev_time;
   static int trend_;
   bool signal=false;
   static uint buycount=0,sellcount=0;

//---- копируем вновь появившиеся данные в массивы
   if(CopyTime(Symb,Timeframe,SignalBar,1,TIME)<=0) return(RESET);

//---- расчеты необходимого количества копируемых данных для функции CopyBuffer
   if(prev_calculated>rates_total || prev_calculated<=0)// проверка на первый старт расчета индикатора
     {
      prev_time=time[0];
      trend_=0;
     }

   rates_time=TimeCurrent();
//---- копируем вновь появившиеся данные в массивы
   if(CopyBuffer(NRTR_Handle,1,rates_time,prev_time,DnSign)<=0) return(RESET);
   if(CopyBuffer(NRTR_Handle,0,rates_time,prev_time,UpSign)<=0) return(RESET);

//---- расчеты стартового номера limit для цикла пересчета баров  
   limit=ArraySize(UpSign)-1;
   trend=trend_;

//---- индексация элементов в массивах, как в таймсериях  
   ArraySetAsSeries(DnSign,true);
   ArraySetAsSeries(UpSign,true);

//---- ставим счетчики алертов в исходное положение   
   if(TIME[0]!=prev_time && AlertCount)
     {
      buycount=AlertCount;
      sellcount=AlertCount;
     }

//---- основной цикл расчета индикатора
   for(int bar=limit; bar>=0 && !IsStopped(); bar--)
     {
      if(UpSign[bar]&&UpSign[bar]!=EMPTY_VALUE) {trend=+1; if(!bar) signal=true;}
      if(DnSign[bar]&&DnSign[bar]!=EMPTY_VALUE) {trend=-1; if(!bar) signal=true;}
      if(bar ||  SignalBar) trend_=trend;
     }

   if(trend>0)
     {
      Color0=Upsymbol_Color;

      if(signal)
        {
         SignSymbol=UP_SIGNAL_SYMBOL;
         if(buycount)
           {
            switch(alert_mode)
              {
               case OnlyAlert: Alert(IndName+": "+BUY_ALERT_TEXT); break;
               case OnlySound: PlaySound(BUY_SOUND); break;
              }

            buycount--;
           }
        }
      else SignSymbol=UP_TREND_SYMBOL;
     }

   if(trend<0)
     {
      Color0=Dnsymbol_Color;

      if(signal)
        {
         SignSymbol=DN_SIGNAL_SYMBOL;
         if(sellcount)
           {
            switch(alert_mode)
              {
               case OnlyAlert: Alert(IndName+": "+SELL_ALERT_TEXT); break;
               case OnlySound: PlaySound(SELL_SOUND); break;
              }

            sellcount--;
           }

        }
      else SignSymbol=DN_TREND_SYMBOL;
     }

   if(trend)
     {
      if(ShowIndName)
         SetTLabel(0,name1,0,WhatCorner,ENUM_ANCHOR_POINT(2*WhatCorner),X_1_,Y_1_,IndName,IndName,IndName_Color,NAMES_SYMBOLS_FONT,Font_Size);
      if(signal) SetTLabel(0,name0,0,WhatCorner,ENUM_ANCHOR_POINT(2*WhatCorner),X_0,Yn,SignSymbol,IndName,Color0,SIGNAL_SYMBOLS_FONT,Symbols_Size);
      else SetTLabel(0,name0,0,WhatCorner,ENUM_ANCHOR_POINT(2*WhatCorner),X_0,Yn,SignSymbol,IndName,Color0,TREND_SYMBOLS_FONT,Symbols_Size);
     }
   else Deinit();

//----
   ChartRedraw(0);
   prev_time=TIME[0];
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
