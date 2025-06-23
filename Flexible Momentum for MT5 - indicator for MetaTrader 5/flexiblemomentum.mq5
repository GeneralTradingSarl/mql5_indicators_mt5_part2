
#property description   "Shows price momentum in percentage or points during the last N seconds."
#property description   "Alerts on above/below a given threshold."
#property description   ""
#property description   "Find More on https://t.me/ForexEaPremium"


#property indicator_chart_window
#property indicator_plots 0
#property indicator_buffers 1 // Use one buffer to store the current momentum value for EA access.

enum ENUM_ALERT_BEHAVIOR
{
    ENUM_ALERT_BEHAVIOR_NONE, // No alerts
    ENUM_ALERT_BEHAVIOR_SINGLE, // Single alert until next breach
    ENUM_ALERT_BEHAVIOR_CONSTANT, // Continuous alerts whenever condition is met
    ENUM_ALERT_BEHAVIOR_RESTRICTED // Alert on condition but with time limit on next alert
};

enum ENUM_PRICE
{
    ENUM_PRICE_ASK, // Ask
    ENUM_PRICE_BID, // Bid
    ENUM_PRICE_MIDPRICE // Midprice
};

input group "Main"
input int Seconds = 10; // Number of seconds to calculate momentum
input int ThresholdPoints = 30; // Threshold in points
input double ThresholdPercentage = 0.02; // Threshold in percentage
input int DiscardIfOlder = 1; // Discard calculations if ticks are older than N seconds
input ENUM_PRICE PriceToUse = ENUM_PRICE_BID; // PriceToUse: Which price to use?
input group "Alerts"
input ENUM_ALERT_BEHAVIOR AlertBehaviror = ENUM_ALERT_BEHAVIOR_NONE; 
input int AlertTimeLimitForRestricted = 5; // Alert time limit till next alert in seconds
input bool EnableNativeAlerts = false;
input bool EnableEmailAlerts = false;
input bool EnablePushAlerts = false;
input group "Display"
input int Font_Size = 8; // Font size
input color Up_Color = clrGreen; // Up color
input color Down_Color = clrRed; // Down color
input color No_Mvt_Color = clrBlue; // No change color
input int X_Position_Text = 21; // X distance for text
input int Y_Position_Text = 20; // Y distance for text
input ENUM_BASE_CORNER Corner_Position_Text = CORNER_LEFT_LOWER; // Text corner
input string Text_Object = "FM_Text"; // Text object name

