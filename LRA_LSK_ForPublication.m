%% Extracting Data from LRA
str = extractFileText("Redacted LIRA.PDF");
T = readtable('Redacted LSK.docx');

str = strsplit(str,'\n')'; % splits report by line

str = str(1:find(contains(str, "LEAD HAZARD LEVELS")));  % cuts off the last 8 pages of reference

mask1 = contains(str,["mg/cm2" "ppm" "ug/ft2" "mg/Kg"]); % logical that determines which lines contain the listed units (0 or 1)
mask2 = contains(str,'Component Location'); % logical that determines which lines contain component location (0 or 1)
mask3 = contains(str,"(in ug/ft2)");

locations = str(mask2); % retrieves the lines containing location as string
pairing_loc = find(mask2); % records the line number of the locations
del_quant = find(mask3);
str_quantities = str(mask1); % retrieves the line containing the quantities
pairing_quant = find(mask1); % records the line number of the quantities
pairing_quant(ismember(pairing_quant,del_quant)) = []; % removes where ug/ft2 is present without a numerical value in front

pairlendiff = length(pairing_loc)-length(pairing_quant);

if pairlendiff>0
    pairing_quant = [pairing_quant; ones(pairlendiff,1)];
end
if pairlendiff<0
    pairing_loc = [pairing_loc; ones(pairlendiff,1)];
end

pairing_collect = [pairing_loc,pairing_quant]; % brings two columns of line location info together

for i = 1:height(pairing_loc) % identifies instances where a location doesn't match with a quantification
    if pairing_loc(i) == 0
        continue
    end
    if pairing_quant(i) - pairing_loc(i) > 14
        pairing_loc(i) = 0;
        i = 0;
    end
end

pairing_collect1 = [pairing_loc,pairing_quant];
loc = [pairing_loc, locations];

for i = 1:height(loc)
    if pairing_loc(i) == 0
       locations(i) = [];
    end
end


quantities = {height(str_quantities),2}; % creates cell (1x2) with first value the number of the quantites found, and the second 2

for i = 1:height(locations)
    tempstr = strsplit(locations(i,1), '-'); % splits string at - and places each of the three components in separate columns
    locations(i,1) = erase(tempstr(1,2), "Type "); % removes the word Type inserts this string in the first column of the locations string
    locations(i,2) = tempstr(1,3); % places the corresponding sample location in the second column of locations string
end

for i = 1:height(str_quantities)
    tempstr = strsplit(str_quantities(i,1), ' '); % splits string at spaces and places each component in separate columns
    if ~isnan(str2double(tempstr(1,end-1))) % removes anywhere where the units are present without a value 
        quantities{i,1} = str2double(tempstr(1,end-1));
        quantities{i,2} = tempstr(1,end);
    end
end


quantities = quantities(~cellfun(@isempty, quantities(:,1)), :); % returns 8x2 cell with 1st column double and second column string of units


locandquants = [locations,quantities];


%% Determining if Over EPA Limit

sz = [3 4];
varTypes = ["string","categorical","categorical","categorical"];
varNames = ["Sample Type","LRA Hazard","LSK Hazard", "Agreement"];

comparison = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

LRAhaz = "empty" + strings(height(locandquants),1);

for i = 1:height(locandquants)
    % paint
    if locandquants(i,4) == "mg/cm2"
        if str2double(locandquants(i,3)) > 1
            LRAhaz(i) = "Yes";
        else
            LRAhaz(i) = "No";
        end
    end
    
    % soil
    if locandquants(i,4) == "ppm" || locandquants(i,4) == "mg/Kg"

        if  contains(locandquants(i,1),"Play") || contains(locandquants(i,2),"Play")
            if str2double(locandquants(i,3)) > 400
                LRAhaz(i) = "Yes";
            else
                LRAhaz(i) = "No";
            end
        else 
            if str2double(locandquants(i,3)) > 1200
                LRAhaz(i) = "Yes";
            else
                LRAhaz(i) = "No";
            end
        end
    end

    % dust --> New EPA limits Dec 2020 floor: 10 ug/ft2, window sill: 100
    % ug/ft2
     if locandquants(i,4) == "ug/ft2" 

        if  contains(locandquants(i,1),"Sill") || contains(locandquants(i,2),"Sill")
            if str2double(locandquants(i,3)) > 100
                LRAhaz(i) = "Yes";
            else
                LRAhaz(i) = "No";
            end
        end
        if contains(locandquants(i,1),"Floor") || contains(locandquants(i,2),"Floor")
            if str2double(locandquants(i,3)) > 10
                LRAhaz(i) = "Yes";
            else
                LRAhaz(i) = "No";
            end
        end
    end
