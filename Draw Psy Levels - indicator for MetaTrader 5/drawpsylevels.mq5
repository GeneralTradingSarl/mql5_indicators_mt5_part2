//===================================================================//
//                                   Transl_DrawPsyLevels_v_1-01.mq5 ||
//                                 Copyright © 2012.04.27, Alexander ||
// ICQ: 609928564 | email: I-m-hungree@yandex.ru | skype:i_m_hungree ||
//===================================================================||
//                    ---------------------------                    ||
//                    The source code information                    ||
//                    ---------------------------                    ||
//                                                                   ||
//                                              DrawPsyLevels_v1.mq4 ||
//                                 Copyright © 2011, TrendLaboratory ||
//             http://finance.groups.yahoo.com/group/TrendLaboratory ||
//                                    E-mail: igorad2003@yahoo.co.uk ||
//===================================================================\\

#property copyright "Copyright © 2012, Im_hungry"
#property version   "1.01"
#property link      "Transl_DrawPsyLevels_v_1-01 by Im_hungry"

#define Label "Transl_DrawPsyLevels "

#property indicator_chart_window

#property indicator_buffers 1
#property indicator_plots   1

#property indicator_type1   DRAW_ARROW

#property indicator_color1  Magenta

#property indicator_width1  2

//=================================================================//
input  string             Section_1           =                  "========  Level";
input  double             MaxPrice            = 1.4;
input  double             MinPrice            = 1.1;
input  int                PriceStep           = 50;
input  int                Levelwidth          = 1;
input  color              LevelsColor         = Yellow;
input  ENUM_LINE_STYLE    LevelsStyle         = STYLE_DOT;
//=================================================================//
input  string             Section_2           =                  "========  Arrow";
input  bool               DrawArrows          = true;

//=================================================================//
//                     global parameters                           ||
//=================================================================//

       double             Arrow[],
                          aPivot[],
                          md_Point;

       int                PivotsNum;

       datetime           pTouchTime;

//=================================================================//
//             Custom indicator initialization function            ||
//=================================================================//
int OnInit()
{
  SetIndexBuffer(0, Arrow,  INDICATOR_DATA);

  PlotIndexSetString(0,PLOT_LABEL,"Arrow");

  IndicatorSetString(INDICATOR_SHORTNAME,Label+"  ( "+Symbol()+" )  ");

  PlotIndexSetInteger(0, PLOT_ARROW, 169);

//-------

  int         kp              = 1;
  if (Digits() == 5 || Digits() == 3 || Digits() == 1)
              kp              = 10;
              md_Point        = SymbolInfoDouble(Symbol(),SYMBOL_POINT) * kp;

//-------

  double      Max             = MaxPrice;
  if(MaxPrice == 0.0)
   {
    double    High[1];
              CopyHigh(Symbol(), 0, 0, 1, High);
              Max = (MathRound(High[0] / (PriceStep * md_Point)) + 2) * (PriceStep * md_Point);
   }
  double      Min             = MinPrice;
  if(MinPrice == 0.0)
   {
    double    Low[1];
              CopyLow(Symbol(), 0, 0, 1, Low);
              Min = (MathRound(Low[0] / (PriceStep * md_Point)) - 2) * (PriceStep * md_Point);
   }

//-------

              PivotsNum       = (int) ( (Max - Min)/(PriceStep * md_Point) + 1);
              ArrayResize(aPivot, PivotsNum);
  for(int i = 0; i < PivotsNum; i++) 
   {
              aPivot[i]       = NormalizeDouble((Min + (PriceStep * md_Point) * i), Digits());
    string    str_name        = "lev # "+(string)i+" = "+DoubleToString(aPivot[i],Digits());
              PlotLine(str_name, aPivot[i]);
   }

//-------

  return(0);
}
//=================================================================//
//                          delete                                 ||
//=================================================================//
void OnDeinit(const int reason)
{
  string      name_obj;
  for(int i = ObjectsTotal(0); i >= 0; i--)
   {
              name_obj        = ObjectName(0, i);
    if (StringFind(name_obj, "lev", 0) != -1)
     {
      ObjectDelete(0, name_obj);
     }
   }

//----

}
//=================================================================//
//              Custom indicator iteration function                ||
//=================================================================//
int OnCalculate(const int       rates_total,
                const int       prev_calculated,
                const datetime  &time[],
                const double    &open[],
                const double    &high[],
                const double    &low[],
                const double    &close[],
                const long      &tick_volume[],
                const long      &volume[],
                const int       &spread[])
{
 int          touch,
              i;
 double       ZeroLevel;
 datetime     TouchTime; 

 for(int t = rates_total - 1; t >= 0; t--)
  {
              i               = 0;   
   while(i < PivotsNum)
    {
     if(high[t] >= aPivot[i] && low[t] <= aPivot[i])
      {
              touch           = 1; 
              ZeroLevel       = aPivot[i] - ((PriceStep*md_Point) / 10); 
              TouchTime       = time[t]; 
              break;
      } 
      i++;
	 }
	if(DrawArrows == true && touch > 0 && TouchTime != pTouchTime) 
	 {
	           Arrow[t]        = ZeroLevel;
	           pTouchTime      = TouchTime;
    }
  }
              return(rates_total);
}
//=================================================================//
//                           PlotLine                              ||
//=================================================================//
void PlotLine (string   name,
               double   value)
{
 if(value > 0)
  {
   ObjectDelete (0, name);
   ObjectCreate (0, name, OBJ_HLINE, 0, 0, value);

   ObjectSetInteger (0, name, OBJPROP_WIDTH, Levelwidth);
   ObjectSetInteger (0, name, OBJPROP_STYLE, LevelsStyle);
   ObjectSetInteger (0, name, OBJPROP_COLOR, LevelsColor);
  }
}
//=================================================================//
//                       drawArrow                                 ||
//=================================================================//
void drawArrow(datetime time,
               double   price,
               int      size,
               color    clr)
{
  string      c_name          = "lev _ "+(string)PriceStep+" = "+TimeToString(time);  
  ObjectCreate(0, c_name, OBJ_TEXT, 0, time, price);
  ObjectSetInteger (0, c_name, OBJPROP_WIDTH, size);
  ObjectSetInteger (0, c_name, OBJPROP_COLOR, clr);
}