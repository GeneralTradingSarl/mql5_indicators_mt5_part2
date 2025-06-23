//+------------------------------------------------------------------+
//|                                               GRFLeadingEdge.mq5 | 
//|                                  Copyright © 2007, GammaRatForex | 
//|                                   http://www.gammarat.com/Forex/ | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2007, GammaRatForex"
#property link "http://www.gammarat.com/Forex/"
/*
 * LSQ line fitting to the a number of samples.
 * The trendline is the leading point in the fit;
 * the bands are calculated somewhat differently, check the math below and adapt to 
 * your own needs as appropriate
 * also the point estimate is given by the geometric mean
 * MathPow(HCCC,.025) (see function "get_avg" below) rather than 
 * more standard estimates.
 * It's computationally fairly intensive
 */
//---- номер версии индикатора
#property version   "1.00"
//---- отрисовка индикатора в главном окне
#property indicator_chart_window 
//---- количество индикаторных буферов 5
#property indicator_buffers 5 
//---- использовано всего 5 графических построений
#property indicator_plots   5
//+-----------------------------------+
//|  Параметры отрисовки индикатора   |
//+-----------------------------------+
//---- отрисовка индикатора в виде линии
#property indicator_type1   DRAW_LINE
//---- в качестве цвета линии индикатора использован LimeGreen цвет
#property indicator_color1 clrLimeGreen
//---- линия индикатора - сплошная кривая
#property indicator_style1  STYLE_SOLID
//---- толщина линии индикатора равна 2
#property indicator_width1  2

//+--------------------------------------------+
//|  Параметры отрисовки индикатора BB уровней |
//+--------------------------------------------+
//---- отрисовка уровней в виде линий
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
//---- ввыбор цветов уровней
#property indicator_color2  clrBlue
#property indicator_color3  clrRed
#property indicator_color4  clrRed
#property indicator_color5  clrBlue
//---- уровни - штрихпунктирные кривые
#property indicator_style2 STYLE_DASHDOTDOT
#property indicator_style3 STYLE_DASHDOTDOT
#property indicator_style4 STYLE_DASHDOTDOT
#property indicator_style5 STYLE_DASHDOTDOT
//---- толщина уровней равна 1
#property indicator_width2  1
#property indicator_width3  1
#property indicator_width4  1
#property indicator_width5  1
//+-----------------------------------+
//|  ВХОДНЫЕ ПАРАМЕТРЫ ИНДИКАТОРА     |
//+-----------------------------------+
input uint Samples=60;
input int  LookAhead=0;
input double StdLevel1=2.0;
input double  StdLevel2=4.0;
input int Shift=0; // сдвиг индикатора по горизонтали в барах
input int PriceShift=0; // cдвиг индикатора по вертикали в пунктах
//+-----------------------------------+

//---- объявление динамических массивов, которые будут в 
// дальнейшем использованы в качестве индикаторных буферов
double LeadingEdgeBuffer[];
double LeadingEdgeBufferPlus1[];
double LeadingEdgeBufferNeg1[];
double LeadingEdgeBufferPlus2[];
double LeadingEdgeBufferNeg2[];

double pStdLevel1,pStdLevel2;
//---- Объявление переменной значения вертикального сдвига мувинга
double dPriceShift;
//---- Объявление целых переменных начала отсчёта данных
int min_rates_total;
//+------------------------------------------------------------------+   
//| Custom indicator initialization function                         | 
//+------------------------------------------------------------------+ 
void OnInit()
  {
//---- Инициализация переменных начала отсчёта данных
   min_rates_total=int(Samples);
   
   pStdLevel1=StdLevel1*_Point;
   pStdLevel2=StdLevel2*_Point;

//---- Инициализация сдвига по вертикали
   dPriceShift=_Point*PriceShift;

//---- превращение динамического массива в индикаторный буфер
   SetIndexBuffer(0,LeadingEdgeBuffer,INDICATOR_DATA);
//---- осуществление сдвига индикатора 1 по горизонтали
   PlotIndexSetInteger(0,PLOT_SHIFT,Shift);
//---- осуществление сдвига начала отсчёта отрисовки индикатора
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,min_rates_total);
//--- создание метки для отображения в DataWindow
   PlotIndexSetString(0,PLOT_LABEL,"LeadingEdge Trend");
//---- установка значений индикатора, которые не будут видимы на графике
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0);

//---- превращение динамических массивов в индикаторные буферы
   SetIndexBuffer(1,LeadingEdgeBufferPlus2,INDICATOR_DATA);
   SetIndexBuffer(2,LeadingEdgeBufferPlus1,INDICATOR_DATA);
   SetIndexBuffer(3,LeadingEdgeBufferNeg1,INDICATOR_DATA);
   SetIndexBuffer(4,LeadingEdgeBufferNeg2,INDICATOR_DATA);
