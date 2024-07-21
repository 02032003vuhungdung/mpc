function varargout = GUIDE(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @streaming_plotter_OpeningFcn, ...
                   'gui_OutputFcn',  @streaming_plotter_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

function streaming_plotter_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;

guidata(hObject, handles);

create_serial_object(hObject, eventdata, handles);


function varargout = streaming_plotter_OutputFcn(hObject, eventdata, handles) 

varargout{1} = handles.output;

function stream_button_Callback(hObject, eventdata, handles)
set(handles.port_menu,       'Enable','off');
set(handles.baud_rate_menu,  'Enable','off');
get(hObject,'Value');
Values = [];
global obj1
obj1;
if strcmp(obj1.Status,'closed')
   try(fopen(obj1));
        fprintf(['port ' obj1.port ' opened\n'])
   catch
        fprintf(['port ' obj1.port ' not available\n'])
        set(hObject,'Value',0)
   end
end
if (get(hObject,'Value')==1)
too_big = 500;
flushinput(obj1);
pause(0.1)
num_channels_found = 4;
values_string = fgetl(obj1);
hold off
cla
hold on
G1 = plot(handles.axes1,0,0,'b-');
set(G1,'XDataSource','Values(:,1)','YDataSource','Values(:,2)')
hold on
G2 = plot(handles.axes2,0,0,'r-');
set(G2,'XDataSource','Values(:,1)','YDataSource','Values(:,3)')
hold on
G3 = plot(handles.axes3,0,0,'g-');
set(G3,'XDataSource','Values(:,1)','YDataSource','Values(:,4)')
timeout = 10; 
tic
while (get(hObject,'Value')==1 && toc<timeout)
     if obj1.BytesAvailable>0                 % run loop if there is data to act on
          while obj1.BytesAvailable>0        % collect data until the buffer is empty
               values_string = fgetl(obj1);

               for i = 1:num_channels_found
                     [token,values_string] = strtok(values_string);
                     if size(token)>0
                       values(i) = str2num(token);
                     end
               end
                    [rows,columns] = size(Values);
                    if (rows>too_big)
                         Values = Values(2:end,:);
                    end
                    Values = [Values;values];
                    assignin('base','log',Values);
          end
             refreshdata(G1,'caller')
             refreshdata(G2,'caller')
             refreshdata(G3,'caller')
        if length(Values)>1 && (min(Values(:,1)) ~= max(Values(:,1)))
              xlim(handles.axes1,[min(Values(:,1)) max(Values(:,1))])
              xlim(handles.axes2,[min(Values(:,1)) max(Values(:,1))])
              xlim(handles.axes3,[min(Values(:,1)) max(Values(:,1))])
        end
        tic
        pause(0.0001);
     end
end
end

set(handles.port_menu,       'Enable','on');
set(handles.baud_rate_menu,  'Enable','on');


function port_menu_Callback(hObject, eventdata, handles)

create_serial_object(hObject, eventdata, handles);


function port_menu_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function baud_rate_menu_Callback(hObject, eventdata, handles)

create_serial_object(hObject, eventdata, handles);

function baud_rate_menu_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function create_serial_object(hObject, eventdata, handles)
global obj1
global selection
     set(handles.axes1,'Visible','on');
     set(handles.axes2,'Visible','on');
     set(handles.axes3,'Visible','on');
     contents = cellstr(get(handles.port_menu,'String'));
     selection = contents{get(handles.port_menu,'Value')};

     try
        fclose(instrfind);
        fprintf('closing all existing ports...\n')
     catch
        fprintf('could not find existing Serial ports\n')
     end
     
     obj1 = instrfind('Type', 'serial', 'Port', selection, 'Tag', '');
     if isempty(obj1)
         obj1 = serial(selection);
     else
         fclose(obj1);
         obj1 = obj1(1);
     end

contents2 = cellstr(get(handles.baud_rate_menu,'String'));
BAUD  = str2double(contents2{get(handles.baud_rate_menu,'Value')});
     set(obj1, 'BaudRate', BAUD, 'ReadAsyncMode','continuous');
     set(obj1, 'Terminator','LF');
     set(obj1, 'RequestToSend', 'off');
     set(obj1, 'Timeout', 4);
     fprintf(['serial object created for ' selection ' at ' num2str(BAUD) ' BAUD\n\n']);
