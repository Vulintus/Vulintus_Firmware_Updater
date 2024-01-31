function Vulintus_Firmware_Updater(varargin)

%Vulintus_Firmware_Updater.m - Vulintus, Inc., 2021
%
%   VULINTUS_FIRMWARE_UPDATER creates and executes firmware programming
%   commands for the avrdude.exe (AVR microcontrollers) and bossac.exe
%   (SAMD microcontrollers) firmware uploading programs. Users select a COM
%   port target, a HEX or BIN file, and the upload program, and the script
%   then creates the appropriate command line entry.
%
%   UPDATE LOG:
%   2021-??-?? - Drew Sloan - Function first created.
%

close all force;                                                            %Close any existing figures.

if ~isdeployed                                                              %If the function is running as a script instead of deployed code...
    matproducts = ver;                                                      %Grab all of the installed MATLAB products.
    if ~any(strcmpi({matproducts.Name},'Instrument Control Toolbox'))       %If the instrument toolbox isn't installed...
        errordlg(['The Vulintus Firmware Updater script requires the '...
            'MATLAB Instrument Control Toolbox, which is not installed '...
            'on your computer. You will need to install the toolbox or '...
            'run the compiled version of the program.'],...
            'Missing Required MATLAB Toolbox');                             %Show an error dialog.
        return                                                              %Skip execution of the rest of the function.
    end
end

[port, description] = Scan_COM_Ports('Checking for Vulintus devices');      %Scan the COM ports.

if isempty(port)                                                            %If no serial ports were found...
    errordlg(['ERROR: No Vulintus devices were detected connected to '...
        'this computer.'],'No Devices Detected!');                          %Show an error in a dialog box.
    return                                                                  %Skip execution of the rest of the function.
end

ui_h = 0.7;                                                                 %Set the height for all buttons, in centimeters.
fig_w = 15;                                                                 %Set the width of the figure, in centimeters.
ui_sp = 0.1;                                                                %Set the space between uicontrols, in centimeters.
fig_h = 6*ui_sp + 12*ui_h;                                                  %Calculate the height of the figure.
set(0,'units','centimeters');                                               %Set the screensize units to centimeters.
pos = get(0,'ScreenSize');                                                  %Grab the screensize.
pos = [pos(3)/2-fig_w/2, pos(4)/2-fig_h/2, fig_w, fig_h];                   %Scale a figure position relative to the screensize.
fig = figure('units','centimeters',...
    'Position',pos,...
    'resize','off',...
    'MenuBar','none',...
    'name','Vulintus Firmware Updater',...
    'numbertitle','off');                                                   %Set the properties of the figure.

