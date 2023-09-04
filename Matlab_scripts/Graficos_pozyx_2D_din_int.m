clc;
clear;

%--------------------------------------------------------------
%Lectura de los ficheros de posiciones medidas con los sensores
%--------------------------------------------------------------

folder = uigetdir();
fileList = dir(fullfile(folder, '*.csv'));
fileList = {fileList.name};

T_opti = readtable(string(fileList(1)));
T_pozyx = readtable(string(fileList(2)));

tamano = size(fileList);
start_index = 1;
samples_opti = size(T_opti,1);
samples_pozyx = size(T_pozyx,1);



pozyx_data = readtable(string(fileList(2)));
opti_data = readtable(string(fileList(1)));


opti.time=opti_data.rosbagTimestamp;
opti.linear.x = opti_data.x;
opti.linear.y = opti_data.y;
opti.linear.z = opti_data.z;
opti_time = opti.time;
opti_time = opti_time/(1e9);
t = opti_time(1);
opti_time = opti_time - opti_time(1);
opti_time = round(opti_time,1);

pozyx.time=pozyx_data.rosbagTimestamp;
pozyx.position.x= pozyx_data.x/1000;
pozyx.position.y= pozyx_data.y/1000;
pozyx.position.z= pozyx_data.z/1000;
pozyx_time = pozyx.time;
pozyx_time = pozyx_time/(1e9);
pozyx_time = pozyx_time - t;
pozyx_time = round(pozyx_time,1);

j=1;
pozyx_final = [];
error_pozyx = [];
p1 = [];
p2 = [];
norm_pozyx = [];



% %Convierte de nanosegundos a segundos y fracción de segundos
% opti_secs = floor(opti_time / 1e9);
% opti_frac = mod(opti_time, 1e9);
% pozyx_secs = floor(pozyx_time / 1e9);
% pozyx_frac = mod(pozyx_time, 1e9);
% %Crea un objeto de tiempo a partir de los segundos
% time_opti = datetime(opti_secs, 'ConvertFrom', 'posixtime');
% time_pozyx = datetime(pozyx_secs, 'ConvertFrom', 'posixtime');
% %Agrega la fracción de segundos a la fecha y hora
% time_opti = time_opti + seconds(opti_frac / 1e9);
% time_pozyx = time_pozyx + seconds(pozyx_frac / 1e9);
% %Formatea la fecha y hora en una cadena legible por humanos
% opti_time_formatted = datestr(time_opti, 'yyyy-mm-dd HH:MM:SS.FFF');
% pozyx_time_formatted = datestr(time_pozyx, 'yyyy-mm-dd HH:MM:SS.FFF');

for i=0:0.1:(opti_time(end)-0.1)
    i = round(i,1);
    pozyx_index_time=find(pozyx_time==i);
    opti_index_time=find(opti_time==i);

    if (size(pozyx_index_time,1)~=0 && size(opti_index_time,1)~=0)
        pozyx_index=pozyx_index_time(end);
        opti_index=opti_index_time(end);

        pozyx_compare(j,1)=pozyx.position.x(pozyx_index);
        pozyx_compare(j,2)=pozyx.position.y(pozyx_index);
        pozyx_compare(j,3)=pozyx_time(pozyx_index);

        opti_compare(j,1)=opti.linear.x(opti_index);
        opti_compare(j,2)=opti.linear.y(opti_index);
        opti_compare(j,3)=opti_time(opti_index);

        j=j+1;
    end

end

for i=1:size(pozyx_compare)
    for j=1:3
        opti_final(i,j)=opti_compare(i,j);
        pozyx_final(i,j)=pozyx_compare(i,j);
    end
end

p(:,[1 2 3]) = pozyx_final(380:size(pozyx_final,1), [1 2 3]);
o(:,[1 2 3]) = opti_final(380:size(opti_final,1), [1 2 3]);
pozyx_final = p;
opti_final = o;
pozyx_final(:,3) = pozyx_final(:,3)-pozyx_final(1,3);

%Error del sistema en X e Y
error_pozyx = opti_final(:,1:2) - pozyx_final(:,1:2);

%Distancias euclideas entre puntos
for i=1:size(error_pozyx,1)
    p1=[pozyx_final(i,1) pozyx_final(i,2)];
    p2 = [opti_final(i,1) opti_final(i,2)];
    norm_pozyx(i) = norm(p1-p2);
end
norm_pozyx = transpose(norm_pozyx);


%%%%%%%%%%%%%%%%%%%
%Muestra de errores
%%%%%%%%%%%%%%%%%%%
disp('Media del error en x:')
disp(mean(abs(error_pozyx(:,1))))

disp('Error maximo en x:')
disp(max(abs(error_pozyx(:,1))))

disp('Media del error en y:')
disp(mean(abs(error_pozyx(:,2))))

disp('Error maximo en y:')
disp(max(abs(error_pozyx(:,2))))

disp('Media del error en distancia:')
disp(mean(norm_pozyx(:)))

disp('Máximo error en distancia:')
disp(max(norm_pozyx(:)))

