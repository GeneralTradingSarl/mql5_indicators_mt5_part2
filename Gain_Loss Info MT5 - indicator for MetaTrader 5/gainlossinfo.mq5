//+------------------------------------------------------------------+
//|                                                 GainLossInfo.mq5 |
//+------------------------------------------------------------------+
#property version   "1.01"
#property strict

#property description "Shows percentage and point gain/loss for a candle."
#property description "Can calculate gain/loss compared either to the previous Close or to the current Open."

// The indicator uses only objects for display, but the line below is required for it to work.
#property indicator_chart_window
#property indicator_plots 0

input double PercentageLimit = 1.0; // PercentageLimit - Will not display number if percentage gain/loss is below limit.
input int PointsLimit = 1000; // PointsLimit - Will not display number if points gain/loss is below limit.
// If true, will compare Close of the current candle to Close of the previous one. Otherwise compares current Close to current Open.
input bool CloseToClose = true;
input color DisplayLossColor = clrRed;
input color DisplayGainColor = clrLimeGreen;
input int MaxBars = 100; // MaxBars: More bars - more objects - more lag and memory usage.
input string FontFace = "Verdana";
input int FontSize = 10;
input string ObjectPrefix = "GLI-";

void OnDeinit(const int reason)
{
    ObjectsDeleteAll(0, ObjectPrefix, -1, OBJ_TEXT);
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
    // Redraw visible labels.
    if (id == CHARTEVENT_CHART_CHANGE) RedrawVisibleLabels();
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    string name, perc, points;
    int index = rates_total - 1;
    double start;

    int counted_bars = prev_calculated;
    if (counted_bars > 0) counted_bars--;
    int limit = counted_bars;
    if (rates_total - counted_bars > MaxBars) limit = rates_total - MaxBars;

    for (int i = rates_total - 1; i >= limit; i--)
    {
        if ((CloseToClose) && (i > 0)) start = Close[i - 1];
        else start = Open[i];

        name = ObjectPrefix + "Percent-" + TimeToString(Time[i], TIME_DATE | TIME_MINUTES);
        ObjectDelete(0, name);
        if (((Close[i] - start) / start) * 100 >= PercentageLimit) // Gain percent display
        {
            perc = DoubleToString(((Close[i] - start) / start) * 100, 1) + "%";
            ObjectCreate(0, name, OBJ_TEXT, 0, Time[i], High[i]);
            ObjectSetString(0, name, OBJPROP_TEXT, perc);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FontSize);
            ObjectSetString(0, name, OBJPROP_FONT, FontFace);
            ObjectSetInteger(0, name, OBJPROP_COLOR, DisplayGainColor);
            int visible_bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
            int first_bar = (int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
            int last_bar = first_bar - visible_bars + 1;
            if ((i <= first_bar) && (i >= last_bar)) RedrawOneLabel(i, last_bar);
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }
        else if (((start - Close[i]) / start) * 100 >= PercentageLimit) // Loss percent display
        {
            perc = DoubleToString(((start - Close[i]) / start) * 100, 1) + "%";
            ObjectCreate(0, name, OBJ_TEXT, 0, Time[i], High[i]);
            ObjectSetString(0, name, OBJPROP_TEXT, perc);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FontSize);
            ObjectSetString(0, name, OBJPROP_FONT, FontFace);
            ObjectSetInteger(0, name, OBJPROP_COLOR, DisplayLossColor);
            int visible_bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
            int first_bar = (int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
            int last_bar = first_bar - visible_bars + 1;
            if ((i <= first_bar) && (i >= last_bar)) RedrawOneLabel(i, last_bar);
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }

        name = ObjectPrefix + "Points-" + TimeToString(Time[i], TIME_DATE | TIME_MINUTES);
        ObjectDelete(0, name);
        if ((Close[i] - start) / _Point >= PointsLimit) // Gain points display
        {
            points = DoubleToString((Close[i] - start) / _Point, 0);
            ObjectCreate(0, name, OBJ_TEXT, 0, Time[i], Low[i]);
            ObjectSetString(0, name, OBJPROP_TEXT, points);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FontSize);
            ObjectSetString(0, name, OBJPROP_FONT, FontFace);
            ObjectSetInteger(0, name, OBJPROP_COLOR, DisplayGainColor);
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }
        else if ((start - Close[i]) / _Point >= PointsLimit) // Loss points display
        {
            points = DoubleToString((start - Close[i]) / _Point, 0);
            ObjectCreate(0, name, OBJ_TEXT, 0, Time[i], Low[i]);
            ObjectSetString(0, name, OBJPROP_TEXT, points);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, FontSize);
            ObjectSetString(0, name, OBJPROP_FONT, FontFace);
            ObjectSetInteger(0, name, OBJPROP_COLOR, DisplayLossColor);
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }
    }

    return rates_total;
}

// Required only for labels above High.
void RedrawVisibleLabels()
{
   int visible_bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
   int first_bar = (int)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
   int last_bar = first_bar - visible_bars + 1;
   
   // Process all bars on the current screen.
   for (int i = first_bar; i >= last_bar; i--) RedrawOneLabel(i, last_bar);
}

void RedrawOneLabel(const int i, const int last_bar)
{
   int x, y, cw;
   uint w, h;
   datetime t;
   double p, high;
   string length, name;

   // For further use.
   high = iHigh(NULL, 0, i);

   name = GenerateObjectName("Percent-", iTime(NULL, Period(), i));
   if (ObjectFind(0, name) == -1) return;
   // Needed only for y; x is used as a dummy.
   ChartTimePriceToXY(0, 0, iTime(NULL, Period(), last_bar), high, x, y);
   // Get the height of the text based on font and its size. Negative because OS-dependent, *10 because set in 1/10 of pt.
   TextSetFont(FontFace, FontSize * -10);
   length = DoubleToString(MathRound((high - MathMax(iOpen(NULL, 0, i), iClose(NULL, 0, i))) / _Point), 0);
   TextGetSize(length, w, h);

   // Normal shift of the text upward will result in negative Y coordinate and the price level will be moved down.
   // To work around this, we have to calculate the "price difference" of the necessary "pixel difference" (price height of h).
   // Then, add it to the High of the bar.
   if (y - (int)h - 2 < 0)
   {
      if (!ChartXYToTimePrice(0, x, y + h + 2, cw, t, p)) Print("Error: ", GetLastError());
      double diff = high - p;
      p = high + diff;
   }
   // Normal way.
   else ChartXYToTimePrice(0, x, y - h - 2, cw, t, p);

   ObjectSetDouble(0, name, OBJPROP_PRICE, p);
}

string GenerateObjectName(const string prefix, const datetime time)
{
   return ObjectPrefix + prefix + TimeToString(time, TIME_DATE | TIME_MINUTES);
}
//+------------------------------------------------------------------+