end

locquanthaz = [locandquants,LRAhaz]

%% Summary of Types
sampletype = ["Soil - Play Area";"Soil - Overall";"Paint";...
    "Dust - Floor"; "Dust - Window Sill"; "Dust - Overall"];
hazsum = "empty" + strings(height(sampletype),1);
summary = [sampletype,hazsum];
summary(1,2) = 'N/A';
summary(4,2) = 'N/A';
summary(5,2) = 'N/A';

for i = 1:height(locquanthaz)
    % paint
    if locquanthaz(i,4) == "mg/cm2" && locquanthaz(i,5) == "Yes"
        summary(3,2) = "Yes";
    % soil
    elseif contains(locquanthaz(i,1),"Play") && locquanthaz(i,4) == "ppm"...
            && locquanthaz(i,5) == "Yes"|| contains(locquanthaz(i,1),"Play") ...
            && locquanthaz(i,4) == "mg/Kg" && locquanthaz(i,5) == "Yes"
        summary(1,2) = "Yes";
    elseif contains(locquanthaz(i,1),"Play") && locquanthaz(i,4) == "ppm"...
            && locquanthaz(i,5) == "No" && summary(1,2)~= "Yes"|| ... 
            contains(locquanthaz(i,1),"Play") && locquanthaz(i,4) == ...
            "mg/Kg" && locquanthaz(i,5) == "No" && summary(1,2)~= "Yes"
        summary(1,2) = "No";
    elseif locquanthaz(i,4) == "ppm" && locquanthaz(i,5) == "Yes"|| locquanthaz(i,4) == "mg/Kg" && locquanthaz(i,5) == "Yes"
        summary(2,2) = "Yes";
    % dust
    elseif locquanthaz(i,4) == "ug/ft2"  && locquanthaz(i,5) == "Yes"...
            && contains(locquanthaz(i,2),"Sill") || locquanthaz(i,4) == ...
            "ug/ft2"  && locquanthaz(i,5) == "Yes" && contains...
            (locquanthaz(i,2),"sill")
        summary(5,2) = "Yes";
        summary(6,2) = "Yes";
    elseif locquanthaz(i,4) == "ug/ft2"  && locquanthaz(i,5) == "No"...
            && contains(locquanthaz(i,2),"Sill") || locquanthaz(i,4) == ...
            "ug/ft2"  && locquanthaz(i,5) == "No" && contains...
            (locquanthaz(i,2),"sill")
        summary(5,2) = "No";
    elseif locquanthaz(i,4) == "ug/ft2"  && locquanthaz(i,5) == "Yes"
        summary(4,2) = "Yes";
        summary(6,2) = "Yes";
    elseif locquanthaz(i,4) == "ug/ft2"  && locquanthaz(i,5) == "No"
        summary(4,2) = "No";
    else 
        continue
    end
end

newsummary = strrep(summary, 'empty','No');
% May be an issue in that it defaults the answer in the chart to the last
% entry of that type in the locquanthaz

%% Extracting Data from Kit

%str = extractFileText("817 S 32nd St Report.docx");

% T = readtable('Reports/1229 Longfellow.docx');
A = table2array(T);

Samplecolumn = A(:,1);
Sample = Samplecolumn(2:end);


LeadConccol = A(:,2);
LeadConcStr = LeadConccol(2:end);
LeadConcStr(LeadConcStr == "n/a") = "0 n/a";

newLead = split(LeadConcStr," ");
LeadConc = newLead(:,1);
LeadUnits = newLead(:,2);


Locationcol = A(:,3);
Location = Locationcol(2:end);


AllDataNewFormat = [Sample,LeadConc,LeadUnits,Location];



%% Determining if Over EPA Limit - Kit

kithaz = "empty" + strings(height(AllDataNewFormat)-1,1);

for i = 1:height(AllDataNewFormat)-1
    if contains(AllDataNewFormat(i,1),"Paint")
        if str2double(AllDataNewFormat(i,2)) > 5000
            kithaz(i) = "Yes";
%         elseif contains(AllDataNewFormat(i,2),"0 n/a")
%             kithaz(i) = "N/A"
        else
            kithaz(i) = "No";
        end
    end
    
    if contains(AllDataNewFormat(i,1),"Soil")

        if  contains(AllDataNewFormat(i,4),"Play") || contains(AllDataNewFormat(i,4),"play")
            if str2double(AllDataNewFormat(i,2)) > 400
                kithaz(i) = "Yes";
            else
                kithaz(i) = "No";
            end
        else 
            if str2double(AllDataNewFormat(i,2)) > 1200
                kithaz(i) = "Yes";
            else
                kithaz(i) = "No";
            end
        end
    end

     if contains(AllDataNewFormat(i,1),"Dust") 

        if  contains(AllDataNewFormat(i,4),"Sill") || contains(AllDataNewFormat(i,4),"sill")
            if str2double(AllDataNewFormat(i,2)) > 230
                kithaz(i) = "Yes";
            else
                kithaz(i) = "No";
            end
        else
            if str2double(AllDataNewFormat(i,2)) > 20
                kithaz(i) = "Yes";
            else
                kithaz(i) = "No";
            end
        end
        
    end