RMSE = sqrt(mean(norm_pozyx(:).^2));  % Root Mean Squared Error
disp('Error cuadrático medio')
disp(RMSE)

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Gráfico de la medida Pozyx
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(pozyx_final(:,1),pozyx_final(:,2),'o','color',[0.3010 0.7450 0.9330],'MarkerFaceColor',[0 0 1],'MarkerSize',10);
% hold on;
% plot(opti_final(:,1),opti_final(:,2),'o','color',[0 1 0],'MarkerFaceColor',[0.4660 0.6740 0.1880],'MarkerSize',10);
% grid on;
% xlim([0 6]);
% ylim([0 6]);
% title('Evolución en el plano XY de las medidas', 'FontSize', 18);
% xlabel('Posición en x (m)', 'FontSize', 18); 
% ylabel('Posición en y (m)', 'FontSize', 18);
% legend('Medidas pozyx', 'Medidas optitrack', 'FontSize', 18);

%%%%%%%%%%%%%%%%%%%%%%%  
%Gráfico de los errores
%%%%%%%%%%%%%%%%%%%%%%%
% figure
% hold on;
% plot(pozyx_final(:,3), error_pozyx(:,1), '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[0 0 1],'MarkerSize',10);
% plot(pozyx_final(:,3), error_pozyx(:,2), '-o', 'color',[0 1 0], 'MarkerFaceColor',[40/255 114/255 51/255],'MarkerSize',10);
% plot(pozyx_final(:,3), norm_pozyx, '-o', 'color', [1 0 0], 'MarkerFaceColor',[203/255 50/255 52/255],'MarkerSize',10);
% grid on;
% title('Evolución de los errores: ', 'FontSize', 18);
% xlabel('Tiempo en segundos', 'FontSize', 18);
% ylabel('Error (m)', 'FontSize', 18);
% legend('Error en el eje x', 'Error en el eje y', 'Norma del error', 'FontSize', 18);
% hold off;

%%%%%%%%%%%%%%%%%%%%%%%  
%Gráfico del error en X
%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(pozyx_final(:,3), error_pozyx(:,1), '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[0 0 1], 'MarkerSize', 10);
% grid on;
% title('Error a lo largo del eje X', 'FontSize', 18);
% xlabel('Tiempo en segundos', 'FontSize', 18);
% ylabel('Error (m)', 'FontSize', 18);

%%%%%%%%%%%%%%%%%%%%%%%
%Gráfico del error en Y
%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(pozyx_final(:,3), error_pozyx(:,2), '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[0 0 1], 'MarkerSize', 10);
% grid on;
% title('Error a lo largo del eje Y', 'FontSize', 18);
% xlabel('Tiempo en segundos', 'FontSize', 18);
% ylabel('Error (m)', 'FontSize', 18);


%%%%%%%%%%%%%%%%%%%%
%Gráfico de la norma
%%%%%%%%%%%%%%%%%%%%
% figure
% plot(pozyx_final(:,3), norm_pozyx, '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[0 0 1], 'MarkerSize', 10);
% hold on;
% grid on;
% title('Norma del error entre OptiTrack y Pozyx', 'FontSize', 18);
% xlabel('Tiempo en segundos', 'FontSize', 18);
% ylabel('Norma (m)', 'FontSize', 18);

% Para eliminar datos sobrantes 
% %--------------------------------------------------------------------------------
% p(:,[1 2 3]) = pozyx_final(206:size(pozyx_final,1), [1 2 3]);
% o(:,[1 2 3]) = opti_final(206:size(opti_final,1), [1 2 3]);
% pozyx_final = p;
% opti_final = o;
% pozyx_final(:,3) = pozyx_final(:,3)-pozyx_final(1,3);
% %--------------------------------------------------------------------------------


% %%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico de la medida Pozyx
% %%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(pozyx_final(:,1),pozyx_final(:,2),'o','color',[0.3010 0.7450 0.9330],'MarkerFaceColor',[0 0 1],'MarkerSize',10);
% hold on;
% plot(opti_final(:,1),opti_final(:,2),'o','color',[0 1 0],'MarkerFaceColor',[0.4660 0.6740 0.1880],'MarkerSize',10);
% grid on;
% plot(Xth,Yth,'color','r','LineWidth',3);
% xlim([0 6]);
% ylim([0 6]);
% title('Evolución en el plano XY de las medidas', 'FontSize', 18);
% xlabel('Posición en x (m)', 'FontSize', 18); 
% ylabel('Posición en y (m)', 'FontSize', 18);
% legend('Medidas pozyx', 'Medidas optitrack','Trayectoria teórica', 'FontSize', 18);
% 
% %%%%%%%%%%%%%%%%%%%%%%%  
% %Gráfico del error en X
% %%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(opti_final(:,3), error_th(:,1), '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[1 0 0], 'MarkerSize', 10);
% grid on;
% title('Error a lo largo del eje X', 'FontSize', 18);
% xlabel('Tiempo en segundos', 'FontSize', 18);
% ylabel('Error (m)', 'FontSize', 18);
% 
% %%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico del error en Y
% %%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(opti_final(:,3), error_th(:,2), '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[1 0 0], 'MarkerSize', 10);
% grid on;
% title('Error a lo largo del eje Y', 'FontSize', 18);
% xlabel('Tiempo en segundos', 'FontSize', 18);
% ylabel('Error (m)', 'FontSize', 18);
% 
% 
% %%%%%%%%%%%%%%%%%%%%
% %Gráfico de la norma
% %%%%%%%%%%%%%%%%%%%%
% figure
% plot(opti_final(:,3), norm_th, '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[1 0 0], 'MarkerSize', 10);
% hold on;
% grid on;
% title('Norma del error entre Pozyx y trayectoria teórica', 'FontSize', 18);
% xlabel('Tiempo en segundos', 'FontSize', 18);
% ylabel('Norma (m)', 'FontSize', 18);
