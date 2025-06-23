#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGreen
#property indicator_label1  "Balance"
#property indicator_width1  1

#property indicator_type2   DRAW_LINE
#property indicator_color2  clrBlue
#property indicator_label2  "Equity"
#property indicator_width2  2

double BalanceBuffer[];
double EquityBuffer[];

int OnInit() {
   SetIndexBuffer(0, BalanceBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, EquityBuffer, INDICATOR_DATA);
   return(INIT_SUCCEEDED);
}

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
   
   int start = prev_calculated > 0 ? prev_calculated - 1 : 0;
   
   for(int i = start; i < rates_total; i++) {
      double balance = 0;
      double unrealizedPnL = 0;
      
      // Get all deals up to current bar time
      HistorySelect(0, time[i]);
      
      // Calculate realized P&L (balance)
      for(int j = 0; j < HistoryDealsTotal(); j++) {
         ulong ticket = HistoryDealGetTicket(j);
         if(ticket > 0 && HistoryDealGetInteger(ticket, DEAL_TIME) <= time[i]) {
            balance += HistoryDealGetDouble(ticket, DEAL_PROFIT);
            balance += HistoryDealGetDouble(ticket, DEAL_SWAP);
            balance += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         }
      }
      
      // Track open positions
      string openSymbols[];
      double openVolumes[];
      double openPrices[];
      int openCount = 0;
      
      // Process all deals to calculate net positions
      for(int j = 0; j < HistoryDealsTotal(); j++) {
         ulong ticket = HistoryDealGetTicket(j);
         if(ticket == 0) continue;
         
         if((datetime)HistoryDealGetInteger(ticket, DEAL_TIME) > time[i]) continue;
         
         string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
         double dealVolume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
         double price = HistoryDealGetDouble(ticket, DEAL_PRICE);
         long type = HistoryDealGetInteger(ticket, DEAL_TYPE);
         long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
         
         // Find or create symbol entry
         int idx = -1;
         for(int k = 0; k < openCount; k++) {
            if(openSymbols[k] == symbol) {
               idx = k;
               break;
            }
         }
         
         if(idx == -1) {
            idx = openCount++;
            ArrayResize(openSymbols, openCount);
            ArrayResize(openVolumes, openCount);
            ArrayResize(openPrices, openCount);
            openSymbols[idx] = symbol;
            openVolumes[idx] = 0;
            openPrices[idx] = 0;
         }
         
         // Update position based on deal
         if(entry == DEAL_ENTRY_IN) {
            double oldVolume = openVolumes[idx];
            double totalCost = MathAbs(oldVolume) * openPrices[idx] + dealVolume * price;
            
            if(type == DEAL_TYPE_BUY) {
               openVolumes[idx] += dealVolume;
            } else if(type == DEAL_TYPE_SELL) {
               openVolumes[idx] -= dealVolume;
            }
            
            if(MathAbs(openVolumes[idx]) > 0.00001) {
               openPrices[idx] = totalCost / MathAbs(openVolumes[idx]);
            }
         } else if(entry == DEAL_ENTRY_OUT) {
            openVolumes[idx] += (type == DEAL_TYPE_BUY ? dealVolume : -dealVolume);
         }
      }
      
      // Calculate unrealized P&L for open positions
      for(int j = 0; j < openCount; j++) {
         if(MathAbs(openVolumes[j]) < 0.00001) continue;
         
         // Get current price
         double currentPrice = 0;
         if(openSymbols[j] == _Symbol) {
            currentPrice = close[i];
         } else {
            double closeArray[1];
            if(CopyClose(openSymbols[j], _Period, time[i], 1, closeArray) > 0) {
               currentPrice = closeArray[0];
            } else {
               continue;
            }
         }
         
         // Calculate P&L
         double pnl = openVolumes[j] * (currentPrice - openPrices[j]);
         
         // Convert to account currency if needed
         string accCurrency = AccountInfoString(ACCOUNT_CURRENCY);
         string profitCurrency = SymbolInfoString(openSymbols[j], SYMBOL_CURRENCY_PROFIT);
         
         if(accCurrency != profitCurrency) {
            double tickValue = SymbolInfoDouble(openSymbols[j], SYMBOL_TRADE_TICK_VALUE);
            double tickSize = SymbolInfoDouble(openSymbols[j], SYMBOL_TRADE_TICK_SIZE);
            if(tickSize > 0) {
               pnl = pnl * tickValue / tickSize;
            }
         }
         
         unrealizedPnL += pnl;
      }
      
      // Add swap for current bar only
      if(i == rates_total - 1) {
         for(int p = 0; p < PositionsTotal(); p++) {
            if(PositionSelectByTicket(PositionGetTicket(p))) {
               unrealizedPnL += PositionGetDouble(POSITION_SWAP);
            }
         }
      }
      
      BalanceBuffer[i] = balance;
      EquityBuffer[i] = balance + unrealizedPnL;
   }
   
   return(rates_total);
}
