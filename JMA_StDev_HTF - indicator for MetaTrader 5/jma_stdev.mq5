//+------------------------------------------------------------------+ 
//|                                                    JMA_StDev.mq5 | 
//|                    MQL5 code: Copyright © 2015, Nikolay Kositsin |
//|                              Khabarovsk,   farria@mail.redcom.ru | 
//+------------------------------------------------------------------+ 
#property copyright "Copyright © 2015, Nikolay Kositsin"
#property link "farria@mail.redcom.ru" 
//---- номер версии индикатора
#property version   "1.02"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- для расчёта и отрисовки индикатора использовано шесть буферов
#property indicator_buffers 6
//---- использовано всего пять графических построений
#property indicator_plots   5
//+----------------------------------------------+
//|  Параметры отрисовки линии индикатора        |
//+----------------------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type1   DRAW_COLOR_LINE
//---- в качестве цветов трёхцветной линии использованы
#property indicator_color1  clrMagenta,clrGray,clrBlue
//---- линия индикатора - непрерывная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1  2
//---- отображение метки индикатора
#property indicator_label1  "JMA"
//+----------------------------------------------+
//|  Параметры отрисовки медвежьего индикатора   |
//+----------------------------------------------+
//---- отрисовка индикатора 2 в виде символа
#property indicator_type2   DRAW_ARROW
//---- в качестве цвета медвежьего индикатора использован красный цвет
#property indicator_color2  clrRed
//---- толщина линии индикатора 2 равна 2
#property indicator_width2  2
//---- отображение медвежьей метки индикатора
#property indicator_label2  "Dn_Signal 1"
//+----------------------------------------------+
//|  Параметры отрисовки бычьго индикатора       |
//+----------------------------------------------+
//---- отрисовка индикатора 3 в виде символа
#property indicator_type3   DRAW_ARROW
//---- в качестве цвета бычьего индикатора использован аквамариновый цвет
#property indicator_color3  clrAqua
//---- толщина линии индикатора 3 равна 2
#property indicator_width3  2
//---- отображение бычей метки индикатора
#property indicator_label3  "Up_Signal 1"
//+----------------------------------------------+
//|  Параметры отрисовки медвежьего индикатора   |
//+----------------------------------------------+
//---- отрисовка индикатора 4 в виде символа
#property indicator_type4   DRAW_ARROW
//---- в качестве цвета медвежьего индикатора использован красный цвет
#property indicator_color4  clrRed
//---- толщина линии индикатора 4 равна 4
#property indicator_width4  4
//---- отображение медвежьей метки индикатора
#property indicator_label4  "Dn_Signal 2"
//+----------------------------------------------+
//|  Параметры отрисовки бычьго индикатора       |
//+----------------------------------------------+
//---- отрисовка индикатора 5 в виде символа
#property indicator_type5   DRAW_ARROW
//---- в качестве цвета бычьего индикатора использован аквамариновый цвет
#property indicator_color5  clrAqua
//---- толщина линии индикатора 5 равна 4
#property indicator_width5  4
//---- отображение бычей метки индикатора
#property indicator_label5  "Up_Signal 2"
//+----------------------------------------------+
//|  объявление перечислений                     |
//+----------------------------------------------+
enum ENUM_APPLIED_PRICE_ //Тип константы
  {
   PRICE_CLOSE_ = 1,     //PRICE_CLOSE
   PRICE_OPEN_,          //PRICE_OPEN
   PRICE_HIGH_,          //PRICE_HIGH
   PRICE_LOW_,           //PRICE_LOW
   PRICE_MEDIAN_,        //PRICE_MEDIAN
   PRICE_TYPICAL_,       //PRICE_TYPICAL
   PRICE_WEIGHTED_,      //PRICE_WEIGHTED
   PRICE_SIMPL_,         //PRICE_SIMPL_
   PRICE_QUARTER_,       //PRICE_QUARTER_
   PRICE_TRENDFOLLOW0_,  //PRICE_TRENDFOLLOW0_
   PRICE_TRENDFOLLOW1_,  // TrendFollow_2 Price 
   PRICE_DEMARK_         // Demark Price 
  };