//---- установка позиции, с которой начинается отрисовка уровней
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(3,PLOT_DRAW_BEGIN,min_rates_total);
   PlotIndexSetInteger(4,PLOT_DRAW_BEGIN,min_rates_total);
//---- создание меток для отображения в Окне данных
   PlotIndexSetString(1,PLOT_LABEL,"LeadingEdge +"+DoubleToString(StdLevel2,1));
   PlotIndexSetString(2,PLOT_LABEL,"LeadingEdge +"+DoubleToString(StdLevel1,1));
   PlotIndexSetString(3,PLOT_LABEL,"LeadingEdge -"+DoubleToString(StdLevel1,1));
   PlotIndexSetString(4,PLOT_LABEL,"LeadingEdge -"+DoubleToString(StdLevel2,1));
//---- запрет на отрисовку индикатором пустых значений
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//--- создание имени для отображения в отдельном подокне и во всплывающей подсказке
   IndicatorSetString(INDICATOR_SHORTNAME,"LeadingEdge Trend");

//--- определение точности отображения значений индикатора
   IndicatorSetInteger(INDICATOR_DIGITS,_Digits+1);
//---- завершение инициализации
  }
//+------------------------------------------------------------------+ 
//| Custom indicator iteration function                              | 
//+------------------------------------------------------------------+ 
int OnCalculate(
                const int rates_total,    // количество истории в барах на текущем тике
                const int prev_calculated,// количество истории в барах на предыдущем тике
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]
                )
  {
//---- проверка количества баров на достаточность для расчёта
   if(rates_total<min_rates_total) return(0);

//---- Объявление переменных с плавающей точкой  
   double c0,c1,alpha,beta,s0,s1,c01,c11;
   static double base_det,a[2][2],b[2][2];
//---- Объявление целых переменных
   int first,bar,kkk;

//---- расчёт стартового номера first для цикла пересчёта баров
   if(prev_calculated>rates_total || prev_calculated<=0) // проверка на первый старт расчёта индикатора
     {
      first=min_rates_total; // стартовый номер для расчёта всех баров
      ArrayInitialize(a,0);
      for(int iii=0; iii<int(Samples); iii++)
        {
         a[0][0]+=iii*iii;
         a[0][1]+=iii;
         a[1][0]+=iii;
         a[1][1]++;
        }

      base_det=det2(a);
     }
   else first=prev_calculated-1; // стартовый номер для расчёта новых баров

//---- Основной цикл расчёта индикатора
   for(bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      c0=0;
      c1=0;
      for(kkk=0; kkk<int(Samples); kkk++)
        {
         double res=get_avg(bar-kkk,high,low,close);
         c0+=kkk*res;
         c1+=res;
        }

      ArrayCopy(b,a);
      b[0][0]=c0;
      b[1][0]=c1;
      alpha=det2(b)/base_det;

      ArrayCopy(b,a);
      b[0][1]=c0;
      b[1][1]=c1;
      beta=det2(b)/base_det;
      
      double Leading=(beta-alpha*LookAhead)*_Point+dPriceShift;
      LeadingEdgeBuffer[bar]=Leading;

      c0 = 0;
      c1 = 0;
      c11=0;
      c01=0;
      for(kkk=0; kkk<int(Samples); kkk++)
        {
         s0=get_avg(bar-kkk,high,low,close);
         s1=kkk*alpha+beta;
         double res=MathPow(s0-s1,2);
         
         if(s0<s1)
           {
            c0+=res;
            c01++;
           }
         else
           {
            c1+=res;
            c11++;
           }
        }
        
      if(!c01) c01=1;
      if(!c11) c11=1;

      c01=MathSqrt(1./(0.5/MathPow(Samples,2)+0.5/c01/c01));
      c11=MathSqrt(1./(0.5/MathPow(Samples,2)+0.5/c11/c11));
      c0=MathSqrt(c0/c01);
      c1=MathSqrt(c1/c11);
      
      if(MathAbs(StdLevel1)>0)
        {
         LeadingEdgeBufferPlus1[bar]=Leading+pStdLevel1*c0;
         LeadingEdgeBufferNeg1[bar]=Leading-pStdLevel1*c1;
        }
        
      if(MathAbs(StdLevel2)>0)
        {
         LeadingEdgeBufferPlus2[bar]=Leading+pStdLevel2*c0;
         LeadingEdgeBufferNeg2[bar]=Leading-pStdLevel2*c1;
        }

     }
//----     
   return(rates_total);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_avg(int index,const double &High[],const double &Low[],const double &Close[])
  {
//----
   return(MathPow((High[index]*Low[index]*Close[index]*Close[index]),1/4.0)/_Point);
  }
//+------------------------------------------------------------------+
//| Point and figure                                                 |
//+------------------------------------------------------------------+       
double det2(double &a[][2])
  {
//----
   return(a[0][0]*a[1][1]-a[1][0]*a[0][1]);
  }
//+------------------------------------------------------------------+
