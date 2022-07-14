% Use following command to check what serial ports are available
%instrhwinfo('serial')
% Define temperature sampling delay in seconds
tempSamplingDelay = 0.1;
% Get path to save 
filter = {'*.csv'}; % will save file as csv
[filename, pathname] = uiputfile(filter);
if isequal(filename,0) || isequal(pathname,0)
   %if user clicked cancelled. Temperature data will not be saved in file 
   logTemperatureData = 0;
   disp('Temperature data will not be logged into file.')
else
   logTemperatureData = 1;  
   disp(['Temperature data will be logged to file: ',fullfile(pathname,filename)])
end
% Configure COM port with following parameters [MUST BE EXACTLY SAME AS
% BELOW]
neoptix = serial('COM6','BaudRate',9600,'DataBits',8,'StopBits',1,'Parity','None');
% Neoptix expects carriage return (CR or 13) at the end of each command
% Neoptix response is terminated by * asterik character Configure read and
% write terminator characters for COM port
neoptix.Terminator = {'*',13};
% open COM port
fopen(neoptix);
temperaturesMat = [];
k=[];
figure(1)
set(gcf,'keypress','k=get(gcf,''currentchar'');');
if(strcmp(neoptix.Status, 'open'))
    fprintf(1,'COM port opened\n');
    input('Press any key to start...\n');
    while 1

        % t command appended with terminating character CR (13) will read all
        % temperature channels. fprintf will append neoptix.Terminator
        fprintf(neoptix,'t'); 
        %Scans until terminating character (*) is read
        response = fscanf(neoptix); flushinput(neoptix); 
        while(neoptix.BytesAvailable > 0 )
            fread(neoptix, neoptix.BytesAvailable);
        end
        %Parse one text string at carriage return to extract temperature from
        %each channel
        temperaturesStr = strsplit(response,'\r');
        temperatures = str2double(temperaturesStr);
        if(isnan(temperatures(1)))
            temperatures(1)=[];
        end
        temperaturesMat = [temperaturesMat;temperatures(1:4)];
        plot(temperaturesMat(:,1)),hold all
        plot(temperaturesMat(:,2))
        plot(temperaturesMat(:,3))
        plot(temperaturesMat(:,4)), hold off
        legend('Ch1','Ch2','Ch3')
        xlabel('Samples')
        ylabel('Temperature ^{\circ}C)')
        fprintf(1,'Ch1: %0.2f  Ch2: %0.2f  Ch3: %0.2f  Ch4: %0.2f\n',temperatures(1),temperatures(2),temperatures(3),temperatures(4));
        if(logTemperatureData)
            dlmwrite(fullfile(pathname,filename),temperatures,'-append');
        end
        pause(tempSamplingDelay);
        if ~isempty(k)
            if strcmp(k,'s'); break; end;
            if strcmp(k,'p'); pause; k=[]; end;
        end
    end
else
    fprintf(1,'Could not open COM port\n');
end

fclose(neoptix); 
fprintf(1,'COM port status at the end:{%s}\n',neoptix.Status);