//+----------------------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА                |
//+----------------------------------------------+
input int Length_=7;                              // глубина сглаживания                   
input int Phase_=100;                             // параметр сглаживания,
//---- изменяющийся в пределах -100 ... +100,
//---- влияет на качество переходного процесса;
input ENUM_APPLIED_PRICE_ IPC=PRICE_CLOSE_;       // ценовая константа
input double dK1=1.5;                             // коэффициент 1 для квадратичного фильтра
input double dK2=2.5;                             // коэффициент 2 для квадратичного фильтра
input uint std_period=9;                          // период квадратичного фильтра
input int Shift=0;                                // сдвиг индикатора по горизонтали в барах
input int PriceShift=0;                           // cдвиг индикатора по вертикали в пунктах
//+----------------------------------------------+
//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double ExtLineBuffer[],ColorExtLineBuffer[];
double BearsBuffer1[],BullsBuffer1[];
double BearsBuffer2[],BullsBuffer2[];
//----  Объявление глобальных переменных
double dPriceShift,dJMA[];
int min_rates_total;
//----
bool m_start;
//----
double m_array[62];
//----
double m_degree,m_Phase,m_sense;
double m_Krx,m_Kfd,m_Krj,m_Kct;
double m_var1,m_var2;
//----
int m_pos2,m_pos1;
int m_Loop1,m_Loop2;
int m_midd1,m_midd2;
int m_count1,m_count2,m_count3;
//----
double m_ser1,m_ser2;
double m_Sum1,m_Sum2,m_JMA;
double m_storage1,m_storage2,m_djma;
double m_hoop1[128],m_hoop2[11],m_data[128];
//---- Переменные для восстановления расчётов на незакрытом баре
int m_pos2_,m_pos1_;
int m_Loop1_,m_Loop2_;
int m_midd1_,m_midd2_;
int m_count1_,m_count2_,m_count3_;
//----
double m_ser1_,m_ser2_;
double m_Sum1_,m_Sum2_,m_JMA_;
double m_storage1_,m_storage2_,m_djma_;
double m_hoop1_[128],m_hoop2_[11],m_data_[128];
//----
bool m_bhoop1[128],m_bhoop2[11],m_bdata[128];
//+------------------------------------------------------------------+    
//| JMA indicator initialization function                            | 
//+------------------------------------------------------------------+  
void OnInit()
  {
//---- инициализация глобальных переменных 
   min_rates_total=30+1+int(std_period);
//---- Распределение памяти под массивы переменных  
   ArrayResize(dJMA,std_period);
//---- превращение динамического массива ExtLineBuffer в индикаторный буфер
   SetIndexBuffer(0,ExtLineBuffer,INDICATOR_DATA);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
//---- осуществление сдвига индикатора 2 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);

//---- превращение динамического массива в цветовой, индексный буфер   
   SetIndexBuffer(1,ColorExtLineBuffer,INDICATOR_COLOR_INDEX);

//---- превращение динамического массива BearsBuffer в индикаторный буфер
   SetIndexBuffer(2,BearsBuffer1,INDICATOR_DATA);
//---- осуществление сдвига индикатора 2 по горизонтали
   PlotIndexSetInteger(1,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
//---- выбор символа для отрисовки
   PlotIndexSetInteger(1,PLOT_ARROW,159);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива BullsBuffer в индикаторный буфер
   SetIndexBuffer(3,BullsBuffer1,INDICATOR_DATA);
//---- осуществление сдвига индикатора 3 по горизонтали
   PlotIndexSetInteger(2,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
//---- выбор символа для отрисовки
   PlotIndexSetInteger(2,PLOT_ARROW,159);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива BearsBuffer в индикаторный буфер
   SetIndexBuffer(4,BearsBuffer2,INDICATOR_DATA);
//---- осуществление сдвига индикатора 2 по горизонтали
   PlotIndexSetInteger(3,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
//---- выбор символа для отрисовки
   PlotIndexSetInteger(3,PLOT_ARROW,159);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- превращение динамического массива BullsBuffer в индикаторный буфер
   SetIndexBuffer(5,BullsBuffer2,INDICATOR_DATA);
//---- осуществление сдвига индикатора 3 по горизонтали
   PlotIndexSetInteger(4,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- выбор символа для отрисовки
   PlotIndexSetInteger(4,PLOT_ARROW,159);
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---- инициализации переменной для короткого имени индикатора
   string shortname;
   StringConcatenate(shortname,"JMA( Length = ",Length_,", Phase = ",Phase_,")");
//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,shortname);
//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- Инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;
//---- завершение инициализации
  }
//+------------------------------------------------------------------+  
//| JMA iteration function                                           | 
//+------------------------------------------------------------------+  
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double& high[],     // ценовой массив максимумов цены для расчёта индикатора
                const double& low[],      // ценовой массив минимумов цены  для расчёта индикатора
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total)return(0);

//---- Объявление локальных переменных
   int posA,posB,back,first,bar;
   int shift2,shift1,numb;
//----
   double Res,ResPow;
   double dser3,dser4,jjma,series;
   double ratio,Extr,ser0,resalt;
   double newvel,dSupr,Pow1,hoop1,SmVel;
   double Pow2,Pow2x2,Suprem1,Suprem2;
   double dser1,dser2,extent=0,factor;

   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
     {
      first=0; // стартовый номер для расчёта всех баров
      //---- Инициализация коэффициентов
      JJMAInit(Phase_,Length_,PriceSeries(IPC,0,open,low,high,close));
     }
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- основной цикл расчёта индикатора
   for(bar=first; bar<rates_total; bar++)
     {
      //---- Обращение к функции PriceSeries для получения входной цены Series
      series=PriceSeries(IPC,bar,open,low,high,close);

      //----
      if(m_Loop1<61)
        {
         m_Loop1++;
         m_array[m_Loop1]=series;
        }
      //-x-x-x-x-x-x-x-+      <<< Расчёт функции JMASeries() >>> 
      if(m_Loop1>30)
        {
         if(!m_start)
           {
            m_start= true;
            shift1 = 1;
            back=29;
            //----
            m_ser2 = m_array[1];
            m_ser1 = m_ser2;
           }
         else back=0;
         //-S-S-S-S-+
         for(int rrr=back; rrr>=0; rrr--)
           {
            if(rrr==0)
               ser0=series;
            else ser0=m_array[31-rrr];
            //----
            dser1 = ser0 - m_ser1;
            dser2 = ser0 - m_ser2;
            //----
            if(MathAbs(dser1)>MathAbs(dser2))
               m_var2=MathAbs(dser1);
            else m_var2=MathAbs(dser2);
            //----
            Res=m_var2;
            newvel=Res+0.0000000001;

            if(m_count1<=1)
               m_count1=127;
            else m_count1--;
            //----
            if(m_count2<=1)
               m_count2=10;
            else m_count2--;
            //----
            if(m_count3<128) m_count3++;
            //----          
            m_Sum1+=newvel-m_hoop2[m_count2];
            //----
            m_hoop2[m_count2]=newvel;
            m_bhoop2[m_count2]=true;
            //----
            if(m_count3>10)
               SmVel=m_Sum1/10.0;
            else SmVel=m_Sum1/m_count3;
            //----
            if(m_count3>127)
              {
               hoop1=m_hoop1[m_count1];
               m_hoop1[m_count1]=SmVel;
               m_bhoop1[m_count1]=true;
               numb = 64;
               posB = numb;
               //----
               while(numb>1)
                 {
                  if(m_data[posB]<hoop1)
                    {
                     numb /= 2.0;
                     posB += numb;
                    }
                  else
                     if(m_data[posB]<=hoop1) numb=1;
                  else
                    {
                     numb /= 2.0;
                     posB -= numb;
                    }
                 }
              }
            else
              {
               m_hoop1[m_count1]=SmVel;
               m_bhoop1[m_count1]=true;
               //----
               if(m_midd1+m_midd2>127)
                 {
                  m_midd2--;
                  posB=m_midd2;
                 }
               else
                 {
                  m_midd1++;
                  posB=m_midd1;
                 }
               //----
               if(m_midd1>96)
                  m_pos2=96;
               else m_pos2=m_midd1;
               //----
               if(m_midd2<32)
                  m_pos1=32;
               else m_pos1=m_midd2;
              }
            //----
            numb = 64;
            posA = numb;
            //----
            while(numb>1)
              {
               if(m_data[posA]>=SmVel)
                 {
                  if(m_data[posA-1]<=SmVel) numb=1;
                  else
                    {
                     numb /= 2.0;
                     posA -= numb;
                    }
                 }
               else
                 {
                  numb /= 2.0;
                  posA += numb;
                 }
               //----
               if(posA==127)
                  if(SmVel>m_data[127]) posA=128;
              }
            //----
            if(m_count3>127)
              {
               if(posB>=posA)
                 {
                  if(m_pos2+1>posA)
                     if(m_pos1-1<posA) m_Sum2+=SmVel;
                  //----         
                  else if(m_pos1+0>posA)
                  if(m_pos1-1<posB)
                     m_Sum2+=m_data[m_pos1-1];
                 }
               else
               if(m_pos1>=posA)
                 {
                  if(m_pos2+1<posA)
                     if(m_pos2+1>posB)
                        m_Sum2+=m_data[m_pos2+1];
                 }
               else if(m_pos2+2>posA) m_Sum2+=SmVel;
               //----               
               else if(m_pos2+1<posA)
               if(m_pos2+1>posB)
                  m_Sum2+=m_data[m_pos2+1];
               //----        
               if(posB>posA)
                 {
                  if(m_pos1-1<posB)
                     if(m_pos2+1>posB)
                        m_Sum2-=m_data[posB];
                  //----
                  else if(m_pos2<posB)
                  if(m_pos2+1>posA)
                     m_Sum2-=m_data[m_pos2];
                 }
               else
                 {
                  if(m_pos2+1>posB && m_pos1-1<posB)
                     m_Sum2-=m_data[posB];
                  //----                    
                  else if(m_pos1+0>posB)
                  if(m_pos1-0<posA)
                     m_Sum2-=m_data[m_pos1];
                 }
              }
            //----
            if(posB<=posA)
              {
               if(posB==posA)
                 {
                  m_data[posA]=SmVel;
                  m_bdata[posA]=true;
                 }
               else
                 {
                  for(numb=posB+1; numb<=posA-1; numb++)
                    {
                     m_data[numb-1]=m_data[numb];
                     m_bdata[numb-1]=true;
                    }
                  //----                 
                  m_data[posA-1]=SmVel;
                  m_bdata[posA-1]=true;
                 }
              }
            else
              {
               for(numb=posB-1; numb>=posA; numb--)
                 {
                  m_data[numb+1]=m_data[numb];
                  m_bdata[numb+1]=true;
                 }
               //----                    
               m_data[posA]=SmVel;
               m_bdata[posA]=true;
              }
            //---- 
            if(m_count3<=127)
              {
               m_Sum2=0;
               for(numb=m_pos1; numb<=m_pos2; numb++)
                  m_Sum2+=m_data[numb];
              }
            //---- 
            resalt=m_Sum2/(m_pos2-m_pos1+1.0);
            //----
            if(m_Loop2>30)
               m_Loop2=31;
            else m_Loop2++;
            //----
            if(m_Loop2<=30)
              {
               if(dser1>0.0)
                  m_ser1=ser0;
               else m_ser1=ser0-dser1*m_Kct;
               //----
               if(dser2<0.0)
                  m_ser2=ser0;
               else m_ser2=ser0-dser2*m_Kct;
               //----
               m_JMA=series;
               //----
               if(m_Loop2!=30) continue;
               else
                 {
                  m_storage1=series;
                  if(MathCeil(m_Krx)>=1)
                     dSupr=MathCeil(m_Krx);
                  else dSupr=1.0;
                  //----
                  if(dSupr>0) Suprem2=MathFloor(dSupr);
                  else
                    {
                     if(dSupr<0)
                        Suprem2=MathCeil(dSupr);
                     else Suprem2=0.0;
                    }
                  //----
                  if(MathFloor(m_Krx)>=1)
                     m_var2=MathFloor(m_Krx);
                  else m_var2=1.0;
                  //----
                  if(m_var2>0) Suprem1=MathFloor(m_var2);
                  else
                    {
                     if(m_var2<0)
                        Suprem1=MathCeil(m_var2);
                     else Suprem1=0.0;
                    }
                  //----
                  if(Suprem2==Suprem1) factor=1.0;
                  else
                    {
                     dSupr=Suprem2-Suprem1;
                     factor=(m_Krx-Suprem1)/dSupr;
                    }
                  //---- 
                  if(Suprem1<=29)
                     shift1=(int)Suprem1;
                  else shift1=29;
                  //----
                  if(Suprem2<=29)
                     shift2=(int)Suprem2;
                  else shift2=29;

                  dser3 = series - m_array[m_Loop1 - shift1];
                  dser4 = series - m_array[m_Loop1 - shift2];
                  //----
                  m_djma=dser3 *(1.0-factor)/Suprem1+dser4*factor/Suprem2;
                 }
              }
            else
              {
               ResPow=MathPow(Res/resalt,m_degree);
               //----
               if(m_Kfd>=ResPow)
                  m_var1= ResPow;
               else m_var1=m_Kfd;
               //----
               if(m_var1<1.0)m_var2=1.0;
               else
                 {
                  if(m_Kfd>=ResPow)
                     m_sense=ResPow;
                  else m_sense=m_Kfd;

                  m_var2=m_sense;
                 }
               //---- 
               extent=m_var2;
               Pow1=MathPow(m_Kct,MathSqrt(extent));
               //----
               if(dser1>0.0)
                  m_ser1=ser0;
               else m_ser1=ser0-dser1*Pow1;
               //----
               if(dser2<0.0)
                  m_ser2=ser0;
               else m_ser2=ser0-dser2*Pow1;
              }
           }
         //---- 
         if(m_Loop2>30)
           {
            Pow2=MathPow(m_Krj,extent);
            //----
            m_storage1 *= Pow2;
            m_storage1 += (1.0 - Pow2) * series;
            m_storage2 *= m_Krj;
            m_storage2 += (series - m_storage1) * (1.0 - m_Krj);
            //----
            Extr=m_Phase*m_storage2+m_storage1;
            //----
            Pow2x2= Pow2 * Pow2;
            ratio = Pow2x2-2.0 * Pow2+1.0;
            m_djma *= Pow2x2;
            m_djma += (Extr - m_JMA) * ratio;
            //----
            m_JMA+=m_djma;
           }
        }
      //-x-x-x-x-x-x-x-+

      if(m_Loop1<=30) continue;
      jjma=m_JMA;

      //---- Восстановление значений переменных
      if(bar==rates_total-1)
        {
         //---- Восстановление изменённых ячеек массивов из пямяти
         for(numb = 0; numb < 128; numb++) if(m_bhoop1[numb]) m_hoop1[numb] = m_hoop1_[numb];
         for(numb = 0; numb < 11;  numb++) if(m_bhoop2[numb]) m_hoop2[numb] = m_hoop2_[numb];
         for(numb = 0; numb < 128; numb++) if(m_bdata [numb]) m_data [numb] = m_data_ [numb];

         //---- Обнуление номеров изменённых ячеек массивов
         ArrayInitialize(m_bhoop1,false);
         ArrayInitialize(m_bhoop2,false);
         ArrayInitialize(m_bdata,false);

         //---- запись значений переменных из пямяти 
         m_JMA=m_JMA_;
         m_djma = m_djma_;
         m_ser1 = m_ser1_;
         m_ser2 = m_ser2_;
         m_Sum2 = m_Sum2_;
         m_pos1 = m_pos1_;
         m_pos2 = m_pos2_;
         m_Sum1 = m_Sum1_;
         m_Loop1 = m_Loop1_;
         m_Loop2 = m_Loop2_;
         m_count1 = m_count1_;
         m_count2 = m_count2_;
         m_count3 = m_count3_;
         m_storage1 = m_storage1_;
         m_storage2 = m_storage2_;
         m_midd1 = m_midd1_;
         m_midd2 = m_midd2_;
        }

      //---- Сохранение значений переменных
      if(bar==rates_total-2)
        {
         //---- запись изменённых ячеек массивов в пямять
         for(numb = 0; numb < 128; numb++) if(m_bhoop1[numb]) m_hoop1_[numb] = m_hoop1[numb];
         for(numb = 0; numb < 11;  numb++) if(m_bhoop2[numb]) m_hoop2_[numb] = m_hoop2[numb];
         for(numb = 0; numb < 128; numb++) if(m_bdata [numb]) m_data_ [numb] = m_data [numb];

         //---- Обнуление номеров изменённых ячеек массивов
         ArrayInitialize(m_bhoop1,false);
         ArrayInitialize(m_bhoop2,false);
         ArrayInitialize(m_bdata,false);

         //---- запись значений переменных в пямять
         m_JMA_=m_JMA;
         m_djma_ = m_djma;
         m_Sum2_ = m_Sum2;
         m_ser1_ = m_ser1;
         m_ser2_ = m_ser2;
         m_pos1_ = m_pos1;
         m_pos2_ = m_pos2;
         m_Sum1_ = m_Sum1;
         m_Loop1_ = m_Loop1;
         m_Loop2_ = m_Loop2;
         m_count1_ = m_count1;
         m_count2_ = m_count2;
         m_count3_ = m_count3;
         m_storage1_ = m_storage1;
         m_storage2_ = m_storage2;
         m_midd1_ = m_midd1;
         m_midd2_ = m_midd2;
        }
      //----       
      ExtLineBuffer[bar]=jjma+dPriceShift;
     }
//---- пересчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
      first++;

//---- Основной цикл раскраски сигнальной линии
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      int clr=1;
      if(ExtLineBuffer[bar-1]<ExtLineBuffer[bar]) clr=2;
      if(ExtLineBuffer[bar-1]>ExtLineBuffer[bar]) clr=0;
      ColorExtLineBuffer[bar]=clr;
     }

   double SMAdif,Sum,StDev,dstd,BEARS1,BULLS1,BEARS2,BULLS2,Filter1,Filter2,jma;
//---- пересчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
      first=min_rates_total;
//---- основной цикл расчёта индикатора стандартных отклонений
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      //---- загружаем приращения индикатора в массив для промежуточных вычислений
      for(int iii=0; iii<int(std_period); iii++) dJMA[iii]=ExtLineBuffer[bar-iii]-ExtLineBuffer[bar-iii-1];

      //---- находим простое среднее приращений индикатора
      Sum=0.0;
      for(int iii=0; iii<int(std_period); iii++) Sum+=dJMA[iii];
      SMAdif=Sum/std_period;

      //---- находим сумму квадратов разностей приращений и среднего
      Sum=0.0;
      for(int iii=0; iii<int(std_period); iii++) Sum+=MathPow(dJMA[iii]-SMAdif,2);

      //---- определяем итоговое значение среднеквадратичного отклонения StDev от приращения индикатора
      StDev=MathSqrt(Sum/std_period);

      //---- инициализация переменных
      dstd=NormalizeDouble(dJMA[0],_Digits+2);
      Filter1=NormalizeDouble(dK1*StDev,_Digits+2);
      Filter2=NormalizeDouble(dK2*StDev,_Digits+2);
      BEARS1=EMPTY_VALUE;
      BULLS1=EMPTY_VALUE;
      BEARS2=EMPTY_VALUE;
      BULLS2=EMPTY_VALUE;
      jma=ExtLineBuffer[bar];

      //---- вычисление индикаторных значений
      if(dstd<-Filter1 && dstd>=-Filter2) BEARS1=jma; //есть нисходящий тренд
      if(dstd<-Filter2) BEARS2=jma; //есть нисходящий тренд
      if(dstd>+Filter1 && dstd<=+Filter2) BULLS1=jma; //есть восходящий тренд
      if(dstd>+Filter2) BULLS2=jma; //есть восходящий тренд

      //---- инициализация ячеек индикаторных буферов полученными значениями 
      BullsBuffer1[bar]=BULLS1;
      BearsBuffer1[bar]=BEARS1;
      BullsBuffer2[bar]=BULLS2;
      BearsBuffer2[bar]=BEARS2;
     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|  Инициализация переменных алгоритма JMA                          |
//+------------------------------------------------------------------+    
void JJMAInit(double Phase,double Length,double series)
// JMAInit(Phase, Length, series) 
//+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -+
  {
//----  
//---- <<< Расчёт коэффициентов  >>> 
   m_midd1 = 63;
   m_midd2 = 64;
   m_start = false;

//----
   for(int numb = 0;   numb <= m_midd1; numb++) m_data[numb] = -1000000.0;
   for(int numb = m_midd2; numb <= 127;   numb++) m_data[numb] = +1000000.0;

//---- Все ячейки массивов должны быть переписаны
   ArrayInitialize(m_bhoop1,true);
   ArrayInitialize(m_bhoop2,true);
   ArrayInitialize(m_bdata,true);

//---- Удаление мусора из массивов при повторных инициализациях 
   ArrayInitialize(m_hoop1_, 0.0);
   ArrayInitialize(m_hoop2_, 0.0);
   ArrayInitialize(m_hoop1,  0.0);
   ArrayInitialize(m_hoop2,  0.0);
   ArrayInitialize(m_array,  0.0);
//----
   m_djma = 0.0;
   m_Sum1 = 0.0;
   m_Sum2 = 0.0;
   m_ser1 = 0.0;
   m_ser2 = 0.0;
   m_pos1 = 0.0;
   m_pos2 = 0.0;
   m_Loop1 = 0.0;
   m_Loop2 = 0.0;
   m_count1 = 0.0;
   m_count2 = 0.0;
   m_count3 = 0.0;
   m_storage1 = 0.0;
   m_storage2 = 0.0;
   m_JMA=series;

   if(Phase>=-100 && Phase<=100)
      m_Phase=Phase/100.0+1.5;
//----  
   if(Phase > +100) m_Phase = 2.5;
   if(Phase < -100) m_Phase = 0.5;
//----
   double velA,velB,velC,velD;
//----
   if(Length>=1.0000000002)
      velA=(Length-1.0)/2.0;
   else velA=0.0000000001;
//----
   velA *= 0.9;
   m_Krj = velA / (velA + 2.0);
   velC = MathSqrt(velA);
   velD = MathLog(velC);
   m_var1= velD;
   m_var2= m_var1;
//----
   velB=MathLog(2.0);
   m_sense=(m_var2/velB)+2.0;
   if(m_sense<0.0) m_sense=0.0;
   m_Kfd=m_sense;
//----
   if(m_Kfd>=2.5)
      m_degree=m_Kfd-2.0;
   else m_degree=0.5;
//----
   m_Krx = velC * m_Kfd;
   m_Kct = m_Krx / (m_Krx + 1.0);
//----
  }
//+------------------------------------------------------------------+   
//| Получение значения ценовой таймсерии                             |
//+------------------------------------------------------------------+ 
double PriceSeries
(
 uint applied_price,// Ценовая константа
 uint   bar,// Индекс сдвига относительно текущего бара на указанное количество периодов назад или вперёд).
 const double &Open[],
 const double &Low[],
 const double &High[],
 const double &Close[]
 )
//PriceSeries(applied_price, bar, open, low, high, close)
//+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -+
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
