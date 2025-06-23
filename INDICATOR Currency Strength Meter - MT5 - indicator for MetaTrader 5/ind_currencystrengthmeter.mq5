//+------------------------------------------------------------------+
//|                                    IND_CurrencyStrengthMeter.mq5 |
//|                                        Copyright 2021, FxWeirdos |
//|                                               info@fxweirdos.com |
//+------------------------------------------------------------------+

#property copyright "Copyright 2021, FxWeirdos. Mario Gharib. Forex Jarvis. info@fxweirdos.com"
#property link      "https://fxweirdos.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_plots 0

input color cFontClr = C'255,166,36';                    // FONT COLOR

void vSetLabel(string sName,int sub_window, int xx, int yy, color cFontColor, int iFontSize, string sText) {
   ObjectCreate(0,sName,OBJ_LABEL,sub_window,0,0);
   ObjectSetInteger(0,sName, OBJPROP_YDISTANCE, xx);
   ObjectSetInteger(0,sName, OBJPROP_XDISTANCE, yy);
   ObjectSetInteger(0,sName, OBJPROP_COLOR,cFontColor);
   ObjectSetInteger(0,sName, OBJPROP_WIDTH,FW_BOLD);   
   ObjectSetInteger(0,sName, OBJPROP_FONTSIZE, iFontSize);
   ObjectSetString(0,sName,OBJPROP_TEXT, 0,sText);
}

double dAUD=0.0, dCAD=0.0, dCHF=0.0, dEUR=0.0, dGBP=0.0, dJPY=0.0, dNZD=0.0, dUSD=0.0;
double dArray1[8];
string sArray1[8]={"AUD","CAD", "CHF", "EUR", "GBP", "JPY", "NZD", "USD"};
long chartid;
string sCurrency1, sCurrency2;
int iPos;
int i,j,k;
double dtemp;
string stemp;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cCandlestick {

   public:

      double dOpenPrice;
      double dClosePrice;
            
      void mvGetCandleStickCharateristics (string s, int n) {
         
         dOpenPrice = iOpen(s, PERIOD_CURRENT,n);
         dClosePrice = iClose(s, PERIOD_CURRENT,n);
         
      }
};

void vfunction (string sCountry, double dPrice1, double dPricen, int iSwitch) {

   if (sCountry == "AUD") {
      dAUD=dAUD+(dPrice1-dPricen)/dPrice1*100*iSwitch;
   } else if (sCountry == "CAD") {
      dCAD=dCAD+(dPrice1-dPricen)/dPrice1*100*iSwitch;
   } else if (sCountry == "CHF") {
      dCHF=dCHF+(dPrice1-dPricen)/dPrice1*100*iSwitch;
   } else if (sCountry == "EUR") {
      dEUR=dEUR+(dPrice1-dPricen)/dPrice1*100*iSwitch;
   } else if (sCountry == "GBP") {
      dGBP=dGBP+(dPrice1-dPricen)/dPrice1*100*iSwitch;
   } else if (sCountry == "JPY") {
      dJPY=dJPY+(dPrice1-dPricen)/dPrice1*100*iSwitch;
   } else if (sCountry == "NZD") {
      dNZD=dNZD+(dPrice1-dPricen)/dPrice1*100*iSwitch;
   } else if (sCountry == "USD") {
      dUSD=dUSD+(dPrice1-dPricen)/dPrice1*100*iSwitch;
   }

}    