end

AllDataNewFormat1 = AllDataNewFormat;
AllDataNewFormat1(end,:) = [];
tableandhaz = [AllDataNewFormat1,kithaz]

%% Summary of Types
sampletype = ["Soil - Play Area";"Soil - Overall";"Paint";...
    "Dust - Floor"; "Dust - Window Sill"; "Dust - Overall"];
kithazsum = "empty" + strings(height(sampletype),1);
kitsummary = [sampletype,kithazsum];
kitsummary(1,2) = 'N/A';
kitsummary(4,2) = 'N/A';
kitsummary(5,2) = 'N/A';

for i = 1:height(AllDataNewFormat1)
    
    % paint
    if contains(tableandhaz(i,1),"Paint") && tableandhaz(i,5) == "Yes"
        kitsummary(3,2) = "Yes";
    % soil
    elseif contains(tableandhaz(i,1),"Soil") && contains(tableandhaz(i,4),...
            "Play") && tableandhaz(i,5) == "Yes"
        kitsummary(1,2) = "Yes";
        kitsummary(1,3) = "Yes";
    elseif contains(tableandhaz(i,1),"Soil") && contains(tableandhaz(i,4),...
            "Play") && tableandhaz(i,5) == "No"
        kitsummary(1,2) = "No";
    elseif contains(tableandhaz(i,1),"Soil") && tableandhaz(i,5) == "Yes"
        kitsummary(1,3) = "Yes";
    % dust
    elseif contains(tableandhaz(i,1),"Dust") && tableandhaz(i,5) == "Yes" ...
            && contains(tableandhaz(i,4),"Sill") || contains ...
            (tableandhaz(i,1),"Dust") && tableandhaz(i,5) == "Yes" ...
            && contains(tableandhaz(i,4),"sill") 
        kitsummary(5,2) = "Yes";
        kitsummary(6,2) = "Yes";
    elseif contains(tableandhaz(i,1),"Dust") && tableandhaz(i,5) == "No" ...
            && contains(tableandhaz(i,4),"Sill") || contains ...
            (tableandhaz(i,1),"Dust") && tableandhaz(i,5) == "No" ...
            && contains(tableandhaz(i,4),"sill") || contains ...
            (tableandhaz(i,1),"Dust") && tableandhaz(i,5) == "No" ...
            && contains(tableandhaz(i,4),"Window") || contains ...
            (tableandhaz(i,1),"Dust") && tableandhaz(i,5) == "No" ...
            && contains(tableandhaz(i,4),"window") 
        kitsummary(5,2) = "No";
        % if it's not a window sill we're categorizing as floor
    elseif contains(tableandhaz(i,1),"Dust") && tableandhaz(i,5) == "Yes"
        kitsummary(4,2) = "Yes";
        kitsummary(6,2) = "Yes";
    else 
        continue
    end
end

newkitsummary = strrep(kitsummary, 'empty','No');

%% Building Table with LRA and Kit Data

header = ["Type", "LRA", "Kit"];
consolidate = [newsummary, newkitsummary(:,2)];
LRAkitchart = [header; consolidate];

agree = "empty" + strings(height(consolidate),1);

for i = 1:height(consolidate) % checks for agreement between LRA and LSK in each category
    if consolidate(i,2) == "Yes" && consolidate(i,3) == "Yes"
        agree(i) = "Yes";
    elseif consolidate(i,2) == "No" && consolidate(i,3) == "No"
        agree(i) = "Yes";
    elseif consolidate(i,2) == "No" && consolidate(i,3) == "Yes"
        agree(i) = "No";
    elseif consolidate(i,2) == "Yes" && consolidate(i,3) == "No"
        agree(i) = "No";
    elseif consolidate(i,2) == "N/A" | consolidate(i,3) == "N/A" 
        agree(i) = "N/A";
    end
end

Type = ["Soil - Play Area"; "Soil - Overall"; "Paint";...
    "Dust - Floor"; "Dust - Window Sill"; "Dust - Overall"];
LRA = [newsummary(:,2)];
Kit = [newkitsummary(:,2)];
Agreement = agree;

comptable = table(Type,LRA,Kit,Agreement)
