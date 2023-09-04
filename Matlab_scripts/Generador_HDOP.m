clc;
clear;

x = 0:0.05:5;
y = 0:0.05:5;
[X,Y] = meshgrid(x);
x1 = 0;
y1 = 0;
z1 = 0;
x2 = 5;
y2 = 0;
z2 = 0;
x3 = 5;
y3 = 4;
z3 = 0;
x4 = 0;
y4 = 4;
z4 = 0;
HDOP = [];
VDOP = [];


for i = 1:size(Y,1)
    for j = 1:size(X,2)
        A = [];
        Q = [];
        %Norma de los vectores anchor - tag
        R1 = sqrt((x1-X(i,j))^2 + (y1-Y(i,j))^2);
        R2 = sqrt((x2-X(i,j))^2 + (y2-Y(i,j))^2);
        R3 = sqrt((x3-X(i,j))^2 + (y3-Y(i,j))^2);
        R4 = sqrt((x4-X(i,j))^2 + (y4-Y(i,j))^2);

        %Componentes de los vectores unitarios anchor - tag
        a11 = (x1-X(i,j))/R1;
        a12 = (y1-Y(i,j))/R1;
        a13 = 0;

        a21 = (x2-X(i,j))/R2;
        a22 = (y2-Y(i,j))/R2;
        a23 = 0;

        a31 = (x3-X(i,j))/R3;
        a32 = (y3-Y(i,j))/R3;
        a33 = 0;

        a41 = (x4-X(i,j))/R4;
        a42 = (y4-Y(i,j))/R4;
        a43 = 0;

        A = [a11 a12 -1; a21 a22 -1; a31 a32 -1; a41 a42 -1];
        Q = inv(transpose(A)*A);
        HDOP(i,j) = sqrt(Q(1,1)+Q(2,2));
    end
end
HDOP = HDOP(1:81,:);
X = X(1:81,:);
Y = Y(1:81,:);
max(max(HDOP))
min(min(HDOP))


F = HDOP;

f = figure;
surf(X,Y,F)
clim([1 1.4])
shading interp;
colormap(f,parula(50));
hold on;
plot3([x1 x2 x3 x4],[y1 y2 y3 y4],[2 2 2 2],'o','color',[1 1 1],'MarkerFaceColor',[0 0 0],'MarkerSize',15)
xlabel('Eje x (m)', 'FontSize', 18);
ylabel('Eje y (m)', 'FontSize', 18);
title('Valores de HDOP en el área de experimentación', 'FontSize', 18);
text(0,0,2,'0x686f', 'FontSize', 18);
text(0,4,2,'0x6866', 'FontSize', 18);
text(5,4,2,'0x6831', 'FontSize', 18);
text(5,0,2,'0x6854', 'FontSize', 18);
c = colorbar;
c.Location = 'eastoutside';
c.Limits = [1 1.4];
c.Ticks = 1:0.1:1.4;
hold off;
