ifm_r
=====

Code for incidence function model simulation

In the data folder there is everything that is needed to simulate occupancies for marsh tit within Nottingham, UK. Species occupancy data are downscaled from Nottinghamshire Birdwatchers (see [here](https://github.com/laurajanegraham/downscaling) for downscaling code). These data were downscaled using the area-weighted method. Habitat scenario maps were created using `create.scenarios.R` on Land Cover Map 2007 and then `create_scenario_shapes.py` on the output; the latter code creates species specific maps.

To simulate species occupancies, run `run.scenario.sims.R`. 
