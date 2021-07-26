$title GAMS code for day-ahead electricity market simulation

$ontext
The code is written by Gorkem Gungor for day-ahead electricity market clearance using test data including 1200 MW nuclear generator.
$offtext

* Definition of sets used for reading inputs
Sets
Offer_ID        The ID number of bidders
Segment_ID       Number of bids for each bidder
Hour_ID          The period of the bid for single and block offers
Teklif_Tipi      Offer type with 'S' for single 'B' for block and 'F' for flexible
Data_File             Data with x1 for quantity of supply (negative) or demand (positive) x2 for price x3 for period and x4 for precondition of block offers
phase            Calculation of objective function for each phase /single,block,final/
;

* Data is used for reading the inputs and data_new is used for solving for each hour independently
Parameter
data(Offer_ID,Segment_ID,Hour_ID,Teklif_Tipi,Data_File)      Test data
data_new(Offer_ID,Segment_ID,Teklif_Tipi,Data_File)          Seperating data for solving each hour seperately due to program limitations
hourly(Offer_ID,Teklif_Tipi)                            Condition for selecting maximum one bid frome each bidder
PTF                      Market exchange price
PTF_old(Hour_ID)         Previous market exchange price for iteration
PTF_new(Hour_ID)         Market exhange price after block offers
PTF_final(Hour_ID)       Market exchange price after including all offers
PTF_hourly(Offer_ID,Segment_ID,Hour_ID,Teklif_Tipi)        Average market exchange price for comparing with block offers
PTF_ave(Offer_ID,Segment_ID,Teklif_Tipi)        Average market exchange price for comparing with block offers
Qs(phase,Hour_ID,Teklif_Tipi)       Total supply for each hour
Qd(phase,Hour_ID,Teklif_Tipi)       Total demand for each hour
report   Storing accepted offers for each hour
report_final     Final report for exporting to Excel
best_obj(phase)         Total social surplus from bidding;

* Definition of model paths
$setglobal       path    'D:\GAMS\'
$setglobal       Data_File    '%path%data\'
$setglobal       gdxout  '%path%gdxout\'
$setglobal       output  '%path%output\'
$setglobal       file    'data'
$setglobal       test    'C:\USERS\GGUNGOR\'

* Reading the input file and writing to gdx
$call csv2gdx %Data_File%%file%.in output=%Data_File%%file%.gdx Index=(1,2,3,4) Values=(5,6,7,8) ColCount=8 id=data autoCol=x storeZero=y
$gdxIn %Data_File%%file%.gdx
$load Offer_ID = Dim1
$load Segment_ID = Dim2
$load Hour_ID = Dim3
$load Teklif_Tipi = Dim4
$load Data_File = Dim5
* x1 is amount of electricity (positive for demand and negative for supply) and x2 is price
$load data
$gdxIn

* Variable used for selecting maximum one proposal from all IDs
Binary variable
x(Offer_ID,Segment_ID,Teklif_Tipi) choice for selecting bids;

* The social surplus received from trading
Variable
z        Social welfare;

Equations
obj
agents
balance;

Option ResLim = 100;

* Used for solving for all hours
alias(Hour_ID,Hour);

