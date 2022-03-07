function [commaFormattedString] = comma_separator(value) % Takes a number and inserts commas for the thousands separators.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DESCRIPTION: Adds a commpa separator between thousands.
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


  [integerPart, decimalPart]=strtok(num2str(value),'.'); % Split into integer part and fractional part.
  integerPart=integerPart(end:-1:1); % Reverse the integer-part string.
  integerPart=[sscanf(integerPart,'%c',[3,inf])' repmat(',',ceil(length(integerPart)/3),1)]'; % Insert commas every third entry.
  integerPart=integerPart(:)'; 
  integerPart=deblank(integerPart(1:(end-1))); % Strip off any trailing commas.
  commaFormattedString = [integerPart(end:-1:1) decimalPart]; % Piece the integer part and fractional part back together again.
end