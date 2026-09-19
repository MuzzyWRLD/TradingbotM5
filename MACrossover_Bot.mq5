#include <Trade\Trade.mqh>

input int FastMA_Period = 9;
input int SlowMA_Period = 21;
input ENUM_MA_METHOD InpMAMethod = MODE_SMA;
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE;
input double InpRiskPercent = 1.0;
input int InpStopLossPoints = 500;
input int InpTakeProfitPoints = 1500;
input ulong InpMagicNumber = 20260918;
input ulong InpDeviationPoints = 20;

CTrade trade;
int handle_ma20;
int handle_ma50;

int OnInit()
{
   if(FastMA_Period < 1 || SlowMA_Period <= FastMA_Period || InpRiskPercent <= 0.0 || InpStopLossPoints <= 0 || InpTakeProfitPoints <= 0)
   {
      return INIT_PARAMETERS_INCORRECT;
   }

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);

   handle_ma20 = iMA(_Symbol, PERIOD_CURRENT, FastMA_Period, 0, InpMAMethod, InpAppliedPrice);
   handle_ma50 = iMA(_Symbol, PERIOD_CURRENT, SlowMA_Period, 0, InpMAMethod, InpAppliedPrice);

   if(handle_ma20 == INVALID_HANDLE || handle_ma50 == INVALID_HANDLE)
   {
      if(handle_ma20 != INVALID_HANDLE) IndicatorRelease(handle_ma20);
      if(handle_ma50 != INVALID_HANDLE) IndicatorRelease(handle_ma50);
      return INIT_FAILED;
   }

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   IndicatorRelease(handle_ma20);
   IndicatorRelease(handle_ma50);
}

double CalculateLotSize(double risk_percent, int sl_points)
{
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   string currency = AccountInfoString(ACCOUNT_CURRENCY);

   bool is_cent_account = ((StringLen(currency) > 0 && StringSubstr(currency, StringLen(currency) - 1, 1) == "C") || (balance > 5000.0 && balance <= 10000.0));

   double risk_money;
   if(is_cent_account && balance < 1000.0)
   {
      risk_money = (balance * 100.0) * (risk_percent / 100.0);
   }
   else
   {
      risk_money = balance * (risk_percent / 100.0);
   }

   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(point <= 0.0 || tick_size <= 0.0 || tick_value <= 0.0) return 0.0;

   double sl_distance_price = sl_points * point;
   double sl_ticks = sl_distance_price / tick_size;
   double loss_for_one_lot = sl_ticks * tick_value;

   if(loss_for_one_lot <= 0.0) return 0.0;

   double raw_lot = risk_money / loss_for_one_lot;

   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(raw_lot <= 0.0 || min_lot <= 0.0 || max_lot <= 0.0 || step_lot <= 0.0) return 0.0;

   double final_lot = MathFloor(raw_lot / step_lot) * step_lot;

   if(final_lot < min_lot) final_lot = min_lot;
   if(final_lot > max_lot) final_lot = max_lot;

   return final_lot;
}

void OnTick()
{
   if(PositionsTotal() > 0) return;

   double ma20_werte[];
   double ma50_werte[];

   ArraySetAsSeries(ma20_werte, true);
   ArraySetAsSeries(ma50_werte, true);

   if(CopyBuffer(handle_ma20, 0, 0, 3, ma20_werte) <= 0) return;
   if(CopyBuffer(handle_ma50, 0, 0, 3, ma50_werte) <= 0) return;

   bool bullish_crossover = (ma20_werte[2] < ma50_werte[2] && ma20_werte[1] > ma50_werte[1]);
   bool bearish_crossover = (ma20_werte[2] > ma50_werte[2] && ma20_werte[1] < ma50_werte[1]);

   if(!bullish_crossover && !bearish_crossover) return;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   double lot_size = CalculateLotSize(InpRiskPercent, InpStopLossPoints);
   if(lot_size == 0.0) return;

   if(bullish_crossover)
   {
      double ask_preis = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl_preis = NormalizeDouble(ask_preis - (InpStopLossPoints * point), digits);
      double tp_preis = NormalizeDouble(ask_preis + (InpTakeProfitPoints * point), digits);
      trade.Buy(lot_size, _Symbol, ask_preis, sl_preis, tp_preis, "MA Crossover Buy");
   }
   else if(bearish_crossover)
   {
      double bid_preis = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl_preis = NormalizeDouble(bid_preis + (InpStopLossPoints * point), digits);
      double tp_preis = NormalizeDouble(bid_preis - (InpTakeProfitPoints * point), digits);
      trade.Sell(lot_size, _Symbol, bid_preis, sl_preis, tp_preis, "MA Crossover Sell");
   }
}
