# README for Engbom, Gonzaga, Moser, and Olivieri (2022)


## Description

This package contains all replication materials for the results presented in Engbom, Gonzaga, Moser, and Olivieri (2022). That paper is split into two parts. Part 1 of the paper is based on the administrative dataset Relação Anual de Informações Sociais (RAIS) and presents standardized statistics pertaining to earnings inequality and dynamics in Brazil between 1985 and 2018. Part 2 of the paper is based on the household survey data Pesquisa Mensal de Emprego (PME) and presents an in-depth analysis of earnings inequality and dynamics for workers in Brazil's formal and informal labor markets as well switchers between the two sectors between 2002 and 2015. Each of the two parts of the paper has associated with it a separate set of codes, which are made available as part of this replication package.


## Data Files

The first part of the paper is based on the administrative dataset RAIS. For a detailed description of the RAIS data, see http://www.rais.gov.br/sitio/sobre.jsf and https://basedosdados.org/dataset/br-me-rais. Due to their confidential nature, the RAIS data are exempt from the disclosure requirements at Quantitative Economics. The interested researcher may submit an academic research proposal to the Brazilian Ministry of the Economy to obtain access to the RAIS data.

The second part of the paper is based on the household survey dataset PME. For a detailed description of the PME data, see https://www.ibge.gov.br/estatisticas/sociais/trabalho/9180-pesquisa-mensal-de-emprego.html and https://basedosdados.org/dataset/pesquisa-mensal-de-empregos-pme. The interested researcher may download the PME data directly at https://www.ibge.gov.br/estatisticas/sociais/trabalho/9180-pesquisa-mensal-de-emprego.html?=&t=microdados.


## Code Files

###### Part 1

- \_MASTER\_GIDDP\_BRA\_Part\_1.do: Master file for Part 1 of Global Income Dynamics Database Project: Brazil.

- 0\_Initialize.do: Initializes program by creating global macros.

- 1\_Gen\_Base\_Sample.do: Generate base sample.

- 2\_DescriptiveStats.do: Compute descriptive statistics.

- 3\_Inequality.do: Compute statistics pertaining to inequality.

- 4\_Volatility.do: Compute statistics pertaining to volatility.

- 5\_Mobility.do: Compute statistics pertaining to mobility.

- 6\_Insheeting\_datasets.do: Generate data files to be uploaded to GIDDP website.

- 7\_Paper\_Figs.do: Produce figures to be included in paper.

- 8\_background\_figures.do: Produce figures to be included in paper.

- 9\_other\_stats.do: Produce figures specific to Part B (formal vs. informal earnings inequality and dynamics) of the GIDP project for Brazil.

- myplots.do: Contains user-written plots.

- myprogs.do: Contains user-written programs.

- comma\_separator.m: Adds a commpa separator between thousands.

- csv2mat\_block.m: Reshapes comma-separated values file into block data structure.

- csv2mat\_numeric.m: Reshapes comma-separated values file into numeric data structure.

- Table\_OB.m: Outsheet table with Oaxaca-Blinder decomposition.

###### Part 2

- \_MASTER\_GIDDP\_BRA\_Part\_2.do: Master file for Part 2 of Global Income Dynamics Database Project: Brazil.

- 10\_initialize\_PME.do: Initializes program by creating global macros.

- 11\_createpanel.do: Clean the raw PME data and create a panel at the level of survey, using Data Zoom routines created by PUC-Rio with support from FINEP.

- 12\_repRAIS.do: Creates and compute statistics of the formal sector replicating RAIS based on PME microdata.

- 13\_computepanel.do: Creates and computes statistics at the year-individual level based on PME microdata.

- 14\_formal\_informal.do: Investigates formal-informal transitions in Brazil based on PME microdata.

- 15\_shiftshare.do: Do a shift-share analysis with Brazil sectoral transition data based on PME microdata.

- progs\_figs.do: Contains user-written programs for 13\_computepanel.do.

- progs\_repRAIS: Contains user-written programs for 12\_repRAIS.do.


## Acknowledgements

We thank the Labor Statistics Dissemination Program within the Brazilian Ministry of the Economy and the Brazilian Institute of Geography and Statistics for providing us with data access. We gratefully acknowledge the use of data cleaning procedures for the PME household survey data that we obtained from the Data Zoom initiative by the Department of Economics at PUC-Rio. Access to Data Zoom is free and open to the public at http://www.econ.puc-rio.br/datazoom/english/index.html. We also gratefully acknowledge the use of codes generously provided by Serdar Ozkan and Sergio Salgado as part of the analysis in Halvorsen, Ozkan, and Salgado (2022) and also used in other country analyses as part of the Global Income Dynamics Database Project. The project's master codes are publicly available as part of a GitHub repository of Sergio Salgado at https://github.com/salga010/QE-MasterCode.


## References

Engbom, Niklas & Gustavo Gonzaga & Christian Moser & Roberta Olivieri. "Earnings Inequality and Dynamics in the Presence of Informality: The Case of Brazil," Quantitative Economics, 2022.

Halvorsen, Elin & Serdar Ozkan & Sergio Salgado. "Earnings Dynamics and Its Intergenerational Transmission: Evidence from Norway," Quantitative Economics, 2022.
