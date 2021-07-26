# day_ahead_market 
The GAMS model uses CPLEX solver with MIP to maximize the social surplus in the day-ahead electricity market. The market clearance is subject to the acceptance or rejection of bidding offers (maximum one offer can be accepted from each bidder) and the hourly balance of electricity supply and demand. The market exchange price is used as a parameter in the objective function with an initial dummy value
and iterated until the maximum social surplus is reached.

The bidding offers in the day-ahead electricity market include hourly, block and flexible offers. The initial hourly market clearance prices are calculated by using the hourly offers in the objective function. The block
offers are accepted in the second cycle of optimization if their prices are higher (lower) than market exchange prices for demand (supply) offers and if the offer in the previous hour has been accepted. The flexible offers are accepted in the final cycle of the optimization in the hour with maximum (minimum) market exchange price for supply (demand) offers.
