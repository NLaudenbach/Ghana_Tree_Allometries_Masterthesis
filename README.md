# **Comparison and Development of Tree Height and Biomass Allometries Based on Terrestrial Laser Scanning Data of Forests in Ghana**
## Evaluation of Existing Allometric Models and Development of Ghana-Specific Height and Biomass Relationships


Author: Nils L. Laudenbach  
Department of Remote Sensing, University of Potsdam, 14476 Potsdam, Germany  
Project: Master’s Thesis  


### Background

Tree height and aboveground biomass are key parameters for studying forest structure, productivity and carbon storage. Since both variables are difficult to measure directly, they are commonly estimated using allometric equations based on more accessible tree parameters such as diameter at breast height, tree height and wood density.

Although several pantropical and African allometries are available, their accuracy may vary between regions because they cannot fully represent local differences in climate, species composition and forest structure. This is particularly relevant for Ghana, where locally calibrated allometric models remain limited.


### Project

The aim of this project is to evaluate the suitability of established tree height and biomass allometries for forests in Ghana and to develop new Ghana-specific models.

Terrestrial laser scanning data are used to generate detailed three-dimensional point clouds of individual trees. From these point clouds, structural tree parameters such as diameter at breast height, total tree height and woody volume are derived. Aboveground woody biomass is estimated by combining TLS-derived volume with species-specific wood density.

The TLS-derived measurements serve as reference data for evaluating existing pantropical and African allometric equations. The comparison focuses mainly on models developed by Chave et al. (2014), Djomo et al. (2016) and Terryn et al. (2024). Model performance is assessed using statistical measures such as RMSE, relative error, bias, R² and the Concordance Correlation Coefficient.

In addition, new allometric models for tree height and aboveground biomass are developed using the Ghanaian TLS dataset. Besides diameter, potential explanatory variables include wood density, climate, forest type, competition and other structural or environmental parameters.


### Study Areas

The study is based on six one-hectare forest plots located in three regions of Ghana:

- Ankasa Conservation Area
- Bobiri Forest Reserve and Butterfly Sanctuary
- Kogyae Strict Nature Reserve

The plots represent wet evergreen forest, moist semi-deciduous forest, dry semi-evergreen forest, wooded savanna and a forest–savanna transition zone.

### Data

The study is based on terrestrial laser scanning data from six one-hectare plots in Ghana. The TLS data were acquired using RIEGL VZ-400i and RIEGL VZ-600i laser scanners. Multiple scan positions were used within each plot to produce dense three-dimensional point clouds of the forest structure.

Additional forest inventory data provided by the Forestry Research Institute of Ghana are used to assign information such as tree ID, species and condition to the segmented trees. Species-specific wood density values are obtained from various Wood Denisty Databases. Environmental and site-related variables include precipitation, temperature, drought stress, elevation and soil conditions.


### Workflow

The main processing and analysis steps include:

1. Registration and filtering of terrestrial laser scanning data
2. Segmentation of individual trees
3. Matching TLS trees with stem maps and forest inventory data
4. Extraction of diameter and tree height
5. Reconstruction of Quantitative Structure Models
6. Estimation of woody volume and aboveground biomass
7. Comparison of existing allometric equations
8. Development and cross-validation of Ghana-specific models


### Main Tools

- R and RStudio
- Python and Jupyter Notebook
- RayCloudTools
- CloudCompare
- ITSMe
- RiSCAN PRO
