clc;
clear;

%% constantes de primer dato y tamaño de muestra

folder = uigetdir();
fileList = dir(fullfile(folder, '*.csv'));
fileList = {fileList.name};

media_error_x_tr = [];
media_error_x_uwb = [];
media_error_y_tr = [];
media_error_y_uwb = [];
max_error_x_tr = [];
max_error_x_uwb = [];
max_error_y_tr = [];
max_error_y_uwb = [];
media_error_distancia_tr = [];
media_error_distancia_uwb= [];
RMSE_tr = [];
RMSE_uwb = [];
t_conv = [];

k = 1;
m = 1;
n = 1;

eje_X = [];
eje_Y = [];


for f = 1:size(fileList,2)
    T = readtable(string(fileList(f)));
    disp(string(fileList(f)))
    
    
    tamano = size(fileList);
    start_index = 1;
    samples = size(T,1);

    switch f
        case {1,2}
            pto_trabajo_X = 1000;
            pto_trabajo_Y = 1000;
        case {3,4}
            pto_trabajo_X = 1000;
            pto_trabajo_Y = 1500;
        case {5,6}
            pto_trabajo_X = 1000;
            pto_trabajo_Y = 2000;
        case {7,8}
            pto_trabajo_X = 1000;
            pto_trabajo_Y = 2500;
        case {9,10}
            pto_trabajo_X = 1000;
            pto_trabajo_Y = 3000;
        case {11,12}
            pto_trabajo_X = 1500;
            pto_trabajo_Y = 1000;
        case {13,14}
            pto_trabajo_X = 1500;
            pto_trabajo_Y = 1500;
        case {15,16}
            pto_trabajo_X = 1500;
            pto_trabajo_Y = 2000;
        case {17,18}
            pto_trabajo_X = 1500;
            pto_trabajo_Y = 2500;
        case {19,20}
            pto_trabajo_X = 1500;
            pto_trabajo_Y = 3000;
        case {21,22}
            pto_trabajo_X = 2000;
            pto_trabajo_Y = 1000;
        case {23,24}
            pto_trabajo_X = 2000;
            pto_trabajo_Y = 1500;
        case {25,26}
            pto_trabajo_X = 2000;
            pto_trabajo_Y = 2000;
        case {27,28}
            pto_trabajo_X = 2000;
            pto_trabajo_Y = 2500;
        case {29,30}
            pto_trabajo_X = 2000;
            pto_trabajo_Y = 3000;
        case {31,32}
            pto_trabajo_X = 2500;
            pto_trabajo_Y = 1000;
        case {33,34}
            pto_trabajo_X = 2500;
            pto_trabajo_Y = 1500;
        case {35,36}
            pto_trabajo_X = 2500;
            pto_trabajo_Y = 2000;
        case {37,38}
            pto_trabajo_X = 2500;
            pto_trabajo_Y = 2500;
        case {39,40}
            pto_trabajo_X = 2500;
            pto_trabajo_Y = 3000;
        case {41,42}
            pto_trabajo_X = 3000;
            pto_trabajo_Y = 1000;
        case {43,44}
            pto_trabajo_X = 3000;
            pto_trabajo_Y = 1500;
        case {45,46}
            pto_trabajo_X = 3000;
            pto_trabajo_Y = 2000;
        case {47,48}
            pto_trabajo_X = 3000;
            pto_trabajo_Y = 2500;
        case {49,50}
            pto_trabajo_X = 3000;
            pto_trabajo_Y = 3000;
        case {51,52}
            pto_trabajo_X = 3500;
            pto_trabajo_Y = 1000;
        case {53,54}
            pto_trabajo_X = 3500;
            pto_trabajo_Y = 1500;
        case {55,56}
            pto_trabajo_X = 3500;
            pto_trabajo_Y = 2000;
        case {57,58}
            pto_trabajo_X = 3500;
            pto_trabajo_Y = 2500;
        case {59,60}
            pto_trabajo_X = 3500;
            pto_trabajo_Y = 3000;
        case {61,62}
            pto_trabajo_X = 4000;
            pto_trabajo_Y = 1000;
        case {63,64}
            pto_trabajo_X = 4000;
            pto_trabajo_Y = 1500;
        case {65,66}
            pto_trabajo_X = 4000;
            pto_trabajo_Y = 2000;
        case {67,68}
            pto_trabajo_X = 4000;
            pto_trabajo_Y = 2500;
        case {69,70}
            pto_trabajo_X = 4000;
            pto_trabajo_Y = 3000;
    end
    
    if(mod(f,2) ~= 0)
        eje_X(n) = pto_trabajo_X;
        eje_Y(n) = pto_trabajo_Y;
        n = n+1;
    end

    pozyx_data = readtable(string(fileList(f)));
    
    pozyx.time=pozyx_data.rosbagTimestamp;
    pozyx.position.x= pozyx_data.x/1000;
    pozyx.position.y= pozyx_data.y/1000;
    pozyx.position.z= pozyx_data.z/1000;
    
    pozyx_time = pozyx.time/(1e9);
    pozyx_time = pozyx_time-pozyx_time(1);
    pozyx_time = round(pozyx_time,1);
    
    j = 1;
    pozyx_final = [];
    ref = [];
    error_pozyx = [];
    p1 = [];
    p2 = [];
    norm_pozyx = [];
    for i = 0:0.1:pozyx_time(end)
        i = round(i,1); %Incluyo esto para que cuadre el formato de i con pozyx_time
        pozyx_index_time = find(pozyx_time == i);
        if(size(pozyx_index_time,1) ~= 0)
            pozyx_index = pozyx_index_time(end);
            pozyx_final(j,1) = pozyx.position.x(pozyx_index);
            pozyx_final(j,2) = pozyx.position.y(pozyx_index);
            pozyx_final(j,3) = pozyx_time(pozyx_index);
            j = j+1;
        end
    end
    
    %Error del sistema en X e Y
    ref = ones(size(pozyx_final,1),2);
    ref(:,1) = ref(:,1)*(pto_trabajo_X/1000);
    ref(:,2) = ref(:,2)*(pto_trabajo_Y/1000);
    error_pozyx = ref - pozyx_final(:,1:2);
    
    %Distancias euclideas entre puntos
    for i=1:size(error_pozyx,1)
        p1=[pozyx_final(i,1) pozyx_final(i,2)];
        p2 = [ref(i,1) ref(i,2)];
        norm_pozyx(i) = norm(p1-p2);
    end
    norm_pozyx = transpose(norm_pozyx);
    

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Gráfico de la medida Pozyx
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % figure
    % plot(pozyx_final(:,1),pozyx_final(:,2),'o','color',[0.3010 0.7450 0.9330],'MarkerFaceColor',[0 0 1],'MarkerSize',8);
    % hold on;
    % plot(ref(1,1),ref(1,2),'o','color',[0.8500 0.3250 0.0980],'MarkerFaceColor',[0.8500 0.3250 0.0980],'MarkerSize',15);
    % grid on;
    % % xlim([3.4 3.6])
    % % ylim([2.9 3.1])
    % % xlim([3.4 3.6])
    % % ylim([1.4 1.6])
    % title('Evolución en XY de la medida: ', fileList(f));
    % xlabel('Posición en x (m)'); 
    % ylabel('Posición en y (m)');
    % legend('Medidas', 'Punto de trabajo');

    %%%%%%%%%%%%%%%%%%%%%%%  
    %Gráfico del error en X
    %%%%%%%%%%%%%%%%%%%%%%%
    % figure
    % plot([0:0.1:40.5], error_pozyx(:,1), '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[0 0 1]);
    % grid on;
    % title('Error a lo largo del eje X: ', fileList(f));
    % xlabel('Tiempo en segundos');
    % ylabel('Error (m)');

    %%%%%%%%%%%%%%%%%%%%%%%
    %Gráfico del error en Y
    %%%%%%%%%%%%%%%%%%%%%%%
    % figure
    % plot([0:0.1:40.5], error_pozyx(:,2), '-o', 'color','g', 'MarkerFaceColor',[0.4660 0.6740 0.1880]);
    % grid on;
    % title('Error a lo largo del eje Y: ', fileList(f));
    % xlabel('Tiempo en segundos');
    % ylabel('Error (m)');

    %%%%%%%%%%%%%%%%%%%%
    %Gráfico de la norma
    %%%%%%%%%%%%%%%%%%%%
    % figure
    % plot([0:0.1:40.5], norm_pozyx, '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[0 0 1]);
    % hold on;
    % grid on;
    % title('Norma entre punto de trabajo y medida: ', fileList(f));
    % xlabel('Tiempo en segundos');
    % ylabel('Norma (m)');

    %%%%%%%%%%%%%%%%%%%
    %Muestra de errores
    %%%%%%%%%%%%%%%%%%%
    if(mod(f,2) == 0)
        % disp('Media del error en x:')
        % disp(mean(abs(error_pozyx(150:end,1))))
        % 
        % disp('Error maximo en x:')
        % disp(max(abs(error_pozyx(150:end,1))))
        % 
        % disp('Media del error en y:')
        % disp(mean(abs(error_pozyx(150:end,2))))
        % 
        % disp('Error maximo en y:')
        % disp(max(abs(error_pozyx(150:end,2))))
        % 
        % disp('Media del error en distancia:')
        % disp(mean(norm_pozyx(150:end)))
        % 
        % RMSE = sqrt(mean(norm_pozyx(150:end).^2));  % Root Mean Squared Error
        % disp('Error RMS')
        % disp(RMSE)
    else
        % disp('Media del error en x:')
        % disp(mean(abs(error_pozyx(20:end,1))))
        % 
        % disp('Error maximo en x:')
        % disp(max(abs(error_pozyx(20:end,1))))
        % 
        % disp('Media del error en y:')
        % disp(mean(abs(error_pozyx(20:end,2))))
        % 
        % disp('Error maximo en y:')
        % disp(max(abs(error_pozyx(20:end,2))))
        % 
        % disp('Media del error en distancia:')
        % disp(mean(norm_pozyx(20:end)))
        % 
        % RMSE = sqrt(mean(norm_pozyx(20:end).^2));  % Root Mean Squared Error
        % disp('Error RMS')
        % disp(RMSE)
    end

   if(mod(f,2) == 0)
        b=1;
        for i = 1:(length(norm_pozyx)-10)
            if(abs(norm_pozyx(end,1)-norm_pozyx(i,1))<0.05*abs(norm_pozyx(end,1)) && b==1)
                if(abs(norm_pozyx(end,1)-norm_pozyx(i+10,1))<0.05*abs(norm_pozyx(end,1)) && b==1)
                    t_conv(k) = i;
                    b=0;
                end
            end
        end
        media_error_x_tr(k) = mean(abs(error_pozyx(t_conv(k):end,1)));
        max_error_x_tr(k) = max(abs(error_pozyx(t_conv(k):end,1)));
        media_error_y_tr(k) = mean(abs(error_pozyx(t_conv(k):end,2)));
        max_error_y_tr(k) = max(abs(error_pozyx(t_conv(k):end,2)));
        media_error_distancia_tr(k) = mean(norm_pozyx(t_conv(k):end));
        RMSE_tr(k) = sqrt(mean(norm_pozyx(t_conv(k):end).^2));
        k=k+1;
        
    else
        media_error_x_uwb(m) = mean(abs(error_pozyx(20:end,1)));
        max_error_x_uwb(m) = max(abs(error_pozyx(20:end,1)));
        media_error_y_uwb(m) = mean(abs(error_pozyx(20:end,2)));
        max_error_y_uwb(m) = max(abs(error_pozyx(20:end,2)));
        media_error_distancia_uwb(m) = mean(norm_pozyx(20:end));
        RMSE_uwb(m) = sqrt(mean(norm_pozyx(20:end).^2));
        m=m+1;
    end 



    % if(mod(f,2) == 0)
    %     b=1;
    %     media_error_x_tr(k) = mean(abs(error_pozyx(150:end,1)));
    %     max_error_x_tr(k) = max(abs(error_pozyx(150:end,1)));
    %     media_error_y_tr(k) = mean(abs(error_pozyx(150:end,2)));
    %     max_error_y_tr(k) = max(abs(error_pozyx(150:end,2)));
    %     media_error_distancia_tr(k) = mean(norm_pozyx(150:end));
    %     RMSE_tr(k) = sqrt(mean(norm_pozyx(150:end).^2));
    %     for i = 1:length(error_pozyx)
    %         if(abs(norm_pozyx(end,1)-norm_pozyx(i,1))<0.05*abs(norm_pozyx(end,1)) && b==1)
    %             t_conv(k) = i;
    %             b=0;
    %         end
    %     end
    %     k=k+1;
    % else
    %     media_error_x_uwb(m) = mean(abs(error_pozyx(20:end,1)));
    %     max_error_x_uwb(m) = max(abs(error_pozyx(20:end,1)));
    %     media_error_y_uwb(m) = mean(abs(error_pozyx(20:end,2)));
    %     max_error_y_uwb(m) = max(abs(error_pozyx(20:end,2)));
    %     media_error_distancia_uwb(m) = mean(norm_pozyx(20:end));
    %     RMSE_uwb(m) = sqrt(mean(norm_pozyx(20:end).^2));
    %     m=m+1;
    % end
end
t_conv
disp(mean(t_conv));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico media del error en X tracking y UWB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(media_error_x_tr, '-o', 'color',[1 0 1], 'MarkerFaceColor',[1 0 0]);
% hold on
% plot(media_error_x_uwb, '-o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% grid on;
% title('Errores medios en el eje X');
% xlabel('Medición');
% ylabel('Error medio (m)');
% legend('Tracking','UWB only')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico media del error en Y tracking y UWB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(media_error_y_tr, '-o', 'color',[1 0 1], 'MarkerFaceColor',[1 0 0]);
% hold on
% plot(media_error_y_uwb, '-o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% grid on;
% title('Errores medios en el eje Y');
% xlabel('Medición');
% ylabel('Error medio (m)');
% legend('Tracking','UWB only')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico media del error en distancia tracking y UWB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(media_error_distancia_tr, '-o', 'color',[1 0 1], 'MarkerFaceColor',[1 0 0]);
% hold on
% plot(media_error_distancia_uwb, '-o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% grid on;
% title('Medias de la norma del error');
% xlabel('Medición');
% ylabel('Media de la norma del error (m)');
% legend('Tracking','UWB only')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico RMSE tracking y UWB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(RMSE_tr, '-o', 'color',[1 0 1], 'MarkerFaceColor',[1 0 0]);
% hold on
% plot(RMSE_uwb, '-o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% grid on;
% title('Error cuadrático medio');
% xlabel('Medición');
% ylabel('Error cuadrático medio (m)');
% legend('Tracking','UWB only')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico media del error en x tracking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% %plot3(eje_X, eje_Y, media_error_x_tr, 'o', 'color', 'g', 'MarkerFaceColor','g');
% plot(media_error_x_tr, 'o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% hold on
% %plot(eje_X, eje_Y, 'x','color',[0 0.4470 0.7410],'MarkerFaceColor',[0.3010 0.7450 0.9330],'MarkerSize',10)
% %plot([0 5000 5000 0], [0 4000 0 4000], 'o','color','k','MarkerFaceColor','k','MarkerSize',10)
% %legend('Media del error en X', 'Marcadores de medidas', 'Marcadores de anchors');
% grid on;
% title('Medias de los errores en X para cada medición con Tracking');
% xlabel('Medición');
% ylabel('Media del error (m)');
% %zlabel('Error_X');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico media del error en x UWB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% %plot3(eje_X, eje_Y, media_error_x_uwb, 'o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% plot(media_error_x_uwb, 'o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% hold on
% %plot(eje_X, eje_Y, 'o','color',[0 0.4470 0.7410],'MarkerFaceColor',[0.3010 0.7450 0.9330],'MarkerSize',10)
% %plot([0 5000 5000 0], [0 4000 0 4000], 'o','color','k','MarkerFaceColor','k','MarkerSize',10)
% %legend('Media del error en X', 'Marcadores de medidas', 'Marcadores de anchors');
% grid on;
% title('Medias de los errores en X para cada medición con UWB');
% xlabel('Medición');
% ylabel('Media del error (m)');
% %zlabel('Error_X');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico media del error en Y tracking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% %plot3(eje_X, eje_Y, media_error_y_tr, 'o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% plot(media_error_y_tr, 'o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% hold on
% %plot(eje_X, eje_Y, 'o','color',[0 0.4470 0.7410],'MarkerFaceColor',[0.3010 0.7450 0.9330],'MarkerSize',10)
% %plot([0 5000 5000 0], [0 4000 0 4000], 'o','color','k','MarkerFaceColor','k','MarkerSize',10)
% grid on;
% title('Medias de los errores en Y para cada medición con Tracking');
% xlabel('Medición');
% ylabel('Media del error (m)');
% %zlabel('Error_Y');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico media del error en Y UWB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% %plot3(eje_X, eje_Y, media_error_y_uwb, 'o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% plot(media_error_y_uwb, 'o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% hold on
% %plot(eje_X, eje_Y, 'o','color',[0 0.4470 0.7410],'MarkerFaceColor',[0.3010 0.7450 0.9330],'MarkerSize',10)
% %plot([0 5000 5000 0], [0 4000 0 4000], 'o','color','k','MarkerFaceColor','k','MarkerSize',10)
% grid on;
% title('Medias de los errores en Y para cada medición con UWB');
% xlabel('Medición');
% ylabel('Media del error (m)');
% %zlabel('Error_Y');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico media error distancia tracking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% %plot3(eje_X, eje_Y, media_error_distancia_tr, 'o', 'color', 'g', 'MarkerFaceColor','g');
% plot(media_error_distancia_tr, 'o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% hold on
% %plot(eje_X, eje_Y, 'o','color',[0 0.4470 0.7410],'MarkerFaceColor',[0.3010 0.7450 0.9330],'MarkerSize',10)
% %plot([0 5000 5000 0], [0 4000 0 4000], 'o','color','k','MarkerFaceColor','k','MarkerSize',10)
% grid on;
% title('Medias de las normas entre cada medición y su punto de trabajo con Tracking');
% xlabel('Medición');
% ylabel('Media de la norma (m)');
% %zlabel('Error');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Gráfico media error distancia uwb
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% %plot3(eje_X, eje_Y, media_error_distancia_uwb, 'o', 'color', 'g', 'MarkerFaceColor','g');
% plot(media_error_distancia_uwb, 'o', 'color', [0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330]);
% hold on
% %plot(eje_X, eje_Y, 'o','color',[0 0.4470 0.7410],'MarkerFaceColor',[0.3010 0.7450 0.9330],'MarkerSize',10)
% %plot([0 5000 5000 0], [0 4000 0 4000], 'o','color','k','MarkerFaceColor','k','MarkerSize',10)
% grid on;
% title('Medias de las normas entre cada medición y su punto de trabajo con UWB');
% xlabel('Medición');
% ylabel('Media de la norma (m)');
% %zlabel('Error');
% figure
% plot([1:35], media_error_distancia_uwb, 'o', 'color', 'g', 'MarkerFaceColor','g');
% hold on
% grid on;
% title('Media del error distancia con UWB');
% xlabel('X');
% ylabel('Y');
% zlabel('Error');

%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico RMSE tracking
%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot3(eje_X, eje_Y, RMSE_tr, 'o', 'color', 'g', 'MarkerFaceColor','g');
% hold on
% plot(eje_X, eje_Y, 'o','color',[0 0.4470 0.7410],'MarkerFaceColor',[0.3010 0.7450 0.9330],'MarkerSize',10)
% plot([0 5000 5000 0], [0 4000 0 4000], 'o','color','k','MarkerFaceColor','k','MarkerSize',10)
% grid on;
% title('RMSE con algoritmo con filtro');
% xlabel('X');
% ylabel('Y');
% zlabel('RMSE');

%%%%%%%%%%%%%%%%%
%Gráfico RMSE UWB
%%%%%%%%%%%%%%%%%
% figure
% plot3(eje_X, eje_Y, RMSE_uwb, 'o', 'color', 'g', 'MarkerFaceColor','g');
% hold on
% plot(eje_X, eje_Y, 'o','color',[0 0.4470 0.7410],'MarkerFaceColor',[0.3010 0.7450 0.9330],'MarkerSize',10)
% plot([0 5000 5000 0], [0 4000 0 4000], 'o','color','k','MarkerFaceColor','k','MarkerSize',10)
% grid on;
% title('RMSE con UWB');
% xlabel('X');
% ylabel('Y');
% zlabel('RMSE');