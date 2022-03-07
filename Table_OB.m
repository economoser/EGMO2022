%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DESCRIPTION: Outsheet table with Oaxaca-Blinder decomposition.
%
% AUTHORS:     Niklas Engbom (New York University),
%			   Gustavo Gonzaga (PUC-Rio),
%			   Christian Moser (Columbia University),
%			   Roberta Olivieri (Cornell University).
%
% PLEASE CITE: Engbom, Niklas & Gustavo Gonzaga & Christian Moser & Roberta
%              Olivieri. "Earnings Inequality and Dynamics in the Presence
%              of Informality: The Case of Brazil," Quantitative Economics,
%              2022.
%
% TIME STAMP:  March 5, 2022.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% close all; clear all; clc
dbstop if error
try_path_1 = '/Users/niklasengbom/Dropbox/Global Income Dynamics Database Project (GIDDP)/Brazil/7_PME/output' ;
try_path_2 = '/Users/economoser/Dropbox (CBS)/Global Income Dynamics Database Project (GIDDP)/Brazil/7_PME/output'; % local (Chris' personal iMac Pro)
try_path_3 = '/Users/cm3594/Dropbox (CBS)/Global Income Dynamics Database Project (GIDDP)/Brazil/7_PME/output'; % local (Chris' work iMac Pro)
if exist(try_path_1, 'dir') % Nik personal
    directories.data = [try_path_1 '/out/'] ;
    directories.table = [try_path_1 '/tex/'];
    addpath('/Users/niklasengbom/Dropbox/Global Income Dynamics Database Project (GIDDP)/Brazil/3_code/do')
elseif exist(try_path_2, 'dir') % Chris' personal
    directories.data = [try_path_2 '/out/'] ;
    directories.table = [try_path_2 '/tex/'];
    addpath('/Users/economoser/Dropbox (CBS)/Global Income Dynamics Database Project (GIDDP)/Brazil/3_code/do')
elseif exist(try_path_3, 'dir') % Chris' work
    directories.data = [try_path_3 '/out/'] ;
    directories.table = [try_path_3 '/tex/'];
    addpath('/Users/cm3594/Dropbox (CBS)/Global Income Dynamics Database Project (GIDDP)/Brazil/3_code/do')
else
    error('\nUSER ERROR: Directory not found.\n')
end
clear try_path_1 try_path_2 try_path_3



%% TABLE XX: OAXACA-BLINDER DECOMPOSITION
% read data from stata 
data = csv2mat_numeric([directories.data 'Table_OB.out']) ;

% write table
fid = fopen([directories.table 'Table_OB.tex'],'w');
fprintf(fid,'\\begin{tabular}{l c ccc cccccc}\n');
fprintf(fid,'\\hline \\hline \n');
fprintf(fid,'&& & & & \\multicolumn{6}{c}{Composition} \\\\ \\cline{6-11} \n');
fprintf(fid,'&& Formal & Informal & Returns & Total & Age & Educ. & Gender & Industry & Occupation \\\\ \n');
fprintf(fid,'\\hline \n');
fprintf(fid,'\\\\[-.15in] \n');
fprintf(fid,'Variance of earnings changes && %4.3f & %4.3f & %4.3f & %4.3f & %4.3f & %4.3f & %4.3f & %4.3f & %4.3f \\\\ \n', ...
             data.formal,data.informal,data.returns,data.composition_all,data.composition_age_group,data.composition_edu_group,data.composition_gender,data.composition_ind_group,data.composition_occ_group);
fprintf(fid,'\\\\[.0in] \n');
output.obsmin = 'Minimum number of observations' ;
output.obsmax = 'Maximum number of observations' ;
output.obstot = 'Total number of observations' ;
for moment = fieldnames(output)'
    fprintf(fid,'%s && %s & %s \\\\ \n',output.(moment{1}),comma_separator(data.([moment{1} '1'])),comma_separator(data.([moment{1} '2']))) ;
end
fprintf(fid,'\\\\[-.15in] \n');
fprintf(fid,'\\hline\n');
fprintf(fid,'\\end{tabular}');
fclose(fid);