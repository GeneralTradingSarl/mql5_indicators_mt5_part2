//+------------------------------------------------------------------+
//|                                  Copyright © 2009-2022, Laguerre |
//+------------------------------------------------------------------+
#property link      "https://t.me/ForexEaPremium"
#property version   "1.02"

#property description "Laguerre - shows weighted trendline in a separate indicator window."

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_color1 clrMagenta
#property indicator_type1  DRAW_LINE
#property indicator_level1 0.80
#property indicator_level2 0.50
#property indicator_level3 0.20
#property indicator_minimum 0
#property indicator_maximum 1

input double Gamma =  0.7;
input int CountBars = 950;

double Laguerre[];

void OnInit()
{
    SetIndexBuffer(0, Laguerre, INDICATOR_DATA);
    IndicatorSetString(INDICATOR_SHORTNAME, "Laguerre");
    ArraySetAsSeries(Laguerre, true);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &Close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    int i = rates_total - 1;
    if (i >= CountBars) i = CountBars - 1;

    ArraySetAsSeries(Close, true);

    double L0 = 0, L1 = 0, L2 = 0, L3 = 0, LRSI = 0;
    
    while (i >= 0)
    {
        double L0A = L0;
        double L1A = L1;
        double L2A = L2;
        double L3A = L3;

        L0 = (1 - Gamma) * Close[i] + Gamma * L0A;
        L1 = -Gamma * L0 + L0A + Gamma * L1A;
        L2 = -Gamma * L1 + L1A + Gamma * L2A;
        L3 = -Gamma * L2 + L2A + Gamma * L3A;

        double CU = 0;
        double CD = 0;

        if (L0 >= L1) CU = L0 - L1;
        else CD = L1 - L0;
        if (L1 >= L2) CU = CU + L1 - L2;
        else CD = CD + L2 - L1;
        if (L2 >= L3) CU = CU + L2 - L3;
        else CD = CD + L3 - L2;

        if (CU + CD != 0) LRSI = CU / (CU + CD);

        Laguerre[i] = LRSI;

        i--;
    }

    return rates_total;
}
//+------------------------------------------------------------------+