y = fig_h - ui_h - ui_sp;                                                   %Set the bottom edge for this row of uicontrols.
uicontrol(fig,'style','edit',...
    'String','COM Port: ',...
    'units','centimeters',...    
    'position',[ui_sp, y, 3, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','inactive',...
    'horizontalalignment','right',...
    'backgroundcolor',[0.9 0.9 1],...
    'tag','port_lbl');                                                      %Make a label for the port.
uicontrol(fig,'style','popupmenu',...
    'String',description,...
    'userdata',port,...
    'units','centimeters',...    
    'position',[3 + 2*ui_sp, y, 10, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','on',...
    'tag','port_pop');                                                      %Make a port pop-up menu.
rescan_btn = uicontrol(fig,'style','pushbutton',...
    'String','SCAN',...
    'units','centimeters',...    
    'position',[13 + 3*ui_sp, y, fig_w - 4*ui_sp - 13, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','on',...
    'tag','rescan_btn');                                                    %Make a re-scan button

y = fig_h - 2*ui_h - 2*ui_sp;                                               %Set the bottom edge for this row of uicontrols.
uicontrol(fig,'style','edit',...
    'String','HEX/BIN File: ',...
    'units','centimeters',...    
    'position',[ui_sp, y, 3, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','inactive',...
    'horizontalalignment','right',...
    'backgroundcolor',[0.9 0.9 1],...
    'tag','file_lbl');                                                      %Make a label for the hex/bin file.
uicontrol(fig,'style','edit',...
    'String','[click LOAD to select >>]',...
    'units','centimeters',...    
    'position',[3 + 2*ui_sp, y, 10, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','inactive',...
    'horizontalalignment','left',...
    'tag','file_edit');                                                     %Make clickable editbox for the hex file.
load_btn = uicontrol(fig,'style','pushbutton',...
    'String','LOAD',...
    'units','centimeters',...    
    'position',[13 + 3*ui_sp, y, fig_w - 4*ui_sp - 13, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','on',...
    'tag','load_btn');                                                      %Make a load button.

y = fig_h - 3*ui_h - 3*ui_sp;                                               %Set the bottom edge for this row of uicontrols.
uicontrol(fig,'style','edit',...
    'String','Programmer: ',...
    'units','centimeters',...    
    'position',[ui_sp, y, 3, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','inactive',...
    'horizontalalignment','right',...
    'backgroundcolor',[0.9 0.9 1],...
    'tag','programmer)lbl');                                                %Make a label for the programmer.
uicontrol(fig,'style','popupmenu',...
    'String',{'avrdude.exe','bossac.exe'},...
    'units','centimeters',...    
    'position',[3 + 2*ui_sp, y, fig_w - 3*ui_sp - 3, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','on',...
    'tag','prog_pop');                                                      %Make a programmer pop-up menu.

y = fig_h - 4*ui_h - 4*ui_sp;                                               %Set the bottom edge for this row of uicontrols.
prog_btn = uicontrol(fig,'style','pushbutton',...
    'String','PROGRAM',...
    'units','centimeters',...    
    'position',[ui_sp, y, fig_w - 2*ui_sp, ui_h],...
    'fontweight','bold',...
    'fontsize',12,...
    'enable','off',...
    'tag','prog_btn');                                                      %Make a program button.

msgbox = uicontrol(fig,'style','listbox',...
    'enable','inactive',...
    'string',{},...
    'units','centimeters',...
    'position',[ui_sp, ui_sp, fig_w - 2*ui_sp, 8*ui_h],...
    'fontweight','bold',...
    'fontsize',10,...
    'min',0,...
    'max',2,...
    'value',[],...
    'backgroundcolor','w',...
    'tag','msgbox');                                                        %Make a listbox for displaying messages to the user.

set(prog_btn,'callback',@Program_Vulintus_Device);                          %Set the program button callback.
set(rescan_btn,'callback',@Rescan_COM_Ports);                               %Set the program button callback.
set(load_btn,'callback',@Set_File);                                         %Set the program button callback.
Add_Msg(msgbox,'Select a COM port and hex file to start.');                 %Add a message to the message box.


function Rescan_COM_Ports(hObject, ~)
fig = get(hObject,'parent');                                                %Grab the parent of the "Scan" button uicontrol.
obj = get(fig,'children');                                                  %Grab all children of the figure.
for i = 1:length(obj)                                                       %Step through each object.
    if ~strcmpi(get(obj(i),'enable'),'inactive')                            %If the object is active...
        set(obj(i),'enable','off');                                         %Disable the object. 
    end
end
msgbox = findobj(obj,'tag','msgbox');                                       %Grab the messagebox handle.
port_pop = findobj(obj,'tag','port_pop');                                   %Grab the port pop-up menu handle.
Add_Msg(msgbox,'Re-scanning COM ports...');                                 %Show a message in the messagebox.
[port, description] = Scan_COM_Ports('Re-scanning COM ports...');           %Re-scan the COM ports.
set(port_pop,'String',description,...
    'userdata',port);                                                       %Update the port pop-up menu.
for i = 1:length(obj)                                                       %Step through each object.
    if ~strcmpi(get(obj(i),'enable'),'inactive')                            %If the object is active...
        set(obj(i),'enable','on');                                          %Enable the object. 
    end
end


function Program_Vulintus_Device(hObject, ~)
if isdeployed                                                               %If the program is compiled and deployed...
    [~, result] = system('set PATH');                                       %Grab the curent system search path.
    cur_dur = char(regexpi(result,'Path=(.*?);','tokens','once'));          %Find the path containing the current executable.
else                                                                        %Otherwise, if we're running as a MATLAB script...
    cur_dur = pwd;                                                          %Grab the current directory.
end 
fig = get(hObject,'parent');                                                %Grab the parent of the "Scan" button uicontrol.
obj = get(fig,'children');                                                  %Grab all children of the figure.
for i = 1:length(obj)                                                       %Step through each object.
    if ~strcmpi(get(obj(i),'enable'),'inactive')                            %If the object is active...
        set(obj(i),'enable','off');                                         %Disable the object. 
    end
end
msgbox = findobj(obj,'tag','msgbox');                                       %Grab the messagebox handle.
port_pop = findobj(obj,'tag','port_pop');                                   %Grab the port pop-up menu handle.
file_edit = findobj(obj,'tag','file_edit');                                 %Grab the file editbox handle.
prog_pop = findobj(obj,'tag','prog_pop');                                   %Grab the programmer pop-up menu handle.
Clear_Msg(msgbox);                                                          %Clear the message.
temp = port_pop.UserData;                                                   %Grab the user data from the port pop-up menu.
port = temp{port_pop.Value};                                                %Grab the name of the selected COM port.
file = file_edit.UserData;                                                  %Grab the hex filename from the file editbox user data.
% [~,filename,ext] = fileparts(file);                                         %Grab the filename and extension for the hex file.
% temp_file = fullfile(tempdir,[filename,ext]);                               %Create a temporary filename.
% copyfile(file,temp_file,'f');                                               %Copy the file to the temporary directory.
temp = prog_pop.String;                                                     %Grab the string from the programmer pop-up menu.
programmer = temp{prog_pop.Value};                                          %Grab the name of the selected COM port.
switch programmer                                                           %Switch between the programmers.

    case 'avrdude.exe'                                                      %If we're using avrdude...
        if ~exist(fullfile(cur_dur,programmer),'file') || ...
                ~exist(fullfile(cur_dur, 'avrdude.conf'),'file') || ...
                ~exist(fullfile(cur_dur, 'libusb0.dll'),'file')             %If avrdude.exe or it's configuration files aren't found...
            str1 = sprintf(['ERROR: Could not find programmer %s or '...
                'associated files in the current directory.'],...
                programmer);                                                %Set the first string of an error message.
            str2 = sprintf('Directory: %s',cur_dur);                        %Set the second string of an error message.
            errordlg({str1,[],str2},...
                'Required Programming Files Not Found!');                   %Show an error in a dialog box.
            close(hObject.Parent);                                          %Close the figure.
            return                                                          %Skip execution of the function.
        end
%         copyfile(fullfile(cur_dur,programmer),tempdir,'f');                 %Copy avrdude.exe to the temporary folder.
%         copyfile(fullfile(cur_dur,'avrdude.conf'),tempdir,'f');             %Copy avrdude.conf to the temporary folder.
        cmd = ['"' fullfile(cur_dur,programmer) '" '...                     %avrdude.exe location
            '-C"' fullfile(cur_dur,'avrdude.conf') '" '...                  %avrdude.conf location
            '-patmega328p '...                                              %microcontroller type
            '-carduino '...                                                 %arduino programmer
            '-P' port ' '...                                                %port
            '-b115200 '...                                                  %baud rate
            '-D '...                                                        %disable erasing the chip
            '-Uflash:w:"' file '":i'];                                      %hex file name.
    case 'bossac.exe'                                                       %If we're using bossac...

%         'https://github.com/arduino/arduino-flash-tools/raw/master/tools_darwin/bossac/bin/bossac'
        
        if ~exist(fullfile(cur_dur,programmer),'file')                      %If bossac.exe or it's configuration file aren't found...
            bossac_url = 'https://github.com/Vulintus/Vulintus_Firmware_Updater/raw/main/src/bossac.exe';
            try                                                             %Try to download bossac.
                bossac = webread(bossac_url);                               %Grab the bossac binary.
                fid = fopen(fullfile(cur_dur,programmer),'w');              %Open a binary file for writing.
                fwrite(fid,bossac);                                         %Write the binary data to the file.
                fclose(fid);                                                %Close the *.exe.
            catch
                errordlg(sprintf(['ERROR: Could not find programmer '...
                    '%s or associated files in the current directory.'],...
                    programmer),...
                    'Required Programming Files Not Found!');               %Show an error in a dialog box.
                close(hObject.Parent);                                      %Close the figure.
                return                                                      %Skip execution of the function.
            end
        end
%         copyfile(fullfile(cur_dur,programmer),tempdir,'f');                 %Copy avrdude.exe to the temporary folder.
        Add_Msg(msgbox,'Attempting programming reset...');                  %Show a message in the messagebox.
        original_ports = instrhwinfo('serial');                             %Grab information about the currently-available serial ports.
        original_ports = original_ports.SerialPorts;                        %Save the list of all serial ports regardless of whether they're busy.
        serialcon = serialport(port,1200);                                  %Set up the serial connection on the specified port.
        pause(5);                                                           %Pause for 5 seconds.
        delete(serialcon);                                                  %Delete the serial object.
        pause(5);                                                           %Pause for 5 seconds.
        temp_port = instrhwinfo('serial');                                  %Grab information about the available serial ports.
        temp_port = temp_port.SerialPorts;                                  %Save the list of all serial ports regardless of whether they're busy.
        new_port = setdiff(temp_port,original_ports);                       %Check to see if a new COM port showed up.
        if ~isempty(new_port)                                               %If a new port was found...
            temp_port = new_port{1};                                        %Set the new port as the target.            
            str = sprintf('Upload port found: %s...',temp_port);            %Show a message in the messagebox.
        else                                                                %Otherwise...
            temp_port = port;                                               %Use the original port.
            str = sprintf('No port reset detected! Using %s.',temp_port);   %Create a messagebox message.
        end
        Add_Msg(msgbox,str);                                                %Sow a message in the messagebox.

        % "C:\Users\drew\AppData\Local\Arduino15\packages\adafruit\tools\bossac\1.8.0-48-gb176eee/bossac" 
        % -i 
        % -d 
        % --port=COM10 
        % -U 
        % -i 
        % --offset=0x4000 
        % -w 
        % -v 
        % "C:\Users\drew\AppData\Local\Temp\arduino\sketches\42E4916E2275720E41C66BEA2D560F1E/OmniTrak_Controller_5Poke.ino.bin" 
        % -R
        [~, programmer, ~] = fileparts(programmer);                         %Strip the file extension from the programmer name.
        cmd = ['"' fullfile(cur_dur,programmer) '" '...                     %bossac.exe location
            '-i '...                                                        %Display diagnostic information about the device.
            '-d '...                                                        %Print verbose diagnostic messages
            '--port=' temp_port ' '...                                      %Set the COM port.
            '-U '...                                                        %Allow automatic COM port detection.
            '-i '...                                                        %Display diagnostic information about the device.
            '--offset=0x4000 '...                                           %Specify the flash memory starting offset (to retain the bootloader).
            '-w '...                                                        %Write the file to the target's flash memory.
            '-v '...                                                        %Verify the file matches the contents after writing.
            '"' file '" '...                                                %Set the file.
            '-R'];                                                          %Reset the microcontroller after writing the flash.

        % cmd = '"H:\My Drive\Vulintus Software (Drew)\Vulintus Common Functions\Vulintus Firmware Updater\src\bossac" -i -d --port=COM10 -U -i --offset=0x4000 -w -v "H:\My Drive\Vulintus Software (Drew)\Custom Software\Aldridge Lab (U-Iowa)\Firmware\OmniTrak_Controller_5Poke.ino.bin" -R'
        % cmd = '"C:\Users\drew\AppData\Local\Arduino15\packages\adafruit\tools\bossac\1.8.0-48-gb176eee/bossac" -i -d --port=COM10 -U -i --offset=0x4000 -w -v "C:\Users\drew\AppData\Local\Temp\arduino\sketches\42E4916E2275720E41C66BEA2D560F1E/OmniTrak_Controller_5Poke.ino.bin" -R'
end
clc;                                                                        %Clear the command line.
cprintf('*blue','\n%s\n',cmd);                                              %Print the command in bold green.
[~, short_file, ext] = fileparts(file);                                     %Grab the file minus the path.
Add_Msg(msgbox,sprintf('Uploading: %s%s...', short_file, ext));             %Show a message in the messagebox.
Add_Msg(msgbox,cmd);                                                        %Show a message in the messagebox.
[status, output] = dos(cmd,'-echo');                                        %Execute the command in a dos prompt, showing the results.
ln = [0, find(output == 10), numel(output) + 1];                            %Find line indices.
for i = 1:numel(ln) - 1                                                     %Step through each line.
    str = output(ln(i)+1:ln(i+1)-1);                                        %Grab the line.
    str(str < 31) = [];                                                     %Kick out any special characters.
    Add_Msg(msgbox,str);                                                    %Show a message in the messagebox.
end
if status == 0                                                              %If the command was successful...
    Add_Msg(msgbox,'Microcode successfully updated!');                      %Show a success message in the messagebox.    
else                                                                        %Otherwise...
    Add_Msg(msgbox,'Microcode update failed!');                             %Show a failure message in the messagebox.    
end
% if exist(fullfile(tempdir,programmer),'file')                               %If the programmer exists in the temporary directory...
%     delete(fullfile(tempdir,programmer));                                   %Delete it.
% end
% if exist(fullfile(tempdir,'avrdude.conf'),'file')                           %If "avrdude.conf" exists in the temporary directory...
%     delete(fullfile(tempdir,'avrdude.conf'));                               %Delete it.
% end
% if exist(temp_file,'file')                                                  %If the temporary hex file exists...
%     delete(temp_file);                                                      %Delete it.
% end
[port, description] = Scan_COM_Ports('Re-scanning COM ports...');           %Re-scan the COM ports.
set(port_pop,'String',description,...
    'userdata',port);                                                       %Update the port pop-up menu.
for i = 1:length(obj)                                                       %Step through each object.
    if ~strcmpi(get(obj(i),'enable'),'inactive')                            %If the object is active...
        set(obj(i),'enable','on');                                          %Enable the object. 
    end
end


function Set_File(hObject, ~)
fig = get(hObject,'parent');                                                %Grab the parent of the file editbox button uicontrol.
obj = get(fig,'children');                                                  %Grab all children of the figure.
prog_btn = findobj(obj,'tag','prog_btn');                                   %Grab the program button handle.
file_edit = findobj(obj,'tag','file_edit');                                 %Grab the file editbox handle.
[file, path] = uigetfile('*.hex;*.bin');                                    %Have the user select a hex file.
if file(1) == 0                                                             %If the user didn't select a file.
    return
end
file_edit.UserData = [path file];                                           %Save the filename with path.
file_edit.String = file;                                                    %Set the editbox string to the filename.
prog_btn.Enable = 'on';                                                     %Enable the program button.


function [port, description] = Scan_COM_Ports(str)
waitbar = big_waitbar('title',str,...
    'string','Detecting serial ports...',...
    'value',0.25);                                                          %Create a waitbar figure.
port = instrhwinfo('serial');                                               %Grab information about the available serial ports.
if isempty(port)                                                            %If no serial ports were found...
    errordlg(['ERROR: No Vulintus devices were detected connected to '...
        'this computer.'],'No Devices Detected!');                          %Show an error in a dialog box.
    return                                                                  %Skip execution of the rest of the function.
end
busyports = setdiff(port.SerialPorts,port.AvailableSerialPorts);            %Find all ports that are currently busy.
port = port.SerialPorts;                                                    %Save the list of all serial ports regardless of whether they're busy.
if waitbar.isclosed()                                                       %If the user closed the waitbar figure...
    return                                                                  %Skip execution of the rest of the function.
end
waitbar.string('Identifying Vulintus devices...');                          %Update the waitbar text.
waitbar.value(0.50);                                                        %Update the waitbar value.
description = cell(size(port));                                             %Create a cell array to hold the port description.
key = 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\';              %Set the registry query field.
[~, txt] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);     %Query the registry for all USB devices.
for i = 1:numel(port)                                                       %Step through each port name.
    j = strfind(txt,['(' port{i} ')']);                                     %Find the port in the USB device list.    
    if ~isempty(j)                                                          %If a matching port was found...
        k = strfind(txt(1:j),'    ');                                       %Find all quadruple spaces preceding the port.
        description{i} = txt(k(end)+4:j-2);                                 %Grab the description.
    end
end
busyports = intersect(port,busyports);                                      %Kick out all non-Vulintus devices from the busy ports list.
if waitbar.isclosed()                                                       %If the user closed the waitbar figure...
    return                                                                  %Skip execution of the rest of the function.
end
waitbar.close();                                                            %Close the waitbar.
for i = 1:numel(port)                                                       %Step through each remaining port.
    description{i} = horzcat(port{i}, ': ', description{i});                %Add the COM port to each descriptions.
    if ~isempty(busyports) && any(strcmpi(port{i},busyports))               %If the port is busy...
        description{i} = horzcat(description{i}, ' (busy)');                %Add a busy indicator.
    end
end