int OnInit()
{
    if ((AlertBehaviror != ENUM_ALERT_BEHAVIOR_NONE) && (!EnableNativeAlerts) && (!EnableEmailAlerts) && (!EnablePushAlerts))
    {
        Print("AlertBehaviror is set to issue alerts, but no alret type is enabled. There won't be any alerts.");
    }
    
    if ((AlertBehaviror == ENUM_ALERT_BEHAVIOR_NONE) && ((EnableNativeAlerts) || (EnableEmailAlerts) || (EnablePushAlerts)))
    {
        Print("One or more alert type is enabled, but AlertBehaviror is set to \"No alerts\". There won't be any alerts.");
    }

    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
    ObjectDelete(ChartID(), Text_Object);
    ChartRedraw();
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    static bool syncing = false;
    if (iBarShift(Symbol(), Period(), iTime(Symbol(), Period(), 0), true) < 0) // iBarShift failure.
    {
        // When chart data is in normal state, there shouldn't be an error when searching for the current bar with iBarShift.
        Print("Syncing...");
        syncing = true;
        return prev_calculated;
    }
    if (syncing)
    {
        Print("Synced.");
        syncing = false;
    }

    MqlTick ticks_array[];
    // Tick functions work with milliseconds.
    int end_time_seconds = (int)TimeCurrent();
    ulong begin_time_ms = ulong(end_time_seconds - Seconds - DiscardIfOlder) * 1000; // First time.
    static bool not_enough_chart_data = false;
    if (begin_time_ms / 1000 < (ulong)Time[0]) // Time[0] - oldest bar.
    {
        Print("Not enough chart data...");
        not_enough_chart_data = true;
        return prev_calculated;
    }
    if (not_enough_chart_data)
    {
        Print("Found enough chart data.");
        not_enough_chart_data = false;
    }
    
    // CopyTicks() has inconsistent behavior, so everything is handled with CopyTicksRange().
    int n = CopyTicksRange(Symbol(), ticks_array, COPY_TICKS_ALL, begin_time_ms, (ulong)end_time_seconds * 1000);
    static bool waiting_for_ticks = false;
    if (n <= 0)
    {
        Print("Waiting for ticks... ");
        waiting_for_ticks = true;
        return prev_calculated;
    }
    if (waiting_for_ticks == true)
    {
        Print("Found enough ticks.");
        waiting_for_ticks = false;
    }

    int found_i = -1;
    // From oldest to newest.
    for (int i = 0; i < n; i++)
    {
        if (ticks_array[i].time > end_time_seconds - Seconds) // If newer than exact time, exit. Result - unknown.
        {
            if (i == 0) // Started with time, which is too close to the current time.
            {
                found_i = -1;
            }
            else if (i > 0) // There was at least one tick older than this. It can be used.
            {
                found_i = i - 1;
            }
            break;
        }
        else if (ticks_array[i].time == end_time_seconds - Seconds)
        {
            // Exact match.
            found_i = i;
            break;
        }
    }
    
    string text = "???";
    color colour = No_Mvt_Color;
    int distance_points = 0;
    double distance_percentage = 0;
    long time_ms = 0; // Tick's time in milliseconds for alerts.
    if (found_i >= 0)
    {
        double price_old;
        double price_current;
        switch (PriceToUse)
        {
            case ENUM_PRICE_BID:
            price_old = ticks_array[found_i].bid;
            price_current = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            break;
            case ENUM_PRICE_ASK:
            price_old = ticks_array[found_i].ask;
            price_current = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
            break;
            case ENUM_PRICE_MIDPRICE:
            price_old = (ticks_array[found_i].bid + ticks_array[found_i].ask) / 2;
            price_current = (SymbolInfoDouble(Symbol(), SYMBOL_BID) + SymbolInfoDouble(Symbol(), SYMBOL_ASK)) / 2;
            break;
            default:
            price_old = ticks_array[found_i].bid;
            price_current = SymbolInfoDouble(Symbol(), SYMBOL_BID);
            break;
        }

        time_ms = ticks_array[found_i].time_msc;
        distance_points = (int)MathRound(MathAbs(price_current - price_old) / _Point);
        distance_percentage = 0;
        if (price_old != 0)
        {
            distance_percentage = MathAbs(price_current - price_old) / price_old * 100;
        }
        
        if (ThresholdPoints > 0)
        {
            text = IntegerToString(distance_points) + "p/" + IntegerToString(ThresholdPoints) + "p";
        }
        if (ThresholdPercentage > 0)
        {
            if (text != "") text += ", ";
            text += DoubleToString(distance_percentage, 2) + "%/" + DoubleToString(ThresholdPercentage, 2) + "%";
        }
        if (price_current > price_old)
        {
            colour = Up_Color;
        }
        else if (price_current < price_old)
        {
            colour = Down_Color;
        }
    }

    bool need_points_alert = false;
    bool need_percentage_alert = false;
    static bool prev_need_points_alert = false;
    static bool prev_need_percentage_alert = false;
    static datetime prev_points_alert = 0;
    static datetime prev_percentage_alert = 0;
    bool need_bigger_font = false;
    // Doing this check regardless of the alerts settings to change the display font size in case of a breach.
    if ((ThresholdPoints > 0) && (distance_points >= ThresholdPoints))
    {
        need_points_alert = true;
    }
    else
    {
        need_points_alert = false;
        prev_need_points_alert = false;
    }
    if ((ThresholdPercentage > 0) && (distance_percentage >= ThresholdPercentage))
    {
        need_percentage_alert = true;
    }
    else
    {
        need_percentage_alert = false;
        prev_need_percentage_alert = false;
    }
    // Set a flag requiring font size increase for the output text label.
    if ((need_points_alert) || (need_percentage_alert))
    {
        need_bigger_font = true;
    }
    
    // If no alerts are needed, turn off alert variables and only use need_bigger_font.
    if ((AlertBehaviror == ENUM_ALERT_BEHAVIOR_NONE) || ((!EnableEmailAlerts) && (!EnableNativeAlerts) && (!EnablePushAlerts)))
    {
        need_points_alert = false;
        need_percentage_alert = false;
    }
    // If alerts are needed, check if they can be issued now.
    else
    {
        switch (AlertBehaviror) // Specific behavior.
        {
            case ENUM_ALERT_BEHAVIOR_CONSTANT:
            // Just do alert.
            break;
            case ENUM_ALERT_BEHAVIOR_SINGLE:
            // Only after reset.
            if (prev_need_points_alert) need_points_alert = false;
            else prev_need_points_alert = need_points_alert;
            if (prev_need_percentage_alert) need_percentage_alert = false;
            else prev_need_percentage_alert = need_percentage_alert;
            break;
            
            case ENUM_ALERT_BEHAVIOR_RESTRICTED:
            // Alert only if enough time has passed since the last alert.
            if (TimeCurrent() - prev_points_alert < AlertTimeLimitForRestricted)
            {
                need_points_alert = false;
            }
            else prev_points_alert = TimeCurrent(); // Will alert now.
            if (TimeCurrent() - prev_percentage_alert < AlertTimeLimitForRestricted)
            {
                need_percentage_alert = false;
            }
            else prev_percentage_alert = TimeCurrent(); // Will alert now.
            break;
            default:
            break;
        }
    }
    
    int font_size = Font_Size;
    if (need_bigger_font)
    {
        font_size += 4;
    }
    
    ShowObjects(text + " (" + IntegerToString(Seconds) + "s)",
                Text_Object,
                colour,
                font_size,
                Corner_Position_Text,
                X_Position_Text,
                Y_Position_Text);

    if ((need_points_alert) || (need_percentage_alert)) DoAlerts(need_points_alert, need_percentage_alert, distance_points, distance_percentage, time_ms, colour);

    return rates_total;
}