* The objective function takes maximum values for demand and negative values for supply in accordance with economics
obj..   z =e= sum[(Offer_ID,Segment_ID,Teklif_Tipi),x(Offer_ID,Segment_ID,Teklif_Tipi)*[data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x2')-PTF]*data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')];
* Maximum one offer can be accepted from all IDs
agents(Offer_ID,Teklif_Tipi)$hourly(Offer_ID,Teklif_Tipi).. sum[Segment_ID,x(Offer_ID,Segment_ID,Teklif_Tipi)$data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')] =l= 1;
* The supply for each hour must be greater than demand
balance.. sum[(Offer_ID,Segment_ID,Teklif_Tipi),data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')*x(Offer_ID,Segment_ID,Teklif_Tipi)] =e= 0;
* Market exchange price for all selected bids

Model day_ahead_market /all/;

option limrow = 1000;

* Initializing the objective function value
best_obj('single') = 0;

* Calculating for single offers
loop(Hour,
* Calculating the condition for equations related to offers of IDs
hourly(Offer_ID,'S') = sum(Segment_ID,data(Offer_ID,Segment_ID,Hour,'S','x1'));
* Reducing the parameter index of data for each hour individually
data_new(Offer_ID,Segment_ID,'S',Data_File) = data(Offer_ID,Segment_ID,Hour,'S',Data_File);
* Initial market exchange price for iteration
execseed = 1 + gmillisec(jnow);
PTF = uniform(0,1000);
Display PTF;
* First solve for the initial market exchange price
Solve day_ahead_market using mip maximizing z;
* Calculating new market exchange price for iteration
PTF_old(Hour) = PTF;
PTF = z.l/sum[(Offer_ID,Segment_ID,Teklif_Tipi),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*abs{data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')}];
* Iteration until market exchange price converges
while (abs(PTF-PTF_old(Hour))>10,
Solve day_ahead_market using mip maximizing z;
PTF_old(Hour) = PTF;
PTF = z.l/sum[(Offer_ID,Segment_ID,Teklif_Tipi),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*abs{data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')}];
Display PTF_old;
);
* Storing market exchange prices for each hour
PTF_old(Hour) = PTF;
Qs('single',Hour,Teklif_Tipi) = sum[(Offer_ID,Segment_ID),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')$(data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')<0)];
Qd('single',Hour,Teklif_Tipi) = sum[(Offer_ID,Segment_ID),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')$(data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')>0)];
* Displaying the objective value and accepted offers of IDs
best_obj('single') = best_obj('single') + z.l;
);

* Copying Hour_ID set to Time for calculating average market exchange price
alias(Hour_ID,Time);

* Initializing the objective function value
best_obj('block') = 0;

* Calculating the average market exchange prices for block offers
loop(Hour,
PTF_hourly(Offer_ID,Segment_ID,Hour,'B') = sum(Time$[Time.val le data(Offer_ID,Segment_ID,Hour,'B','x3')],PTF_old(Time)/data(Offer_ID,Segment_ID,Hour,'B','x3'));
);

PTF_ave(Offer_ID,Segment_ID,'B') = smax[Hour,PTF_hourly(Offer_ID,Segment_ID,Hour,'B')];

alias(Offer_ID,Condition);

* Including block offers
loop(Hour,
* Calculating the condition for equations related to offers of IDs
hourly(Offer_ID,'B') = sum(Segment_ID,data(Offer_ID,Segment_ID,Hour,'B','x1'));
hourly(Offer_ID,'S') = sum(Segment_ID,data(Offer_ID,Segment_ID,Hour,'S','x1'));
* Reducing the parameter index of data for each hour individually
data_new(Offer_ID,Segment_ID,'B',Data_File) = data(Offer_ID,Segment_ID,Hour,'B',Data_File);
data_new(Offer_ID,Segment_ID,'S',Data_File) = data(Offer_ID,Segment_ID,Hour,'S',Data_File);
* Initial market exchange price for iteration
PTF = PTF_old(Hour);
* First solve for the initial market exchange price
Solve day_ahead_market using mip maximizing z;
* Selecting block offer if previous offer has already been accepted and with average market exchange price
x.fx(Offer_ID,Segment_ID,'B')$data_new(Offer_ID,Segment_ID,'B','x4') = smax[Condition,x.l(Condition,Segment_ID,'B')$[Condition.val = data_new(Offer_ID,Segment_ID,'B','x4')]];
x.fx(Offer_ID,Segment_ID,'B')$data_new(Offer_ID,Segment_ID,'B','x3') = [{data_new(Offer_ID,Segment_ID,'B','x2')-PTF_ave(Offer_ID,Segment_ID,'B')}*data_new(Offer_ID,Segment_ID,'B','x1') ge 0];
* Calculating new market exchange price for iteration
PTF_new(Hour) = PTF;
PTF = z.l/sum[(Offer_ID,Segment_ID,Teklif_Tipi),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*abs{data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')}];
* Iteration until market exchange price converges
while (abs(PTF-PTF_new(Hour))>10,
Solve day_ahead_market using mip maximizing z;
PTF_new(Hour) = PTF;
PTF = z.l/sum[(Offer_ID,Segment_ID,Teklif_Tipi),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*abs{data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')}];
);
* Expanding the data to further hours for block offers
data(Offer_ID,Segment_ID,Hour+1,'B','x1')$[data(Offer_ID,Segment_ID,Hour,'B','x3')>1] = data(Offer_ID,Segment_ID,Hour,'B','x1');
data(Offer_ID,Segment_ID,Hour+1,'B','x2')$[data(Offer_ID,Segment_ID,Hour,'B','x3')>1] = data(Offer_ID,Segment_ID,Hour,'B','x2');
data(Offer_ID,Segment_ID,Hour+1,'B','x3')$[data(Offer_ID,Segment_ID,Hour,'B','x3')>1] = data(Offer_ID,Segment_ID,Hour,'B','x3')-1;
data(Offer_ID,Segment_ID,Hour+1,'B','x4')$[data(Offer_ID,Segment_ID,Hour,'B','x3')>1] = data(Offer_ID,Segment_ID,Hour,'B','x4');
* Storing market exchange prices for each hour
PTF_new(Hour) = PTF;
Qs('block',Hour,Teklif_Tipi) = sum[(Offer_ID,Segment_ID),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')$(data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')<0)];
Qd('block',Hour,Teklif_Tipi) = sum[(Offer_ID,Segment_ID),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')$(data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')>0)];
report(Offer_ID,'B',Hour)= x.l(Offer_ID,'1','B')$hourly(Offer_ID,'B')*[Hour.val-smax[Hour_ID,data(Offer_ID,'1',Hour_ID,'B','x3')]+1];
* Displaying the objective value and accepted offers of IDs
best_obj('block') = best_obj('block') + z.l;
);

* Initializing the objective function value
best_obj('final') = 0;

* Including flexible offers
loop(Hour$[[PTF_new(Hour) eq smax(Time,PTF_new(Time))] or [PTF_new(Hour) eq smin(Time,PTF_new(Time))]],
* Removing the hour information from flexible offers
data_new(Offer_ID,'1','F',Data_File)$[not x.l(Offer_ID,'1','F')] = data(Offer_ID,'1','1','F',Data_File);
data_new(Offer_ID,Segment_ID,'B',Data_File) = data(Offer_ID,Segment_ID,Hour,'B',Data_File);
data_new(Offer_ID,Segment_ID,'S',Data_File) = data(Offer_ID,Segment_ID,Hour,'S',Data_File);
* Supply offers are selected for maximum and demand offers for minimum market exchange prices
x.fx(Offer_ID,'1','F')$[data_new(Offer_ID,'1','F','x1')<0] = data_new(Offer_ID,'1','F','x3');
x.fx(Offer_ID,'1','F')$[data_new(Offer_ID,'1','F','x1')>0] = data_new(Offer_ID,'1','F','x3');
* Calculating the condition for equations related to offers of IDs
hourly(Offer_ID,'F') = data_new(Offer_ID,'1','F','x1');
hourly(Offer_ID,'B') = sum(Segment_ID,data_new(Offer_ID,Segment_ID,'B','x1'));
hourly(Offer_ID,'S') = sum(Segment_ID,data_new(Offer_ID,Segment_ID,'S','x1'));
* Initial market exchange price for iteration
PTF = PTF_new(Hour);
* First solve for the initial market exchange price
Solve day_ahead_market using mip maximizing z;
PTF_final(Hour) = PTF;
PTF = z.l/sum[(Offer_ID,Segment_ID,Teklif_Tipi),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*abs{data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')}];
* Iteration until market exchange price converges
while (abs(PTF-PTF_final(Hour))>10,
Solve day_ahead_market using mip maximizing z;
* Calculating new market exchange price for iteration
PTF_final(Hour) = PTF;
PTF = z.l/sum[(Offer_ID,Segment_ID,Teklif_Tipi),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*abs{data_new(Offer_ID,Segment_ID,Teklif_Tipi,'x1')}];
);
PTF_final(Hour) = PTF;
* Storing aggregated supply and demand for each hour
Qs('final',Hour,Teklif_Tipi) = sum[(Offer_ID,Segment_ID),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*data(Offer_ID,Segment_ID,Hour,Teklif_Tipi,'x1')$(data(Offer_ID,Segment_ID,Hour,Teklif_Tipi,'x1')<0)];
Qd('final',Hour,Teklif_Tipi) = sum[(Offer_ID,Segment_ID),x.l(Offer_ID,Segment_ID,Teklif_Tipi)*data(Offer_ID,Segment_ID,Hour,Teklif_Tipi,'x1')$(data(Offer_ID,Segment_ID,Hour,Teklif_Tipi,'x1')>0)];
report(Offer_ID,'F',Hour)= x.l(Offer_ID,'1','F')$hourly(Offer_ID,'F')*Hour.val;
);

report_final(Offer_ID) = smax[(Hour,Teklif_Tipi),report(Offer_ID,Teklif_Tipi,Hour)];

execute_unload "%gdxout%%file%_final.gdx" report_final;

execute "gdxxrw.exe epsout=0 i=%gdxout%%file%_final.gdx o=%output%%file%_final.xlsx par=report_final RDIM=1";

execute "gdxdump %gdxout%%file%_final.gdx output=%test%%file%.csv symb=report_final format=csv noHeader"
