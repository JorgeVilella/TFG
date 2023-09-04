clc;
clear;

%% constantes de primer dato y tamaño de muestra

folder = uigetdir();
fileList = dir(fullfile(folder, '*.csv'));
fileList = {fileList.name};
fileList=natsortfiles(fileList);

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
ptos_medida = [];


for f = 1:size(fileList,2)
    T = readtable(string(fileList(f)));
    disp(string(fileList(f)))
    
    
    tamano = size(fileList);
    start_index = 1;
    samples = size(T,1);

    switch f
        case {1,2}
            pto_trabajo_X = 4500;
            pto_trabajo_Y = 6140;
        case {3,4}
            pto_trabajo_X = 4500;
            pto_trabajo_Y = 10210;
        case {5,6}
            pto_trabajo_X = 8600;
            pto_trabajo_Y = 2130;
        case {7,8}
            pto_trabajo_X = 8600;
            pto_trabajo_Y = 6140;
        case {9,10}
            pto_trabajo_X = 8600;
            pto_trabajo_Y = 10210;
        case {11,12}
            pto_trabajo_X = 12680;
            pto_trabajo_Y = 2130;
        case {13,14}
            pto_trabajo_X = 12680;
            pto_trabajo_Y = 6140;
        case {15,16}
            pto_trabajo_X = 12680;
            pto_trabajo_Y = 10210;
        case {17,18}
            pto_trabajo_X = 16760;
            pto_trabajo_Y = 2130;
        case {19,20}
            pto_trabajo_X = 16760;
            pto_trabajo_Y = 6140;
        case {21,22}
            pto_trabajo_X = 16760;
            pto_trabajo_Y = 10210;
    end
    
    if(mod(f,2) ~= 0)
        ptos_medida(n,1:2) = [pto_trabajo_X/1000 pto_trabajo_Y/1000];
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
    if(f==8)
        aux_n(1:size(norm_pozyx,2)-1) = norm_pozyx(1:size(norm_pozyx,2)-1);
        aux_n(186:end) = norm_pozyx(187:end);
        norm_pozyx = aux_n;
    end
    norm_pozyx = transpose(norm_pozyx);
    
    %%%%%%%%%%%%%%%%%%%%%%
    %Histograma de medidas
    %%%%%%%%%%%%%%%%%%%%%%
    % figure;
    % subplot(1,2,1);
    % title('Distribución de medidas en el eje X');
    % x = min(pozyx_final(:,1)):max(pozyx_final(:,1));
    % histogram(pozyx_final(:,1), 1.55:0.008:2.1);
    % y = normpdf(pozyx_final(:,1));
    % plot(x,y,'r')
    % 
    % subplot(1,2,2);
    % title('Distribución de medidas en el eje Y');
    % histogram(pozyx_final(:,2), 0.86:0.002:1.04);

    % %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % %Gráfico de la medida Pozyx
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%
    % figure
    % plot(pozyx_final(:,1),pozyx_final(:,2),'o','color',[0.3010 0.7450 0.9330],'MarkerFaceColor',[0 0 1],'MarkerSize',10);
    % hold on;
    % plot(ref(1,1),ref(1,2),'o','color',[0.8500 0.3250 0.0980],'MarkerFaceColor',[0.8500 0.3250 0.0980],'MarkerSize',15);
    % grid on;
    % % xlim([3.4 3.6])
    % % ylim([2.9 3.1])
    % % xlim([3.4 3.6])
    % % ylim([1.4 1.6])
    % title('Evolución en XY de la medida: ', fileList(f), 'FontSize', 18);
    % xlabel('Posición en x (m)', 'FontSize', 18); 
    % ylabel('Posición en y (m)', 'FontSize', 18);
    % legend('Medidas', 'Punto de trabajo', 'FontSize', 18);

    %%%%%%%%%%%%%%%%%%%  
    %Gráfico de errores
    %%%%%%%%%%%%%%%%%%%
    % figure
    % hold on;
    % plot(pozyx_final(:,3), error_pozyx(:,1), '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[0 0 1],'MarkerSize',10);
    % plot(pozyx_final(:,3), error_pozyx(:,2), '-o', 'color',[0 1 0], 'MarkerFaceColor',[40/255 114/255 51/255],'MarkerSize',10);
    % plot(pozyx_final(:,3),norm_pozyx, '-o', 'color', [1 0 0], 'MarkerFaceColor',[203/255 50/255 52/255],'MarkerSize',10);
    % grid on;
    % title('Evolución de los errores: ', fileList(f), 'FontSize', 18);
    % xlabel('Tiempo en segundos', 'FontSize', 18);
    % ylabel('Error (m)', 'FontSize', 18);
    % legend('Error en el eje x', 'Error en el eje y', 'Norma del error', 'FontSize', 18);
    % hold off;


    % %%%%%%%%%%%%%%%%%%%%%%%  
    % %Gráfico del error en X
    % %%%%%%%%%%%%%%%%%%%%%%%
    % figure
    % plot(pozyx_final(:,3), error_pozyx(:,1), '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[0 0 1],'MarkerSize',10);
    % grid on;
    % title('Error a lo largo del eje X: ', fileList(f),'FontSize', 18);
    % xlabel('Tiempo en segundos', 'FontSize', 18);
    % ylabel('Error (m)', 'FontSize', 18);

    % %%%%%%%%%%%%%%%%%%%%%%%
    % %Gráfico del error en Y
    % %%%%%%%%%%%%%%%%%%%%%%%
    % figure
    % plot(pozyx_final(:,3), error_pozyx(:,2), '-o', 'color',[0.3010 0.7450 0.9330], 'MarkerFaceColor',[0 0 1],'MarkerSize',10);
    % grid on;
    % title('Error a lo largo del eje Y: ', fileList(f), 'FontSize', 18);
    % xlabel('Tiempo en segundos', 'FontSize', 18);
    % ylabel('Error (m)', 'FontSize', 18);

    % %%%%%%%%%%%%%%%%%%%%
    % %Gráfico de la norma
    % %%%%%%%%%%%%%%%%%%%%
    % figure
    % if (f==8)
    %     plot(pozyx_final(1:end-1,3), norm_pozyx, '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[0 0 1],'MarkerSize',10);
    % else
    %     plot(pozyx_final(1:end,3), norm_pozyx, '-o', 'color', [0.3010 0.7450 0.9330], 'MarkerFaceColor',[0 0 1],'MarkerSize',10);
    %     hold on;
    %     grid on;
    %     title('Norma entre punto de trabajo y medida: ', fileList(f), 'FontSize', 18);
    %     xlabel('Tiempo en segundos', 'FontSize', 18);
    %     ylabel('Norma (m)', 'FontSize', 18);
    % end
    

    if(mod(f,2) ~= 0)
        b=1;
        for i = 15:length(error_pozyx)
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
        
    else
        media_error_x_uwb(m) = mean(abs(error_pozyx(20:end,1)));
        max_error_x_uwb(m) = max(abs(error_pozyx(20:end,1)));
        media_error_y_uwb(m) = mean(abs(error_pozyx(20:end,2)));
        max_error_y_uwb(m) = max(abs(error_pozyx(20:end,2)));
        media_error_distancia_uwb(m) = mean(norm_pozyx(20:end));
        RMSE_uwb(m) = sqrt(mean(norm_pozyx(20:end).^2));
        m=m+1;
    end

    %%%%%%%%%%%%%%%%%%%
    %Muestra de errores
    %%%%%%%%%%%%%%%%%%%
    if(mod(f,2) ~= 0)
        disp('Media del error en x:')
        disp(mean(abs(error_pozyx(150:end,1))))

        disp('Error maximo en x:')
        disp(max(abs(error_pozyx(150:end,1))))

        disp('Media del error en y:')
        disp(mean(abs(error_pozyx(150:end,2))))

        disp('Error maximo en y:')
        disp(max(abs(error_pozyx(150:end,2))))

        disp('Media del error en distancia:')
        disp(mean(norm_pozyx(150:end)))

        RMSE = sqrt(mean(norm_pozyx(t_conv(k):end).^2));  % Root Mean Squared Error
        disp('Error RMS')
        disp(RMSE)
        k=k+1;
    else
        disp('Media del error en x:')
        disp(mean(abs(error_pozyx(20:end,1))))

        disp('Error maximo en x:')
        disp(max(abs(error_pozyx(20:end,1))))

        disp('Media del error en y:')
        disp(mean(abs(error_pozyx(20:end,2))))

        disp('Error maximo en y:')
        disp(max(abs(error_pozyx(20:end,2))))

        disp('Media del error en distancia:')
        disp(mean(norm_pozyx(20:end)))

        RMSE = sqrt(mean(norm_pozyx(20:end).^2));  % Root Mean Squared Error
        disp('Error RMS')
        disp(RMSE)
   end

end
t_conv
disp(mean(t_conv));

% disp('------------------------')
% disp('Medias de las medias UWB')
% disp('------------------------')
% 
% disp('Media de los errores medios en el eje X')
% disp(mean(media_error_x_uwb))
% disp('Media de los errores medios en el eje Y')
% disp(mean(media_error_y_uwb))
% disp('Media de las normas medias del error')
% disp(mean(media_error_distancia_uwb))
% disp('Media de los RMSE')
% disp(mean(RMSE_uwb))
% 
% disp('-----------------------------')
% disp('Medias de las medias TRACKING')
% disp('-----------------------------')
% 
% disp('Media de los errores medios en el eje X')
% disp(mean(media_error_x_tr))
% disp('Media de los errores medios en el eje Y')
% disp(mean(media_error_y_tr))
% disp('Media de las normas medias del error')
% disp(mean(media_error_distancia_tr))
% disp('Media de los RMSE')
% disp(mean(RMSE_tr))

%%%%%%%%%%%%%%%%%%%%%
%Plano de las medidas
%%%%%%%%%%%%%%%%%%%%%
% figure;
% plot([20.89 0 0 20.89],[10.21 14.27 0 0.35],'o','color',[0 0 0],'MarkerFaceColor',[0 0 0], 'MarkerSize',15);
% hold on;
% grid on;
% med_x_coords = [1 1 1 1 1 1.5 1.5 1.5 1.5 1.5 2 2 2 2 2 2.5 2.5 2.5 2.5 2.5 3 3 3 3 3 3.5 3.5 3.5 3.5 3.5 4 4 4 4 4];
% med_y_coords = [1 1.5 2 2.5 3 1 1.5 2 2.5 3 1 1.5 2 2.5 3 1 1.5 2 2.5 3 1 1.5 2 2.5 3 1 1.5 2 2.5 3 1 1.5 2 2.5 3];
% plot(ptos_medida(:,1),ptos_medida(:,2),'o','color',[0.3010 0.7450 0.9330],'MarkerFaceColor',[0 0 1], 'MarkerSize',10);
% plot(4.5,2.13,'o','color',[1 0 0],'MarkerFaceColor',[1 0 0], 'MarkerSize',10);
% for i=1:size(ptos_medida)
%     text(ptos_medida(i,1)+0.2,ptos_medida(i,2)+0.2,string(i)+'º', 'FontSize', 12);
% end
% text(20.89+0.2,10.21+0.2,'0x686f', 'FontSize', 18);
% text(0+0.2,14.27+0.2,'0x6866', 'FontSize', 18);
% text(0+0.2,0+0.2,'0x6831', 'FontSize', 18);
% text(20.89+0.2,0.35+0.2,'0x6854', 'FontSize', 18);
% xlabel('x (m)', 'FontSize', 18);
% ylabel('y (m)', 'FontSize', 18);
% title('Plano de las medidas', 'FontSize', 18);
% legend('Puntos de referencia', 'Puntos de medida', 'FontSize', 18);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico media del error en X tracking y UWB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(media_error_x_tr, '-o', 'color',[1 0 1], 'MarkerFaceColor',[1 0 0], 'MarkerSize',10);
% hold on
% plot(media_error_x_uwb, '-o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330], 'MarkerSize',10);
% grid on;
% for i=1:size(media_error_x_uwb,2)
%     text(i+0.1,media_error_x_uwb(i)+0.005,string(i*2), 'FontSize', 12);
%     text(i+0.1,media_error_x_tr(i)+0.005,string(i*2-1), 'FontSize', 12);
% end
% title('Errores medios en el eje X', 'FontSize', 18);
% xlabel('Posición de medida', 'FontSize', 18);
% ylabel('Error medio (m)', 'FontSize', 18);
% legend('Tracking','UWB only', 'FontSize', 18)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico media del error en Y tracking y UWB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(media_error_y_tr, '-o', 'color',[1 0 1], 'MarkerFaceColor',[1 0 0], 'MarkerSize',10);
% hold on
% plot(media_error_y_uwb, '-o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330], 'MarkerSize',10);
% grid on;
% for i=1:size(media_error_y_uwb,2)
%     text(i+0.1,media_error_y_uwb(i)+0.005,string(i*2), 'FontSize', 12);
%     text(i+0.1,media_error_y_tr(i)+0.005,string(i*2-1), 'FontSize', 12);
% end
% title('Errores medios en el eje Y', 'FontSize', 18);
% xlabel('Posición de medida', 'FontSize', 18);
% ylabel('Error medio (m)', 'FontSize', 18);
% legend('Tracking','UWB only', 'FontSize', 18)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico media del error en distancia tracking y UWB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(media_error_distancia_tr, '-o', 'color',[1 0 1], 'MarkerFaceColor',[1 0 0], 'MarkerSize',10);
% hold on
% plot(media_error_distancia_uwb, '-o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330], 'MarkerSize',10);
% grid on;
% for i=1:size(media_error_distancia_uwb,2)
%     text(i+0.1,media_error_distancia_uwb(i)+0.005,string(i*2), 'FontSize', 12);
%     text(i+0.1,media_error_distancia_tr(i)+0.005,string(i*2-1), 'FontSize', 12);
% end
% title('Medias de la norma del error', 'FontSize', 18);
% xlabel('Posición de medida', 'FontSize', 18);
% ylabel('Media de la norma del error (m)', 'FontSize', 18);
% legend('Tracking','UWB only', 'FontSize', 18)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %Gráfico RMSE tracking y UWB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure
% plot(RMSE_tr, '-o', 'color',[1 0 1], 'MarkerFaceColor',[1 0 0], 'MarkerSize',10);
% hold on
% plot(RMSE_uwb, '-o', 'color',[0 0.4470 0.7410], 'MarkerFaceColor',[0.3010 0.7450 0.9330], 'MarkerSize',10);
% grid on;
% for i=1:size(RMSE_uwb,2)
%     text(i+0.1,RMSE_uwb(i)+0.005,string(i*2), 'FontSize', 12);
%     text(i+0.1,RMSE_tr(i)+0.005,string(i*2-1), 'FontSize', 12);
% end
% title('Error cuadrático medio', 'FontSize', 18);
% xlabel('Posición de medida', 'FontSize', 18);
% ylabel('Error cuadrático medio (m)', 'FontSize', 18);
% legend('Tracking','UWB only', 'FontSize', 18)

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