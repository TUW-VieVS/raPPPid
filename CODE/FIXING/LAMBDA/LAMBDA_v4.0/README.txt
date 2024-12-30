The Least-squares AMBiguity Decorrelation Adjustment method,	|
LAMBDA toolbox, Version v4.0, MATLAB implementation. 		|
----------------------------------------------------------------|
Copyright: Geoscience & Remote Sensing department @ TUDelft 	|
Contact email:  LAMBDAtoolbox-CITG-GRS@tudelft.nl		|
----------------------------------------------------------------/
Last update: 01-06-2024
________________________________________________________________________________
1 - Main MATLAB routines:

	LAMBDA.m 			| Replaces    LAMBDA 3.0 (2012)
	Ps_LAMBDA.m			| Replaces Ps-LAMBDA 1.0 (2013)
________________________________________________________________________________
2 - Main LAMBDA documents:

	LAMBDA - Documentation.pdf	| LAMBDA 4.0 Documentation
	LAMBDA - UM for MATLAB.pdf	| LAMBDA 4.0 User Manual (MATLAB)
________________________________________________________________________________
3 - Main LAMBDA functionalities:

	Accessible by using << addpath('LAMBDA_toolbox') >>

> Decorrelation	   
	decorrelateVC.m           	| Used in LAMBDA.m / Ps_LAMBDA.m 	
	decomposeLtDL.m         	| Used in LAMBDA.m / Ps_LAMBDA.m
	transformZ.m  			| Used in LAMBDA.m / Ps_LAMBDA.m
			
> Estimation
	estimatorIR.m                 |1| Used in LAMBDA.m / Ps_LAMBDA.m
	estimatorIB.m                 |2| Used in LAMBDA.m / Ps_LAMBDA.m
	estimatorILS.m                |3| Used in LAMBDA.m / Ps_LAMBDA.m
	estimatorILS_enum.m           |4| Used in LAMBDA.m
	estimatorPAR.m                |5| Used in LAMBDA.m 
	estimatorVIB.m                |6| Used in LAMBDA.m / Ps_LAMBDA.m
	estimatorIA_FFRT.m            |7| Used in LAMBDA.m
	estimatorIAB.m                |8| Used in LAMBDA.m
	estimatorBIE.m                |9| Used in LAMBDA.m
	
> Evaluation
	computeSR_IBexact.m           |1| Used in LAMBDA.m / Ps_LAMBDA.m
	computeSR_ADOPapprox.m        |2| Used in          / Ps_LAMBDA.m
	computeSR_LB_Variance.m       |3| Used in          / Ps_LAMBDA.m
	computeSR_UB_ADOP.m           |4| Used in          / Ps_LAMBDA.m
	computeSR_LB_Eigenvalue.m     |5| Used in          / Ps_LAMBDA.m
	computeSR_UB_Eigenvalue.m     |6| Used in          / Ps_LAMBDA.m
	computeSR_LB_Pullin.m         |7| Used in          / Ps_LAMBDA.m
	computeSR_UB_Pullin.m         |8| Used in          / Ps_LAMBDA.m
	computeSR_Numerical.m         |9| Used in          / Ps_LAMBDA.m

> Auxiliary
	checkMainInputs.m          	| Used in LAMBDA.m / Ps_LAMBDA.m
	computeADOP.m           	| Used in          / Ps_LAMBDA.m
	computeFFRTcoeff.m    		| Needed for estimatorIA_FFRT.m	
	computeIGT_row.m    		| Needed for transformZ.m
	computeInitialEllipsoid.m  	| Needed for estimatorILS_enum.m
	computeNumSamples.m     	| Needed for computeSR_Numerical.m
________________________________________________________________________________
4 - Some MATLAB examples:

	Accessible in the folder 'LAMBDA_examples'
		
	MODEL_GeometryFree.m		| Generates GNSS geometry-free models
	RUN_example_1.m			| Example #1 for LAMBDA 4.0 toolbox
	RUN_example_2.m			| Example #2 for LAMBDA 4.0 toolbox
	RUN_example_3.m			| Example #3 for LAMBDA 4.0 toolbox
	RUN_example_X.m			| Template for creating new examples
________________________________________________________________________________
5 - Some LAMBDA literature:

	Provided in the folder 'LAMBDA_papers' in Portable Document Format (PDF)
________________________________________________________________________________