%Proyecto: Guante_Traductor
%Descripcion: Muestra datos capturados en Code_5.m, promedio todas las
%             pruebas por letra y muestra las graficas lineales e imagesc.

close all;  %Limpiar y cerrar todo
clear all;
clc;

%Vectores que se usan para generar los nombres de los archivos
Letra = {'Rest_','A_','B_','C_','D_','E_','F_','G_','H_','I_','J_','K_','L_','M_','N_','O_','P_','Q_','R_','S_','T_','U_','V_','W_','X_','Y_','Z_'};
Prueba = {'p1','p1','p3','p4','p5','p6','p7','p8','p9','p10'};
Dedos = {' Pulgar',' Indice',' Medio',' Anular',' Menique',' Touch1',' Touch2',' Mov',' Direc'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%PARAMETROS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fs = 20;                       %Frecuencia de Muestreo en Arduino  
timeTotal = 7;                 %Tiempo de las pruebas
numLetras = 27;                %Numero de letras
numPruebas = 10;               %Numero de Pruebas
numParam = 9;                  %Numero de Parametros

vect_time = (1/fs : 1/fs : timeTotal);                %Generacion artificial del vector de tiempo5
Figure_Name = 1;

for a = 2 : 2                                         %Letras
    figure(Figure_Name)                               %Figura en la que se graficara
    Figure_Name = Figure_Name+1;
    Matriz_Promedio = zeros(numParam,fs*timeTotal);   %Vector donde se guardara el promedio 
    
    for b = 1 : numPruebas                            %Numero de Pruebas
                                                      %Cargar los archivos
        Nombre_Archivo = strcat(Letra(a), Prueba(b)); %Generacion del nombre de archivo 
        Nombre_Archivo = Nombre_Archivo{1};
        load(strcat(Nombre_Archivo,'.mat'));          %Cargar datos del archivo en una variable
                                                      %Pasar vectores de datos, y sumando los de las 10 pruebas                        
        Matriz_Promedio = Matriz_Promedio + MetaData(1:numParam,:);                     
    end
                                                      %Promedio
    Matriz_Promedio = Matriz_Promedio/numPruebas;
    
                                                      %Graficado
    for f = 1 : numParam
        subplot(3,3,f)
        plot(vect_time, Matriz_Promedio(f,:));
        title(strrep(Nombre_Archivo,'_p10',Dedos{f}));
        xlim([0 timeTotal])
    end
    
    Matriz_Promedio(1:5,:) = (Matriz_Promedio(1:5,:)-10000)/30000;
    figure(Figure_Name)
    imagesc(Matriz_Promedio(1:numParam,:)), colorbar, caxis([0 1])
    title(strrep(Nombre_Archivo,'_p10','.'));
    set(gca, 'YTick', 1:numParam, 'YTickLabel', {'Pulgar','Indice','Medio','Anular','Meñique','Touch1','Touch2',' Mov',' Direc'});
    set(gca, 'XTick', [0:20:fs*timeTotal], 'XTickLabel', [0:timeTotal]);
    xlabel('Tiempo(s)')
    Figure_Name = Figure_Name+1;
   
end

%Calcula la std de las 5 flexo en grupos de 5 datos y las suma
for a=1:140/5
    s(a*5-4:a*5)=sum(std(MetaData(1:5,a*5-4:a*5),0,2));   
end