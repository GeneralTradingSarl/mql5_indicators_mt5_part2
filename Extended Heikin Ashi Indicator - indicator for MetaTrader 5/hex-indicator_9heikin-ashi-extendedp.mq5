/**********************************************************************************
 * Copyright (C) 2010-2020 Dominik Egert <dominik.egert@freie-netze.de>
 *
 * This file is the C-Indicator.
 *
 * Heikin Ashi extended may be copied and/or distributed without explecit permit.
 * Author Dominik Egert / Freie Netze UG.
 **********************************************************************************
 *
 *  File information
 *  ================
 *
 *  Version: 1.00
 *
 *  Use: Heikin Ashi extended
 *
*/

#property copyright "Copyright (C) 2010-2020 Dominik Egert"
#property link      "http://www.freie-netze.de"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   1
#property indicator_type1   DRAW_COLOR_CANDLES
#property indicator_color1  clrDodgerBlue, clrRed, clrGray
#property indicator_label1  "Heiken Ashi Open;Heiken Ashi High;Heiken Ashi Low;Heiken Ashi Close"

// Input
input int   Periods = 1; // Reference period

// Main buffers
static double ExtOBuffer[];
static double ExtHBuffer[];
static double ExtLBuffer[];
static double ExtCBuffer[];
static double ExtColorBuffer[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
const int OnInit()
{
    // Indicator buffers

       SetIndexBuffer(0,ExtOBuffer,INDICATOR_DATA);
       SetIndexBuffer(1,ExtHBuffer,INDICATOR_DATA);
       SetIndexBuffer(2,ExtLBuffer,INDICATOR_DATA);
       SetIndexBuffer(3,ExtCBuffer,INDICATOR_DATA);
       SetIndexBuffer(4,ExtColorBuffer,INDICATOR_COLOR_INDEX);

       IndicatorSetInteger(INDICATOR_DIGITS,_Digits);
       IndicatorSetString(INDICATOR_SHORTNAME,"Heiken Ashi");
       PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);

    // Return
    return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//| Heiken Ashi                                                      |
//+------------------------------------------------------------------+
const int OnCalculate(const int rates_total,const int prev_calculated,
                const datetime &Time[],
                const double &Open[],
                const double &High[],
                const double &Low[],
                const double &Close[],
                const long &TickVolume[],
                const long &Volume[],
                const int &Spread[])
{
    // Local init

        int  i       = NULL;
        int  limit   = NULL;
        const uint symbol_digits_factor = (uint)MathPow(10, SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));


    // Initial period

        if(prev_calculated == 0)
        {
            ExtLBuffer[0]   = Low[0];
            ExtHBuffer[0]   = High[0];
            ExtOBuffer[0]   = Open[0];
            ExtCBuffer[0]   = Close[0];
            limit           = Periods;
        }
        else 
        { limit = prev_calculated - 1; }


    // Main loop

        for(i = limit; (i < rates_total) && !_StopFlag; i++)
        {
            // Primary calculations

                double haOpen   = (ExtOBuffer[i - Periods] + ExtCBuffer[i - Periods]) / 2.0;
                double haClose  = (Open[i] + High[i] + Low[i] + Close[i]) / 4.0;
                double haHigh   = MathMax(High[i], MathMax(haOpen, haClose));
                double haLow    = MathMin(Low[i], MathMin(haOpen, haClose));
                
                ExtLBuffer[i]   = haLow;
                ExtHBuffer[i]   = haHigh;
                ExtOBuffer[i]   = haOpen;
                ExtCBuffer[i]   = haClose;
    
    
            // Set colors

                if( (MathMax(ExtCBuffer[i - Periods], ExtOBuffer[i - Periods]) > haClose)
                 || ((MathMin(haClose, haOpen) > haLow) && (MathMax(haClose, haOpen) == haHigh))
                 || (MathMin(haClose, haOpen) < haLow) )
                { ExtColorBuffer[i] = 1.0; }
                
                if( (MathMin(ExtCBuffer[i - Periods], ExtOBuffer[i - Periods]) < haClose)
                 || ((MathMin(haClose, haOpen) == haLow) && (MathMax(haClose, haOpen) < haHigh))
                 || (MathMax(haClose, haOpen) < haHigh) )
                { ExtColorBuffer[i] = 0.0; }
        
                if( (MathMin(haOpen, haClose) > haLow)
                 && (MathMax(haOpen, haClose) < haHigh) )
                { ExtColorBuffer[i] = ExtColorBuffer[i - 1]; }
                
                if( (MathMin(ExtOBuffer[i - 1], ExtCBuffer[i - 1]) > ExtLBuffer[i - 1])
                 && (MathMax(ExtOBuffer[i - 1], ExtCBuffer[i - 1]) < ExtHBuffer[i - 1])
                 && (MathMin(haOpen, haClose) > haLow)
                 && (MathMax(haOpen, haClose) < haHigh) )
                { ExtColorBuffer[i] = 2.0; }
        
                if((haHigh - haLow) < (Spread[i] / symbol_digits_factor))
                { ExtColorBuffer[i] = 2.0; }
                
                if(haOpen == haClose)
                { ExtColorBuffer[i] = ExtColorBuffer[i - 1]; }
        }

    // Return
    return(rates_total);
}
//+------------------------------------------------------------------+
