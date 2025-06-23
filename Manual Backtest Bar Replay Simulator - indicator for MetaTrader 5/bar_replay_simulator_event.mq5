//+------------------------------------------------------------------+
//|                                         Bar_Replay_Simulator.mq5 |
//|                                Copyright 2025, Rajesh Kumar Nait |
//|                  https://www.mql5.com/en/users/rajeshnait/seller |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Rajesh Kumar Nait"
#property link      "https://www.mql5.com/en/users/rajeshnait/seller"
#property version   "1.00"
#property indicator_chart_window

#property indicator_buffers 6
#property indicator_plots 1                     // Number of graphic plots        
#property indicator_label1 "Open;High;Low;Close"
#property indicator_type1 DRAW_COLOR_CANDLES    // Drawing style color candles
#property indicator_width1 1                    // Width of the graphic plot              

color Color_Bar_Up_1;
color Color_Bar_Down_1;
color Color_Bar_Up_0;
color Color_Bar_Down_0;

// Declaration of buffers
double buf_open[], buf_high[], buf_low[], buf_close[]; // Buffers for data
double buf_color_line[];                                // Buffer for color indexes

long vl_time=0;
string vl_name = "VL";
//+------------------------------------------------------------------+
//| Custom indicator initialization function                        |
//+------------------------------------------------------------------+
int OnInit() {
// Initialize chart colors and buffers
   ChartSetInteger(0, CHART_EVENT_OBJECT_CREATE, true);
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, true);
   Color_Bar_Up_1 = ChartBearColorGet(0);
   Color_Bar_Down_1 = ChartBackColorGet(0);
   Color_Bar_Up_0 = ChartBullColorGet(0);
   Color_Bar_Down_0 = ChartBackColorGet(0);

// Assign the arrays with the indicator's buffers
   SetIndexBuffer(0, buf_open, INDICATOR_DATA);
   SetIndexBuffer(1, buf_high, INDICATOR_DATA);
   SetIndexBuffer(2, buf_low, INDICATOR_DATA);
   SetIndexBuffer(3, buf_close, INDICATOR_DATA);
   SetIndexBuffer(4, buf_color_line, INDICATOR_COLOR_INDEX);

   PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 4);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 0, Color_Bar_Up_0);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 1, Color_Bar_Down_0);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 2, Color_Bar_Up_1);
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, 3, Color_Bar_Down_1);

// Initial buffer update
   UpdateBuffers();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| ChartEvent handler                                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {
// Check if the "VL" object is moved
   if (id == CHARTEVENT_OBJECT_DRAG && sparam == vl_name) {
      UpdateBuffers(); // Update buffers only when "VL" is moved
   }

   if(id == CHARTEVENT_KEYDOWN  && lparam == 0x11) {
      Print("ctrl");
      vl_time = ObjectGetInteger(0, vl_name, OBJPROP_TIME);

      // Find the current bar index where the line is placed
      int current_bar_shift = iBarShift(_Symbol, _Period, vl_time);

      // Calculate the new bar shift (1 bar to the right)
      int new_bar_shift = current_bar_shift - 1;

      // Ensure we don't go beyond the chart
      if (new_bar_shift < 0) {
         Print("Cannot shift beyond the first bar!");
         return;
      }

      // Get the new time for the Vertical Line
      datetime new_time = iTime(_Symbol, _Period, new_bar_shift);

      // Update the Vertical Line's position
      ObjectSetInteger(0, vl_name, OBJPROP_TIME, new_time);

      //Print("Moved '", vl_name, "' 1 bar right. New time: ", TimeToString(new_time));
      UpdateBuffers();
   }

}

//+------------------------------------------------------------------+
//| Core function to update buffers                                  |
//+------------------------------------------------------------------+
void UpdateBuffers() {
// Get historical data
   int rates_total = Bars(_Symbol, _Period);

   datetime time[];
   double open[], high[], low[], close[];

// Copy data and check for errors
   int copied_time = CopyTime(_Symbol, _Period, 0, rates_total, time);
   int copied_open = CopyOpen(_Symbol, _Period, 0, rates_total, open);
   int copied_high = CopyHigh(_Symbol, _Period, 0, rates_total, high);
   int copied_low = CopyLow(_Symbol, _Period, 0, rates_total, low);
   int copied_close = CopyClose(_Symbol, _Period, 0, rates_total, close);

// Validate copied data sizes
   if (copied_time != rates_total || copied_open != rates_total ||
         copied_high != rates_total || copied_low != rates_total ||
         copied_close != rates_total || ObjectFind(0, vl_name) == -1) {
      return;
   }

   vl_time = ObjectGetInteger(0, vl_name, OBJPROP_TIME);

// Ensure buffer indices are within bounds
   int buffer_size = ArraySize(buf_open); // Get current buffer size

   for(int i = 0; i < buffer_size && i < rates_total; i++) {
      buf_open[i] = open[i];
      buf_high[i] = high[i];
      buf_low[i] = low[i];
      buf_close[i] = close[i];

      datetime candle_time = time[i];
      if(candle_time > vl_time) {
         buf_color_line[i] = (open[i] >= close[i]) ? 3 : 1;
      } else {
         buf_color_line[i] = (open[i] >= close[i]) ? 2 : 0;
      }
   }

   ChartRedraw(); // Force chart refresh
}

//+------------------------------------------------------------------+
//| Dummy OnCalculate (required for indicators)                      |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {

   return(rates_total); // No processing here
}
//+------------------------------------------------------------------+
//| Gets the background color of chart                               |
//+------------------------------------------------------------------+
color ChartBackColorGet(const long chart_ID=0) {
//--- prepare the variable to receive the color
   long result=clrNONE;
//--- reset the error value
   ResetLastError();
//--- receive chart background color
   if(!ChartGetInteger(chart_ID,CHART_COLOR_BACKGROUND,0,result)) {
      //--- display the error message in Experts journal
      Print(__FUNCTION__+", Error Code = ",GetLastError());
   }
//--- return the value of the chart property
   return((color)result);
}

//+------------------------------------------------------------------+
//| Gets the color of bullish candlestick's body                     |
//+------------------------------------------------------------------+
color ChartBullColorGet(const long chart_ID=0) {
//--- prepare the variable to receive the color
   long result=clrNONE;
//--- reset the error value
   ResetLastError();
//--- receive the color of bullish candlestick's body
   if(!ChartGetInteger(chart_ID,CHART_COLOR_CANDLE_BULL,0,result)) {
      //--- display the error message in Experts journal
      Print(__FUNCTION__+", Error Code = ",GetLastError());
   }
//--- return the value of the chart property
   return((color)result);
}

//+------------------------------------------------------------------+
//| Gets the color of bearish candlestick's body                     |
//+------------------------------------------------------------------+
color ChartBearColorGet(const long chart_ID=0) {
//--- prepare the variable to receive the color
   long result=clrNONE;
//--- reset the error value
   ResetLastError();
//--- receive the color of bearish candlestick's body
   if(!ChartGetInteger(chart_ID,CHART_COLOR_CANDLE_BEAR,0,result)) {
      //--- display the error message in Experts journal
      Print(__FUNCTION__+", Error Code = ",GetLastError());
   }
//--- return the value of the chart property
   return((color)result);
}
//+------------------------------------------------------------------+
