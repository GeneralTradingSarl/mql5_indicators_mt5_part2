//+------------------------------------------------------------------+
//|                                                    DealsLent.mq5 |
//|                                     Copyright 2016, prostotrader |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, prostotrader"
#property link      "https://www.mql5.com"
#property version   "1.02"
#define on_call -111  //Отрицательное число для вызова функции OnCalculate
// (данные не могут быть в отрицательном диаппозоне)
input int  ActSize=30;      //Размер актуальной истории в буферах индикатора
//---
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   2
//--- plot Label1
#property indicator_label1  "Sell"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrLightPink
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Label1
#property indicator_label2  "Buy"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrLightSkyBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- indicator buffers
double SellBuffer[];
double BuyBuffer[];
double SellVol[];
double BuyVol[];
//---Variables
long sell_deals;
long buy_deals;
long mem_deals;   //Предыдущее общ. кол-во сделок с последнем временем
long last_deals;  //Общ. кол-ва сделок с последним временем
ulong sell_vol;
ulong buy_vol;
ulong start_time; //Время получения пакета тиков
ulong mem_time;
int event_cnt;    //Переменная для вызова функции OnCalculate
bool use_book;    //Флаг, что индикатор добавил стакан
MqlTick ticks[];
//
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   mem_time=0;
   start_time=0;
   event_cnt =0;
   MqlBookInfo book[];
   if(!MarketBookGet(Symbol(),book)) //Автоматическое добавление стакана цен, если на графике стакан не добавлен
     {
      if(!MarketBookAdd(Symbol()))
        {
         Print(__FUNCTION__,": Стакан символа "+Symbol()+" не добавден!");
         return( INIT_FAILED );
        }
      else
        {
         use_book=true;
        }
     }
   else
     {
      use_book=false;
     }
//--- Bars
   int cur_bars=Bars(Symbol(),PERIOD_CURRENT); //Проверка кол-ва баров на графике
   if(cur_bars<(ActSize+1))
     {
      Print(__FUNCTION__,": Не достаточно баров на текущем таймфрейме! должно быть не менее ",ActSize+1);
      return( INIT_FAILED );
     }
   if(cur_bars<2)
     {
      Print(__FUNCTION__,": Не достаточно баров на текущем таймфрейме! Должно быть не менее 2.");
      return( INIT_FAILED );
     }
//--- Set buffers 
   IndicatorSetInteger(INDICATOR_DIGITS,0);
   IndicatorSetString(INDICATOR_SHORTNAME,"DealsLent");
//---Set buffers
   SetIndexBuffer(0,SellBuffer,INDICATOR_DATA);
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   ArraySetAsSeries(SellBuffer,true);

   SetIndexBuffer(1,BuyBuffer,INDICATOR_DATA);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   ArraySetAsSeries(BuyBuffer,true);

   SetIndexBuffer(2,SellVol,INDICATOR_CALCULATIONS);
   ArraySetAsSeries(SellVol,true);

   SetIndexBuffer(3,BuyVol,INDICATOR_CALCULATIONS);
   ArraySetAsSeries(BuyVol,true);
//---Set objects
   int window=ChartWindowFind(ChartID(),"DealsLent");
   ObjectCreate(ChartID(),"Label_1",OBJ_LABEL,window,0,0);
   ObjectCreate(ChartID(),"Label_2",OBJ_LABEL,window,0,0);
   ObjectCreate(ChartID(),"Label_3",OBJ_LABEL,window,0,0);
   ObjectCreate(ChartID(),"Label_4",OBJ_LABEL,window,0,0);

   ObjectSetInteger(ChartID(),"Label_1",OBJPROP_YDISTANCE,30);
   ObjectSetInteger(ChartID(),"Label_1",OBJPROP_XDISTANCE,0);
   ObjectSetInteger(ChartID(),"Label_2",OBJPROP_YDISTANCE,60);
   ObjectSetInteger(ChartID(),"Label_2",OBJPROP_XDISTANCE,0);

   ObjectSetInteger(ChartID(),"Label_3",OBJPROP_YDISTANCE,15);
   ObjectSetInteger(ChartID(),"Label_3",OBJPROP_XDISTANCE,0);
   ObjectSetInteger(ChartID(),"Label_4",OBJPROP_YDISTANCE,45);
   ObjectSetInteger(ChartID(),"Label_4",OBJPROP_XDISTANCE,0);

   ObjectSetInteger(ChartID(),"Label_1",OBJPROP_COLOR,clrLightPink);
   ObjectSetInteger(ChartID(),"Label_2",OBJPROP_COLOR,clrLightSkyBlue);
   ObjectSetInteger(ChartID(),"Label_3",OBJPROP_COLOR,clrLightPink);
   ObjectSetInteger(ChartID(),"Label_4",OBJPROP_COLOR,clrLightSkyBlue);

   ObjectSetString(ChartID(),"Label_1",OBJPROP_TEXT,"Сум. объём Sell: 0");
   ObjectSetString(ChartID(),"Label_2",OBJPROP_TEXT,"Сум. объём Buy: 0");

   ObjectSetString(ChartID(),"Label_3",OBJPROP_TEXT,"Сум. кол-во Sell: 0");
   ObjectSetString(ChartID(),"Label_4",OBJPROP_TEXT,"Сум. кол-во Buy: 0");

   PlotIndexSetInteger(0,PLOT_SHOW_DATA,false);
   PlotIndexSetInteger(1,PLOT_SHOW_DATA,false);

   ChartRedraw(ChartID());
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+  
void OnDeinit(const int reason)
  {
   if(use_book) MarketBookRelease(Symbol());
   ObjectDelete(ChartID(),"Label_1");
   ObjectDelete(ChartID(),"Label_2");
   ObjectDelete(ChartID(),"Label_3");
   ObjectDelete(ChartID(),"Label_4");
   if(reason==REASON_INITFAILED)
     {
      int window=ChartWindowFind(ChartID(),"DealsLent");
      ChartIndicatorDelete(ChartID(),window,"DealsLent");
     }
  }