void ShowObjects(const string text,
                 const string text_obj,
                 const color colour,
                 const int size,
                 const ENUM_BASE_CORNER corner_pos_text,
                 const int x_pos_text,
                 const int y_pos_text)
{
    if (ObjectFind(0, text_obj) < 0)
    {
        ObjectCreate(0, text_obj, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, text_obj, OBJPROP_CORNER, corner_pos_text);
        ObjectSetInteger(0, text_obj, OBJPROP_XDISTANCE, x_pos_text);
        ObjectSetInteger(0, text_obj, OBJPROP_YDISTANCE, y_pos_text);
        ObjectSetString(0, text_obj, OBJPROP_FONT, "Verdana");
    }

    ObjectSetInteger(0, text_obj, OBJPROP_COLOR, colour);
    ObjectSetString(0, text_obj, OBJPROP_TEXT, "Momentum: " + text);
    ObjectSetInteger(0, text_obj, OBJPROP_FONTSIZE, size);
}

void DoAlerts(const bool need_points_alert, const bool need_percentage_alert, const int distance_points, const double distance_percentage, const long time_ms, const color colour)
{
    string direction;
    if (colour == Up_Color) direction = "Up";
    else direction = "Down";
    string Text = "Momentum (" + direction + ") of ";
    if (need_points_alert) Text += IntegerToString(distance_points) + "p over " + IntegerToString(Seconds) + "s > " + IntegerToString(ThresholdPoints) + "p threshold.";
    if (need_percentage_alert)
    {
        if (need_points_alert) Text += " and ";
        Text += DoubleToString(distance_percentage, 2) + "% over " + IntegerToString(Seconds) + "s > " + DoubleToString(ThresholdPercentage, 2) + "% threshold.";
    }
    if (EnableNativeAlerts) Alert(Text);
    if (EnableEmailAlerts) SendMail("FlexibleMomentum Alert on " + Symbol(), Symbol() + ", " + TimeToString(int(time_ms / 1000), TIME_DATE|TIME_MINUTES|TIME_SECONDS) + ":" + StringFormat("%03i", time_ms - int(time_ms / 1000) * 1000) + " - " + Text);
    if (EnablePushAlerts) SendNotification(Symbol() + Text);
}
//+------------------------------------------------------------------+