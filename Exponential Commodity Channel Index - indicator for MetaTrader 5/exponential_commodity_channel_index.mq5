//---------------------------------------------------------------------------------------------------------------------
#define     MName          "Exponential Commodity Channel Index"
#define     MVersion       "1.0"
#define     MBuild         "2023-04-15 15:47 WEST"
#define     MCopyright     "Copyright \x00A9 2023, Fernando M. I. Carreiro, All rights reserved"
#define     MProfile       "https://www.mql5.com/en/users/FMIC"
//---------------------------------------------------------------------------------------------------------------------
#property   strict
#property   version        MVersion
#property   description    MName
#property   description    "An implementation of the Commodity Channel Index using exponential moving averages,"
#property   description    "instead of simple moving averages as implemented by the its creator, Donald Lambert."
#property   description    "MetaTrader Indicator (Build "MBuild")"
#property   copyright      MCopyright
#property   link           MProfile
//---------------------------------------------------------------------------------------------------------------------

//--- Setup

   #property indicator_separate_window

   // Define number of buffers and plots
      #define MPlots    1
      #define MBuffers  3
      #ifdef __MQL4__
         #property indicator_buffers         MPlots
      #else
         #property indicator_buffers         MBuffers
         #property indicator_plots           MPlots
         #property indicator_applied_price   PRICE_TYPICAL
      #endif
   // Display properties for plots
      #property   indicator_label1        "ECCI"
      #property   indicator_type1         DRAW_LINE
      #property   indicator_style1        STYLE_SOLID
      #property   indicator_width1        1
      #property   indicator_color1        C'38,166,154'
   // Display levels for plots
      #property   indicator_level1         100
      #property   indicator_level2        -100
      #property   indicator_levelstyle    STYLE_DOT

//--- Parameter settings

   input double                  i_dbAveragingPeriod     = 14;             // Averaging period
   input double                  i_dbAdjustmentConstant  = 0.015;          // Adjustment constant
   #ifdef __MQL4__
      input ENUM_APPLIED_PRICE   i_ePriceApplied         = PRICE_TYPICAL;  // Applied price
   #endif

//--- Macro definitions

   // Define OnCalculate loop sequencing macros
      #define MOnCalcPrevTest ( prev_calculated < 1 || prev_calculated > rates_total )
      #ifdef __MQL4__   // for MQL4 (as series)
         #define MOnCalcNext(  _index          ) ( _index--             )
         #define MOnCalcBack(  _index, _offset ) ( _index + _offset     )
         #define MOnCalcCheck( _index          ) ( _index >= 0          )
         #define MOnCalcValid( _index          ) ( _index < rates_total )
         #define MOnCalcStart \
            ( rates_total - ( MOnCalcPrevTest ? 1 : prev_calculated ) )
      #else             // for MQL5 (as non-series)
         #define MOnCalcNext(  _index          ) ( _index++             )
         #define MOnCalcBack(  _index, _offset ) ( _index - _offset     )
         #define MOnCalcCheck( _index          ) ( _index < rates_total )
         #define MOnCalcValid( _index          ) ( _index >= 0          )
         #define MOnCalcStart \
            ( MOnCalcPrevTest ? 0 : prev_calculated - 1 )
      #endif
   // Define applied price macro (MQL4 only)
      #ifdef __MQL4__
         #define MSetAppliedPrice( _type, _where, _index ) { switch( _type ) {                                \
            case PRICE_WEIGHTED: _where = ( high[ _index ] + low[ _index ] + close[ _index ]                  \
                                                                           + close[ _index ] ) * 0.25; break; \
            case PRICE_TYPICAL:  _where = ( high[ _index ] + low[ _index ] + close[ _index ] ) / 3.0;  break; \
            case PRICE_MEDIAN:   _where = ( high[ _index ] + low[ _index ]                   ) * 0.5;  break; \
            case PRICE_HIGH:     _where = high[  _index ];                                             break; \
            case PRICE_LOW:      _where = low[   _index ];                                             break; \
            case PRICE_OPEN:     _where = open[  _index ];                                             break; \
            case PRICE_CLOSE:                                                                                 \
            default:             _where = close[ _index ];                                                 }; }
      #endif
   // Define macro for calculating and assigning exponential moving average
      #define MCalcEma( _var, _value, _weight ) \
         _var = _var##Prev + ( ( _value ) - _var##Prev ) * ( _weight )
   // Define macro for invalid parameter values
      #define MCheckParameter( _condition, _text ) if( _condition ) \
         { Print( "Error: Invalid ", _text ); return INIT_PARAMETERS_INCORRECT; }

