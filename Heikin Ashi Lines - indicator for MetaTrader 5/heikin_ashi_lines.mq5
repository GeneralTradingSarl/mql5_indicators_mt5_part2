//---------------------------------------------------------------------------------------------------------------------
#define     MName          "Heikin Ashi Lines"
#define     MVersion       "1.0"
#define     MBuild         "2023-11-10 13:37 WET"
#define     MCopyright     "Copyright \x00A9 2023, Fernando M. I. Carreiro, All rights reserved"
#define     MProfile       "https://www.mql5.com/en/users/FMIC"
//---------------------------------------------------------------------------------------------------------------------
#property   strict
#property   version        MVersion
#property   description    MName
#property   description    "MetaTrader Indicator (Build "MBuild")"
#property   copyright      MCopyright
#property   link           MProfile
//---------------------------------------------------------------------------------------------------------------------

//--- Setup

   #property indicator_chart_window

   // Define number of buffers and plots
      #define MPlots    2
      #define MBuffers  2
      #ifndef __MQL4__
         #property indicator_buffers   MBuffers
         #property indicator_plots     MPlots
      #else
         #property indicator_buffers   MPlots
      #endif

   // Display properties for Heikin Ashi candles
      #property indicator_label1 "haOpen"
      #property indicator_label2 "haClose"
      #property indicator_color1 clrGray
      #property indicator_color2 clrGray
      #property indicator_width1 1
      #property indicator_width2 2
      #property indicator_style1 STYLE_DOT
      #property indicator_style2 STYLE_SOLID
      #property indicator_type1  DRAW_LINE
      #property indicator_type2  DRAW_LINE

//--- Parameter settings

   input double   i_dbPeriod  = 3.0;   // Averaging period (standard = 3.0)

//--- Macro definitions

   // Define OnCalculate loop sequencing macros
      #ifdef __MQL4__   // for MQL4 (as series)
         #define MOnCalcNext(  _index          ) ( _index--             )
         #define MOnCalcBack(  _index, _offset ) ( _index + _offset     )
         #define MOnCalcCheck( _index          ) ( _index >= 0          )
         #define MOnCalcValid( _index          ) ( _index < rates_total )
         #define MOnCalcStart \
            ( rates_total - ( prev_calculated < 1 ? 1 : prev_calculated ) )
      #else             // for MQL5 (as non-series)
         #define MOnCalcNext(  _index          ) ( _index++             )
         #define MOnCalcBack(  _index, _offset ) ( _index - _offset     )
         #define MOnCalcCheck( _index          ) ( _index < rates_total )
         #define MOnCalcValid( _index          ) ( _index >= 0          )
         #define MOnCalcStart \
            ( prev_calculated < 1 ? 0 : prev_calculated - 1 )
      #endif

   // Define macro for invalid parameter values
      #define MCheckParameter( _condition, _text ) if( _condition ) { \
         Print( "Error: Invalid ", _text ); return INIT_PARAMETERS_INCORRECT; }

//--- Global variable declarations

   // Indicator buffers
      double   g_adbHaOpen[],    // Buffer for Heikin Ashi open price (exponential moving average)
               g_adbHaClose[];   // Buffer for Heikin Ashi close price (total price)

   // Miscellaneous global variables
      double   g_dbAlphaWeight;  // Alpha weight to be used for exponential moving average

//--- Event handling functions

   // Initialisation event handler
      int OnInit(void) {
         // Validate input parameters
            MCheckParameter( i_dbPeriod < 1.0, "averaging period!" );

         // Calculate parameter variables
            g_dbAlphaWeight = 2.0 / ( i_dbPeriod + 1.0 );

         // Set number of significant digits (precision)
            IndicatorSetInteger( INDICATOR_DIGITS, _Digits );

         // Add buffers for heikin ashi open and close
            SetIndexBuffer( 0, g_adbHaOpen,  INDICATOR_DATA );
            SetIndexBuffer( 1, g_adbHaClose, INDICATOR_DATA );

         // Set indicator name
            IndicatorSetString( INDICATOR_SHORTNAME,
               MName + "(" + DoubleToString( i_dbPeriod, 3 ) + ")" );

         return INIT_SUCCEEDED;  // Successful initialisation of indicator
      };

   // Calculation event handler
      int OnCalculate( const int      rates_total,
                       const int      prev_calculated,
                       const datetime &time[],
                       const double   &open[],
                       const double   &high[],
                       const double   &low[],
                       const double   &close[],
                       const long     &tick_volume[],
                       const long     &volume[],
                       const int      &spread[]          ) {
         // Main loop — fill in the arrays with data values
            for( int iCur  = MOnCalcStart, iPrev = MOnCalcBack( iCur, 1 );
                 !IsStopped() && MOnCalcCheck( iCur );
                 MOnCalcNext( iCur ), MOnCalcNext( iPrev ) ) {

               // Get previous values
                  double dbHaClosePrev = MOnCalcValid( iPrev ) ? g_adbHaClose[ iPrev ] : close[ iCur ],
                         dbHaOpenPrev  = MOnCalcValid( iPrev ) ? g_adbHaOpen[  iPrev ] : open[  iCur ];

               // Set buffer values
                  g_adbHaOpen[  iCur ] = dbHaOpenPrev + ( dbHaClosePrev - dbHaOpenPrev ) * g_dbAlphaWeight;
                  g_adbHaClose[ iCur ] = ( open[ iCur ] + close[ iCur ] + high[ iCur ] + low[  iCur ] )
                                       * 0.25;
            };

         return rates_total;  // Return value for prev_calculated of next call
      };

//---------------------------------------------------------------------------------------------------------------------
