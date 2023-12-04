# LeadScreeningKitValidation
Contains a MATLAB script that supports a submitted manuscript that compares lead concentration in household samples to the respective EPA limits. Also contains an R script that performs principal component analysis. Scripts were written in MATLAB R2022a + Text Analytics Toolbox and RStudio Version 2022.12.0+353 on Mac OS 13.5.2.

# List of Files
Redacted LIRA.pdf - A lead inspection and risk assessment (LIRA) report in pdf form. Contains the lead concentrations of samples analyzed by a licensed inspector within a home. Identifying information of home is redacted.

Redacted LSK.docx - A lead screening kit report in docx form. Contains the lead concentrations of samples collected by residents and analyzed at Notre Dame. Identifying information of home is redacted.

LRA_LSK_ForPublication.m - MATLAB script that pulls in Redacted LIRA.pdf and Redacted LSK.doc and extracts sample names, locations, concentrations and units from files. Then compares extracted values to the respective EPA values and generates string array variables that may be found in the workspace. User is responsible for outputting values to spreadsheet program.

LIRA_LSK_Validation_Pub.xlsx - An xlsx file in which string array variables generated from LRA_LSK_ForPublication.m are compiled. Also contains data analysis of the 107 homes that had screening kits and LIRAs performed to determine the rate at which the kit and LIRA agree on presence of lead hazards.

PCA_Bins_29May23.xlsx - An xlsx file containing bin values of all samples types (street soil, yard soil, dripline soil, exterior paint, interior paint, threshold dust, old dust, windowsill dust) for 402 homes. Bins values were used to minimize the effect of very highly leaded samples on the PCA and were assigned as a proportion of the EPA limit (bin 1 = 0-0.49 x respective EPA limit, bin 2 = 0.5-0.99 x EPA limit, bin 3 = 1.0-1.49 x EPA limit ... bin 7 = >3.5x EPA limit). 

PCACluster_pub.R - R script that pulls in PCA_Bins_29May23.xlsx and performs principal component analysis and cluster analysis. 

# Usage of Scripts
LRA_LSK_ForPublication.m already references the document and should just be run. The following objects are generated and should be copied into an Excel sheet (as shown in LIRA_LSK_Validation_Pub.xlsx) for further analysis:

_locquanthaz_ - An n by 5 string array where the columns correspond to: general sample location, detailed sample location, lead concentration in sample, quantitation units, and Y/N on whether the sample concentration is over the respective EPA limit. Compiles the information for all samples analyzed in the LIRA.

_tableandhaz_ - An 8 by 5 string array where the columns correspond to: sample type, lead concentration in sample, quantitation units, sample location, and Y/N on whether the sample concentration is over the respective EPA limit. Compiles the information for all 8 samples analyzed with the lead screening kit.


PCACluster_pub.R already references the document and should just be run. The following generated figures were used in the analysis:

_ggcorrplot_ - Displays the correlation matrix in a grid. Boxes on the grid correspond to the correlation between two sample types and is color-coded using the color gradient scale to show the correlation value.

_fviz_eig_ - Displays the scree plot in a bar graph. The scree plot shows the percentage of explained variance in each of the PCA dimensions.

_fviz_pca_var_ - Displays the graph of the PCA variables.

_fviz_nbclust_ - Displays a line graph to determine the optimal number of clusters by plotting the average silhouette width against the number of clusters. 

_pam1_ - Displays the PCA overlaid with color-coded clusters.

_fig6_ - Displays a traceable PCA color-coded by the sample types that showed lead hazards for that home.