//--- Global variable declarations

   // Indicator buffers
      double      g_adbPriceAverage[],             // Buffer for average of price
                  g_adbDeviationAverage[],         // Buffer for average of absolute deviation
                  g_adbCCI[];                      // Buffer for commodity channel index

   // Miscellaneous global variables
      double      g_dbEmaWeight;                   // Weight to be used for exponential moving averages

//--- Event handling functions

   // Initialisation event handler
      int OnInit(void) {
         // Validate input parameters
            MCheckParameter( i_dbAveragingPeriod    < 1.0,         "averaging period"    );
            MCheckParameter( i_dbAdjustmentConstant < DBL_EPSILON, "adjustment constant" );
         // Calculate EMA alpha weight for Wilder's moving average, also known as smoothed moving average (SMMA)
            g_dbEmaWeight = 2.0 / ( i_dbAveragingPeriod + 1.0 );
         // Set number of significant digits (precision)
            IndicatorSetInteger( INDICATOR_DIGITS, _Digits );
         // Set buffers
            int iBuffer = 0;
            #ifdef __MQL4__
               IndicatorBuffers( MBuffers + 1 );                     // Set total number of buffers (MQL4 Only)
            #endif
            SetIndexBuffer(    iBuffer++, g_adbCCI,               INDICATOR_DATA         );  // Commodity channel index
            SetIndexBuffer(    iBuffer++, g_adbPriceAverage,      INDICATOR_CALCULATIONS );  // Price average
            SetIndexBuffer(    iBuffer++, g_adbDeviationAverage,  INDICATOR_CALCULATIONS );  // Absolute deviation average
         // Set indicator name and plot label
            #define MNameLabel( _prefix ) \
               StringFormat( _prefix " ( %.1f, %.3f )", i_dbAveragingPeriod, i_dbAdjustmentConstant )
            string sName  = MNameLabel( MName             ),
                   sLabel = MNameLabel( indicator_label1  );
            IndicatorSetString( INDICATOR_SHORTNAME, sName );
            #ifdef __MQL4__
               SetIndexLabel(      0,             sLabel );
            #else
               PlotIndexSetString( 0, PLOT_LABEL, sLabel );
            #endif

         return INIT_SUCCEEDED;  // Successful initialisation of indicator
      };

   // Calculation event handler
      #ifdef __MQL4__
         int OnCalculate( const int rates_total, const int prev_calculated, const datetime &time[],
                          const double &open[], const double &high[], const double &low[], const double &close[],
                          const long &tick_volume[], const long &volume[], const int &spread[] ) {
      #else
         int OnCalculate( const int rates_total, const int prev_calculated,
                          const int begin, const double& price[] ) {
      #endif
         // Main loop: calculate values and apply data to buffers
            for( int iCur = MOnCalcStart, iPrev = MOnCalcBack( iCur, 1 );
                 !IsStopped() && MOnCalcCheck( iCur ); MOnCalcNext( iCur ), MOnCalcNext( iPrev ) ) {
               // Get (or calculate) current applied price
                  #ifdef __MQL4__
                     double dbPriceCur;
                     MSetAppliedPrice( i_ePriceApplied, dbPriceCur, iCur );
                  #else
                     double dbPriceCur = price[ iCur ];
                  #endif
               // Calculate the remaining values
                  double dbPriceAverage, dbDeviationAverage, dbCCI;
                  if( MOnCalcValid( iPrev ) ) {
                     // Calculate price average
                        double dbPriceAveragePrev = g_adbPriceAverage[ iPrev ];
                        MCalcEma( dbPriceAverage, dbPriceCur, g_dbEmaWeight );
                     // Calculate deviation and its absolute average
                        double dbDeviation            = dbPriceCur - dbPriceAverage,
                               dbDeviationAveragePrev = g_adbDeviationAverage[ iPrev ];
                        MCalcEma( dbDeviationAverage, fabs( dbDeviation ), g_dbEmaWeight );
                     // Calculate commodity channel index
                        dbCCI = dbDeviationAverage > DBL_EPSILON
                              ? dbDeviation / ( dbDeviationAverage * i_dbAdjustmentConstant )
                              : ( dbDeviation > 0.0 ? DBL_MAX : -DBL_MAX );
                  } else {
                     dbPriceAverage     = dbPriceCur;
                     dbDeviationAverage =
                     dbCCI              = 0.0;
                  };
               // Set buffer values
                  g_adbCCI[              iCur ] = dbCCI;
                  g_adbPriceAverage[     iCur ] = dbPriceAverage;
                  g_adbDeviationAverage[ iCur ] = dbDeviationAverage;
            };
         return rates_total;  // Return value for prev_calculated of next call
      };

//---------------------------------------------------------------------------------------------------------------------