//+------------------------------------------------------------------+
//| Custom indicator On book event function                          |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
   if(symbol==Symbol()) //Проверка, что мы получаем данные по искомому символу
     {
      if(start_time==0) //Получение начального времени для отсчёта пакетов тиков 
        {
         if(CopyTicks(Symbol(),ticks,COPY_TICKS_TRADE,0,1)==1)
           {
            start_time=ulong(ticks[0].time_msc);
           }
        }
      else
        {
         sell_deals= 0;
         buy_deals = 0;
         sell_vol= 0;
         buy_vol = 0;
         last_deals=0;
         int result=CopyTicks(Symbol(),ticks,COPY_TICKS_TRADE,start_time,0);     //Получение пакета тиков, если он есть
         if(result>0)
           {
            for(int i=0; i<result; i++)
              {
               if(( ticks[i].flags  &TICK_FLAG_BUY)==TICK_FLAG_BUY)
                 {
                  buy_deals++;                                                   //Общ. кол-во сделок на покупку
                  buy_vol+=ticks[i].volume;                                      //Общ. объём сделок на покупку
                  if(ticks[i].time_msc==ticks[result-1].time_msc) last_deals++;  //Общ. кол-во сделок с указанномым временем
                 }
               else
               if(( ticks[i].flags  &TICK_FLAG_SELL)==TICK_FLAG_SELL)
                 {
                  sell_deals++;                                                  //Общ. кол-во сделок на продажу 
                  sell_vol+=ticks[i].volume;                                     //Общ. объём сделок на продажу
                  if(ticks[i].time_msc==ticks[result-1].time_msc) last_deals++;
                 }
              }
            start_time=ulong(ticks[result-1].time_msc+1);                        //Добавление с текущему времени 1, чтобы получить следующий пакет тиков
            if(( sell_deals==0) && (buy_deals==0)) return;
            double price[];
            OnCalculate(event_cnt,event_cnt,on_call,price);                      //Вызов функции для обработки данных 
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
   if(prev_calculated==0)
     {
      ArrayInitialize(SellBuffer,EMPTY_VALUE);
      ArrayInitialize(BuyBuffer,EMPTY_VALUE);
      ArrayInitialize(SellVol,EMPTY_VALUE);
      ArrayInitialize(BuyVol,EMPTY_VALUE);
     }
   else
     {
      if(begin==on_call) //Уникальный идентификатор (отрицательное число)
        {
         int a_size=ArraySize(ticks);                                            //Размер массива тиков
         //---!!! Мы смотрим НЕ историю тиков, а получаем их в таком виде, каком они приходят в терминал (пакетами).
         //--- Но в каждом последующем пакете могут быть тики с предыдущим временем, и чтобы их не потерять,
         //--- мы анализируем каждый последующий пакет тиков         
         if((mem_time!=ticks[0].time_msc) && (mem_time!=0)) //Убеждаемся, что пришел следующий пакет тиков
           {
            MqlTick t_ticks[];
            long new_deals=0;
            long add_sell=0;
            long add_buy=0;
            ulong add_s_vol=0;
            ulong add_b_vol=0;
            int result=CopyTicks(Symbol(),t_ticks,COPY_TICKS_TRADE,mem_time,0); //Смотрим общее кол-во тиков с предыдущим временем (уже в истории)
            if(result>0)
              {
               for(int i=0; i<result;i++)
                 {
                  if(t_ticks[i].time_msc==mem_time)
                    {
                     if((t_ticks[i].flags  &TICK_FLAG_BUY)==TICK_FLAG_BUY)
                       {
                        new_deals++;
                       }
                     else
                     if((t_ticks[i].flags  &TICK_FLAG_SELL)==TICK_FLAG_SELL)

                       {
                        new_deals++;
                       }

                    }
                 }
               if(new_deals>mem_deals) //Проверяем, что всего тиков больше, чем мы обработали
                 {
                  long res_deals=new_deals-mem_deals;
                  result=CopyTicks(Symbol(),t_ticks,COPY_TICKS_TRADE,mem_time,uint(new_deals));  //Получаем только те тики, которые пришли позже, но с предыдущим временем
                  if(result>0)
                    {
                     for(int i=0; i<result;i++)
                       {
                        if(t_ticks[i].time_msc==mem_time)
                          {
                           if((t_ticks[i].flags  &TICK_FLAG_BUY)==TICK_FLAG_BUY)
                             {
                              if(res_deals>0)
                                {
                                 res_deals--;                               //Уменьшаем счётчик добавленных тиков
                                 add_buy++;                                 //Добавляем сделки на покупку
                                 add_b_vol+=t_ticks[i].volume;              //Добавляем объём сделок на покупку 
                                }
                             }
                           else
                           if((t_ticks[i].flags  &TICK_FLAG_SELL)==TICK_FLAG_SELL)
                             {
                              if(res_deals>0)
                                {
                                 res_deals--;
                                 add_sell++;
                                 add_s_vol+=t_ticks[i].volume;
                                }
                             }

                          }
                       }

                     sell_deals+=add_sell;  //Реальное кол-во сделок на продажу
                     sell_vol+=add_s_vol;   //Реальное кол-во сделок на покупку
                     buy_deals+=add_buy;
                     buy_vol+=add_b_vol;
                    }
                 }
              }
           }
         mem_deals=last_deals;              //запоминаем кол-во сделок с последним временем
         mem_time=ticks[a_size-1].time_msc; //запоминаем последнее время
         //--- Меняем толщину линии графиков в зависимости от объёма         
         switch(int(sell_vol))
           {
            case 0:
            case 1:
               PlotIndexSetInteger(0,PLOT_LINE_WIDTH,1);
               break;
            case 2:
            case 3:
            case 4:
               PlotIndexSetInteger(0,PLOT_LINE_WIDTH,2);
               break;
            case 5:
            case 6:
            case 7:
               PlotIndexSetInteger(0,PLOT_LINE_WIDTH,3);
               break;
            case 8:
            case 9:
            case 10:
               PlotIndexSetInteger(0,PLOT_LINE_WIDTH,4);
               break;
            default:
               PlotIndexSetInteger(0,PLOT_LINE_WIDTH,5);
               break;
           }
         switch(int(buy_vol))
           {
            case 0:
            case 1:
               PlotIndexSetInteger(1,PLOT_LINE_WIDTH,1);
               break;
            case 2:
            case 3:
            case 4:
               PlotIndexSetInteger(1,PLOT_LINE_WIDTH,2);
               break;
            case 5:
            case 6:
            case 7:
               PlotIndexSetInteger(1,PLOT_LINE_WIDTH,3);
               break;
            case 8:
            case 9:
            case 10:
               PlotIndexSetInteger(1,PLOT_LINE_WIDTH,4);
               break;
            default:
               PlotIndexSetInteger(1,PLOT_LINE_WIDTH,5);
               break;
           }
         //--- Выводим данные в инфостроки (Labels)           
         ObjectSetString(ChartID(),"Label_1",OBJPROP_TEXT,"Сум. объём Sell: "+string(sell_vol));
         ObjectSetString(ChartID(),"Label_2",OBJPROP_TEXT,"Сум. объём Buy: "+string(buy_vol));
         ObjectSetString(ChartID(),"Label_3",OBJPROP_TEXT,"Сум. кол-во Sell: "+string(sell_deals));
         ObjectSetString(ChartID(),"Label_4",OBJPROP_TEXT,"Сум. кол-во Buy: "+string(buy_deals));
         ChartRedraw(ChartID());
        }
      if(rates_total==prev_calculated) //кол-во баров не изменилось
        {
         if(begin==on_call) //Мы вызвали OnCalculate
           {
            //--- Сдвигаем буферы           
            if(ActSize==0)
              {
               for(int i=rates_total-1; i>0; i--)
                 {
                  SellBuffer[i]= SellBuffer[i-1];
                  BuyBuffer[i] = BuyBuffer[i-1];
                  SellVol[i]= SellVol[i-1];
                  BuyVol[i] = BuyVol[i-1];
                 }
              }
            else
              {
               for(int i=ActSize-1; i>0; i--)
                 {
                  SellBuffer[i]= SellBuffer[i-1];
                  BuyBuffer[i] = BuyBuffer[i-1];
                  SellVol[i]= SellVol[i-1];
                  BuyVol[i] = BuyVol[i-1];
                 }
              }
            //--- заполняем буферы данными              
            SellBuffer[0]= double(sell_deals);
            BuyBuffer[0] = double(buy_deals);
            SellVol[0]= double(sell_vol);
            BuyVol[0] = double(buy_vol);
           }
        }
      else                                        //кол-во баров изменилось
        {
         int diff=rates_total-prev_calculated;
         if(begin==on_call) //Мы вызвали функцию OnCalculate
           {
            if(diff==1)
              {
               if(ActSize>0)
                 {
                  SellBuffer[ActSize]= EMPTY_VALUE;
                  BuyBuffer[ActSize] = EMPTY_VALUE;
                  SellVol[ActSize]= EMPTY_VALUE;
                  BuyVol[ActSize] = EMPTY_VALUE;
                 }
              }
            else
              {
               if(ActSize>0)
                 {
                  for(int i=1; i<(ActSize+diff);i++)
                    {
                     if(i<ActSize)
                       {
                        SellBuffer[i]= SellBuffer[i+diff-1];
                        BuyBuffer[i] = BuyBuffer[i+diff-1];
                        SellVol[i]= SellVol[i+diff-1];
                        BuyVol[i] = BuyVol[i+diff-1];
                       }
                     else
                       {
                        SellBuffer[i]= EMPTY_VALUE;
                        BuyBuffer[i] = EMPTY_VALUE;
                        SellVol[i]= EMPTY_VALUE;
                        BuyVol[i] = EMPTY_VALUE;
                       }
                    }
                 }
               else
                 {
                  for(int i=1; i<rates_total;i++)
                    {
                     if(i<=prev_calculated)
                       {
                        SellBuffer[i]= SellBuffer[i+diff-1];
                        BuyBuffer[i] = BuyBuffer[i+diff-1];
                        SellVol[i]= SellVol[i+diff-1];
                        BuyVol[i] = BuyVol[i+diff-1];
                       }
                     else
                       {
                        SellBuffer[i]= EMPTY_VALUE;
                        BuyBuffer[i] = EMPTY_VALUE;
                        SellVol[i]= EMPTY_VALUE;
                        BuyVol[i] = EMPTY_VALUE;
                       }
                    }
                 }
              }
            //--- заполняем буферы данными               
            SellBuffer[0]= double(sell_deals);
            BuyBuffer[0] = double(buy_deals);
            SellVol[0]= double(sell_vol);
            BuyVol[0] = double(buy_vol);
           }
         else
           {
            if(ActSize>0)
              {
               for(int i=0; i<ActSize+diff;i++)
                 {
                  if(i<ActSize)
                    {
                     SellBuffer[i]= SellBuffer[i+diff];
                     BuyBuffer[i] = BuyBuffer[i+diff];
                     SellVol[i]= SellVol[i+diff];
                     BuyVol[i] = BuyVol[i+diff];
                    }
                  else
                    {
                     SellBuffer[i]= EMPTY_VALUE;
                     BuyBuffer[i] = EMPTY_VALUE;
                     SellVol[i]= EMPTY_VALUE;
                     BuyVol[i] = EMPTY_VALUE;
                    }
                 }
              }
            else
              {
               for(int i=0; i<rates_total;i++)
                 {
                  if(i<prev_calculated)
                    {
                     SellBuffer[i]= SellBuffer[i+diff];
                     BuyBuffer[i] = BuyBuffer[i+diff];
                     SellVol[i]= SellVol[i+diff];
                     BuyVol[i] = BuyVol[i+diff];
                    }
                  else
                    {
                     SellBuffer[i]= EMPTY_VALUE;
                     BuyBuffer[i] = EMPTY_VALUE;
                     SellVol[i]= EMPTY_VALUE;
                     BuyVol[i] = EMPTY_VALUE;
                    }
                 }
              }
           }
        }
     }
   event_cnt=rates_total;
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