//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {

   switch(lPeriod)
     {
      case 0: return("PERIOD_CURRENT");
      case 1: return("M1");
      case 5: return("M5");
      case 15: return("M15");
      case 30: return("M30");
      case 60: return("H1");
      case 240: return("H4");
      case 1440: return("D1");
      case 10080: return("W1");
      case 43200: return("MN1");
      case 2: return("M2");
      case 3: return("M3");
      case 4: return("M4");      
      case 6: return("M6");
      case 10: return("M10");
      case 12: return("M12");
      case 16385: return("H1");
      case 16386: return("H2");
      case 16387: return("H3");
      case 16388: return("H4");
      case 16390: return("H6");
      case 16392: return("H8");
      case 16396: return("H12");
      case 16408: return("D1");
      case 32769: return("W1");
      case 49153: return("MN1");      
      default: return("PERIOD_CURRENT");
     }

}



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   
   ObjectsDeleteAll(0);
   
   for(k=0;k<SymbolsTotal(true);k++) {
      chartid=ChartOpen(SymbolName(k,true),PERIOD_CURRENT);
      ChartClose(chartid);
   }

   dAUD=0; dCAD=0; dCHF=0; dEUR=0; dGBP=0; dJPY=0; dNZD=0; dUSD=0;
   iPos=0;
   sCurrency1="";
   sCurrency2="";
   dtemp=0;
   stemp="";

   dArray1[0]=dAUD;
   dArray1[1]=dCAD;
   dArray1[2]=dCHF;
   dArray1[3]=dEUR;
   dArray1[4]=dGBP;
   dArray1[5]=dJPY;
   dArray1[6]=dNZD;
   dArray1[7]=dUSD;

   sArray1[0]="AUD";
   sArray1[1]="CAD";
   sArray1[2]="CHF";
   sArray1[3]="EUR";
   sArray1[4]="GBP";
   sArray1[5]="JPY";
   sArray1[6]="NZD";
   sArray1[7]="USD";
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+

cCandlestick cCS1, cCS2;
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   dAUD=0; dCAD=0; dCHF=0; dEUR=0; dGBP=0; dJPY=0; dNZD=0; dUSD=0;
   iPos=0;
   sCurrency1="";
   sCurrency2="";
   dtemp=0;
   stemp="";

   vSetLabel("CSMBorderUp",0,25,20,cFontClr,8,"==============");
   vSetLabel("CSMTimeFrame",0,45,20,cFontClr,8,"Currency Strength Meter | Timeframe is "+GetTimeFrame(Period()));
   vSetLabel("CSMBorderDown",0,65,20,cFontClr,8,"==============");

   for(k=0;k<SymbolsTotal(true);k++) {

      cCS1.mvGetCandleStickCharateristics(SymbolName(k,true),1);
      cCS2.mvGetCandleStickCharateristics(SymbolName(k,true),12);
      
      if (StringLen(SymbolName(k,true))==7)
         iPos=1;
      
      sCurrency1 = StringSubstr(SymbolName(k,true),0,3);
      sCurrency2 = StringSubstr(SymbolName(k,true),3+iPos,3);

      vfunction(sCurrency1,cCS1.dClosePrice,cCS2.dOpenPrice,1);
      vfunction(sCurrency2,cCS1.dClosePrice,cCS2.dOpenPrice,-1);
   

   }

   dArray1[0]=dAUD;
   dArray1[1]=dCAD;
   dArray1[2]=dCHF;
   dArray1[3]=dEUR;
   dArray1[4]=dGBP;
   dArray1[5]=dJPY;
   dArray1[6]=dNZD;
   dArray1[7]=dUSD;

   sArray1[0]="AUD";
   sArray1[1]="CAD";
   sArray1[2]="CHF";
   sArray1[3]="EUR";
   sArray1[4]="GBP";
   sArray1[5]="JPY";
   sArray1[6]="NZD";
   sArray1[7]="USD";
	   
	for(i=0;i<8;i++) {
		for(j=i+1;j<8;j++) {
			if(dArray1[i]>dArray1[j]) {
				dtemp = dArray1[i];
				stemp = sArray1[i];
				dArray1[i]=dArray1[j];
				sArray1[i]=sArray1[j];
				dArray1[j]=dtemp;
				sArray1[j]=stemp;
			}
		}
	}
   
   for (i=0;i<8;i++)    
      vSetLabel("CSM"+IntegerToString(i)+GetTimeFrame(Period()),0,85+i*20,20,cFontClr,8,sArray1[i]+ " = "+DoubleToString(dArray1[i],2));

   return(rates_total);
}