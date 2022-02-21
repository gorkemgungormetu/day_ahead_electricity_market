# GAMS code for auctioning in day-ahead electricity market 
The GAMS model uses CPLEX solver with MIP to maximize the social surplus in the day-ahead electricity market. The market clearance is subject to the acceptance or rejection of bidding offers (maximum one offer can be accepted from each bidder) and the hourly balance of electricity supply and demand. The market exchange price is used as a parameter in the objective function with an initial dummy value
and iterated until the maximum social surplus is reached.

The bidding offers in the day-ahead electricity market include hourly, block and flexible offers. The initial hourly market clearance prices are calculated by using the hourly offers in the objective function. The block
offers are accepted in the second cycle of optimization if their prices are higher (lower) than market exchange prices for demand (supply) offers and if the offer in the previous hour has been accepted. The flexible offers are accepted in the final cycle of the optimization in the hour with maximum (minimum) market exchange price for supply (demand) offers.

# Day-Ahead Electricity Market Game
# Gorkem Gungor

Forecasting of the day-ahead electricity market price for each hour includes crucial information for the electricity transmission system operator for planning the grid investments. This is an example of how you can approach this kind of problem in GAMS using a CPLEX solver and a student license for non-profit usage.

## Bidding process
The simulation is based on the microeconomic theory with bidders giving demand offers at lower prices and supply offers at higher prices. The bids are identified in data file for offers numbers (i=Offer\_ID), offer segments (j=Segment\_ID), hours (k=Hour\_ID) and offer types (l=Offer\_Type). The offer numbers are unique for each bidder which can give their offers in more than one segment for certain hours using combinations of quantity (Q_ijk) and price (P_ijk). The offer quantities are given as positive for demand offers (e.g. 1000 MWh) and negative for supply offers (-1000 MWh). This is consistent with the microeconomic theory with quantity decreasing as the prices increase. 

## Singular offers
The offer types are singular (S) for each hour separately, block (B) for a group of hours with or without conditions for preceding offers and flexible (F) for acceptance in the hours with the maximum market price for supply and minimum market price for demand bids. The initial market price for each hour (PTF_n) is set as a parameter using a random number generator between 0 and 1000 US$/MWh. The binary decision variable (x_ijk) is used as the first constraint for the selection of a maximum of one offer from each bidder. The second constraint is for the electricity balance of demand and supply offers selected for each hour. The objective function (z) calculates the social surplus iteratively until the difference between the market prices of consecutive iterations reduces to less than 0.01 US¢/kWh. The results of the optimization function are used for calculating the succeeding market price (PTF_(n+1)) by dividing the social surplus by total market exchange quantity.

z=∑_ijk▒x_ijk *(P_ijk-PTF_n )*Q_ijk
s.t.∑_ijk▒x_ijk ≤1
s.t.∑_ijk▒x_ijk *Q_ijk=0
Equation 1. Optimization function

PTF_(n+1)=(z/(∑_ijk▒x_ijk *|Q_ijk | ))
while |PTF_(n+1)-PTF_n |>10
Equation 2. Iteration function

## Block offers
The block offers include additional identifiers for the duration of their validity for multiple hours (data(x3)) and the decision for preceding offer (data(x4)) for acceptance or rejection of succeeding offers. The first condition compares the price of the block offer (P_ij) with the market price averages over the validity of block offer (PTF_k) for each hour consecutively. The block offers are copied for succeeding hours if they are accepted and the duration of their validity is controlled by reducing this number with one which is used as a left-hand side condition. The block offers are removed from comparison when the duration of their validity becomes less than one. The acceptance of succeeding offers which are used as a left-hand side condition can also be subject to the acceptance of preceding offers which is used as a right-hand side condition using the binary decision variable x_ij for assignment. 

[x_ij⇔data(x3)]=[[P_ij-PTF_k ]*Q_ij≥0]
[x_ij⇔data(x4)]=[max⁡〖x_ij 〗⇔Teklif\_ID=data(x4)]
Equation 3. Block offer conditions

## Flexible offers
The flexible offers help reduce the market price peaks using supply offers and increase the market price drops using demand offers. In reality, the flexible offers are mostly from suppliers (e.g. diesel generators) which can turn on and turn off easily without severe technical constraints. The binary decision variable (x_ij) is selected for demand offers at minimum and supply offers at maximum market price.
[x_ij⇔Q_ij>0]=[data(x3)⇔PTF_n=PTF_min ]
[x_ij⇔Q_ij<0]=[data(x3)⇔PTF_n=PTF_max ]
Equation 4. Flexible offer conditions

## Give it a try!
The GAMS code and the sample data can be accessed from Github repository with GNU general public license v3.0 (https://github.com/gorkemgungormetu/day_ahead_market).
